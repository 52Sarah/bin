#!/usr/bin/env bash
# shellcheck disable=SC2190
#   SC2190 - ignore associative and indexed arrays

. "$HOME/.functions"

print_usage() {
  echo "Usage: '$SCRIPT_NAME cmd1 [cmd2 cmd3 ... cmdN]' where cmd is one or more of:"
  cat <<EOF
  ps | ping URI | curl URI | pid | info
  up | down |  restart | bounce | reload  | kill | clean-tomcat
  tail-cat | tc  |  tail-access-log | tal  |  rotate-logs | purge-logs NDAYS | rm-logs
  rotate-war WAR | clean-war WAR  |   war WAR | deploy-war WAR
  amps | rotate-amp AMP | amp AMP  |  share-amps | rotate-share-amp AMP | share-amp AMP  |  clean-solr-index
  help | usage  | info | version | vars
  --quiet | -q  |  --verbose | -v  |  --debug | -d  |  -Q | -V | -D
  --whatif | -W
EOF
}

print_help() {
  print_usage
  cat <<EOF
  Incoming environment variables:
    ALFRESCO_HOME       if set to _none_, we won't try to figure out where it is
    TOM_WAR_NOCLEAN     disable all *-war tasks; many older alfrescos customize the exploded webapp
    SUDO_CMD
    TOMCAT_HOME
    TOMCAT_PORT
    ALFRESCO_ROOT
    SOLR_HOME           not meant for standalone Solr, only Alfresco's

    TOMCAT_UP_PRE_ACTION:=rotate_logs or rm_logs or purge_logs
    TAIL_LOG_WAIT:=60           seconds to await a log file when tailing before it exists
    TAIL_LOG_INITIAL_LINES:=100 lines to show initially for tail -f
    TOMCAT_DOWN_WAIT:=30        seconds to wait for "down"
    PING_CURL_WAIT:=3           seconds to wait for "ping" or "curl"
    ALF_USERNAME:=admin
    ALF_PASSWORD:=alfresco

    _LOG_DEBUG    linked with --debug
    _IFVERBOSE linked with --verbose
    _LOG_UNQUIET   linked with --quiet

    At startup, the following local override shell scripts are run, if they exist:
      * PWD/tom_setenv.sh
      * SCRIPT_DIR/tom_setenv.sh
      * PWD/tom_setenv_\${hostname -s}.sh
      * SCRIPT_DIR/tom_setenv_\${hostname -s}.sh

EOF
}

shopt -s extglob  # Enable extended pattern matching in case statements
type gls >& /dev/null && ls() { gls $@; }  # Try and use gnu ls if possible, flexibler date formatting.

# Print an optional error_msg $1, then show usage if print_usage $2 is true.
abort() {
  local error_msg="$1" && shift
  local print_usage="$1" && shift
  if [[ -n "$error_msg" ]]; then
    [[ ! "$error_msg" =~ ^ERROR:\ .+ ]] && error_msg="ERROR: ${error_msg}"
    eecho $'\n'"$error_msg"$'\n'
  fi
  [[ -n "$print_usage" ]] && print_usage
  exit 1
}


tomcat() {

  SCRIPT_DIR="$(cd "$(dirname "$0")" || return 1; pwd)"  # force absolute path
  unset TRUE_SCRIPT_DIR && [[ -L "$0" ]] && TRUE_SCRIPT_DIR="$(cd "$(dirname "$(readlink "$0")")" || return 1; pwd)"
  SCRIPT_NAME="$(basename "$0")"
  SCRIPT_FULL="$0"

  # quiet/verbose/debug/whatif can all be set via switches or env vars; peek ahead at switches to see if these are there
  # and if so, set them now so the earliest commands will utilize them.
  if [[ -n "$_LOG_DEBUG" || "$*" =~ (^|[[:space:]])-{1,2}d(ebug)?([[:space:]]|$) ]]; then
    _LOG_DEBUG=1; _IFVERBOSE=1; unset _LOG_UNQUIET
    echo "Debugging enabled."
  elif [[ -n "$_IFVERBOSE" || "$*" =~ (^|[[:space:]])-{1,2}v(erbose)?([[:space:]]|$) ]]; then
    unset _LOG_DEBUG; _IFVERBOSE=1; unset _LOG_UNQUIET
    echo "Maximum verbosity."
  elif [[ -n "$_LOG_UNQUIET" || "$*" =~ (^|[[:space:]])-{1,2}q(uiet)?([[:space:]]|$) ]]; then
    unset _LOG_DEBUG; unset _IFVERBOSE; _LOG_UNQUIET=1
  fi

  # Make the debugging output pretty
  # shellcheck  disable=SC2034
  DECHO_VARS_WIDTH=20
  # shellcheck  disable=SC2034
  DECHO_VARS_PREFIX='  >>>> '
  # shellcheck  disable=SC2034
  VECHO_VARS_WIDTH=20
  # shellcheck  disable=SC2034
  VECHO_VARS_PREFIX='  >> '

  decho_vars -t '  script vars:' PWD SCRIPT_DIR TRUE_SCRIPT_DIR SCRIPT_NAME SCRIPT_FULL
  [[ "$SCRIPT_DIR" != "$PWD" ]] && iecho "Using SCRIPT_DIR: $SCRIPT_DIR"

  # Work out the regexp switches for sed, grep and find here based on OS.
  is_macos && SED_EXTREGEX="-E" || SED_EXTREGEX="-r"
  is_macos && GREP_EXTREGEX="-E" || GREP_EXTREGEX="-E" # thought it had to be -P
  is_macos && FIND_EXTREGEX_SW="-E" || FIND_EXTREGEX_PRIMARY="-regextype posix-egrep"
  is_macos && OPEN_CMD="open" || OPEN_CMD="vim"


  # Check PWD for tom_setenv.sh, then SCRIPT_DIR, TRUE_SCRIPT_DIR and HOME.
  # Then same for tom_setenv_hostname.sh.
  local candidate_dirs=( "$PWD" "$SCRIPT_DIR" "$TRUE_SCRIPT_DIR" "$HOME" )
  local dirs="$(uniq_array "${candidate_dirs[@]}")"
  vecho "  candidate setenv override directories: $(join_lines <<<"${dirs}")"
  for dir in $dirs; do
    decho "  trying setenv override directory: $dir"
    for suffix in "setenv.sh" "setenv_$(hostname -s).sh"; do
      local setenv_file="$dir/${SCRIPT_NAME%.*}_${suffix}"  # X=a.b.c, then ${X%.*} is a.b
      vecho "  ... checking override:  $setenv_file"
      [[ -e "$setenv_file" ]] && iecho_and_eval ". '$setenv_file'"
    done
  done


  # Local overrides can disable all Alfresco-related handling by setting ALFRESCO_HOME to '_none_'.
  if [[ "$ALFRESCO_HOME" = '_none_' ]]; then
    decho "ALFRESCO_HOME set to _none_, so Alfresco is dead to us"
    unset ALFRESCO_ROOT ALFRESCO_HOME
  else

    # Keep ALFRESCO_ROOT simple: if not already set, try /opt/alfresco. If no luck, unset and try again below.
    decho "initial ALFRESCO_ROOT=$ALFRESCO_ROOT"
    local echo_fn=decho
    [[ -z "$ALFRESCO_ROOT" ]] && ALFRESCO_ROOT="/opt/alfresco" && echo_fn="vecho"
    if [[ ! -d "$ALFRESCO_ROOT" ]]; then
      eecho "Warning: invalid initial value for ALFRESCO_ROOT=$ALFRESCO_ROOT"
      unset ALFRESCO_ROOT
    fi

    # ALFRESCO_HOME: Find an existing and valid ALFRESCO_HOME; if not already set, check PWD and PWD/.., SCRIPT_DIR and SCRIPT_DIR/..,
    # TRUE_SCRIPT_DIR and TRUE_SCRIPT_DIR/.., and $ALFRESCO_ROOT/alfresco-n.n.n
    vecho "initial ALFRESCO_HOME=$ALFRESCO_HOME"
    if [[ -n "$ALFRESCO_HOME" ]]; then
      if [[ ! -d "$ALFRESCO_HOME" || ! -d "$ALFRESCO_HOME/tomcat/shared/classes" ]]; then
        iecho "ALFRESCO_HOME is not a valid or complete Alfresco installation, so ignoring it: $ALFRESCO_HOME"
        unset ALFRESCO_ROOT ALFRESCO_HOME
        echo_fn=vecho
      fi
    else
      local candidate_dirs=()
      candidate_dirs+=( "$PWD" "$(cd ..; pwd)" )
      candidate_dirs+=( "$SCRIPT_DIR" "$(dirname "$SCRIPT_DIR")" )
      candidate_dirs+=( "$TRUE_SCRIPT_DIR" "$(dirname "$TRUE_SCRIPT_DIR")" )
      candidate_dirs+=( "$HOME" )

      local dirs="$(uniq_array "${candidate_dirs[@]}")"
      decho "  candidate alfresco_home directories: $(join_lines <<<"${dirs}")"
      for dir in $dirs _abort_; do
        [[ "$dir" = "_abort_" ]] && unset ALFRESCO_ROOT ALFRESCO_HOME && break
        vecho " ... trying: $dir"

        # IF we find a good directory, either set ALFRESCO_HOME or, if it's already set there, lower echo to decho
        if [[ -d "$dir" && -d "$dir/tomcat/shared/classes" ]]; then
          [[ "$dir" != "$ALFRESCO_HOME" ]] && ALFRESCO_HOME="$dir" || echo_fn=decho
          break
        fi
      done

      # fall through to the system default if none of the "local" options work
      if [[ -z "$ALFRESCO_HOME" ]]; then
        local default_alfresco_home="$(find_alfresco_home)"
        [[ -n "$default_alfresco_home" ]] && ALFRESCO_HOME="$default_alfresco_home"
      fi

    fi

    if [[ -z "$ALFRESCO_HOME" ]]; then
      unset ALFRESCO_HOME ALFRESCO_ROOT
      eecho "Unable to determine ALFRESCO_HOME, so we're going to just avoid eye contact and disable it"
    else
      [[ "$ALFRESCO_HOME" = "$PWD" ]] && echo_fn="decho"
      $echo_fn "Using ALFRESCO_HOME=$ALFRESCO_HOME"
    fi


    # ALFRESCO_ROOT: If not set already, just use ALRESCO_HOME's folder.
    if [[ -z "$ALFRESCO_HOME" ]]; then
      unset ALFRESCO_ROOT
    elif [[ -z "$ALFRESCO_ROOT" ]]; then
      ALFRESCO_ROOT="$(cd "$(dirname "$ALFRESCO_HOME")" || return 1; pwd)"
      vecho "Using ALFRESCO_ROOT=$ALFRESCO_ROOT"
    fi

  fi  # ALFRESCO_HOME = _none_


  # JAVA_HOME: Try to use Alfresco's java if JAVA_HOME not already set
  decho "initial JAVA_HOME=$JAVA_HOME"
  local echo_fn="iecho"
  local candidate_dirs=("$JAVA_HOME")
  [[ -n "$ALFRESCO_HOME" && -d "$ALFRESCO_HOME/java" ]] && candidate_dirs+=("$ALFRESCO_HOME/java")
  [[ -n "$ALFRESCO_ROOT" && -d "$ALFRESCO_ROOT/java" ]] && candidate_dirs+=("$ALFRESCO_ROOT/java")

  local dirs="$(uniq_array "${candidate_dirs[@]}")"
  decho "  candidate java_home directories: $(join_lines <<<"${dirs}")"
  for dir in $dirs _abort_; do
    decho " ... trying: $dir"
    [[ "$dir" = _abort_ ]] && abort "Unable to determine a valid JAVA_HOME"
    if [[ -n "$dir" ]] && [[ -e "$dir/bin/java" ]]; then
      [[ "$dir" != "$JAVA_HOME" ]] && JAVA_HOME="$dir" || echo_fn=decho
      break
    fi
  done
  [[ "$JAVA_HOME" = "$PWD/java" ]] && echo_fn=decho
  $echo_fn "Using JAVA_HOME=$JAVA_HOME"


  # TOMCAT_HOME: If not set by .profile or local tom_setenv.sh (or whatever), try PWD or PWD/tomcat, SCRIPT_DIR or SCRIPT_DIR/tomcat,
  # TRUE_SCRIPT_DIR or TRUE_SCRIPT_DIR/tomcat, ALFRESCO_HOME/tomcat ALFRESCO_ROOT/tomcat.
  # If it is not pointing to a valid tomcat installation, abort.
  # Use associative array so list of candidates is de-duped.
  decho "initial TOMCAT_HOME=$TOMCAT_HOME"
  local echo_fn=vecho
  local candidate_dirs=(
    "$TOMCAT_HOME"
    "$PWD/tomcat" "$PWD"
    "$SCRIPT_DIR/tomcat" "$SCRIPT_DIR"
  )
  [[ -n "$TRUE_SCRIPT_DIR" ]] && candidate_dirs+=("$TRUE_SCRIPT_DIR/tomcat" "$TRUE_SCRIPT_DIR")
  [[ -n "$ALFRESCO_HOME" ]] && candidate_dirs+=("$ALFRESCO_HOME/tomcat" "$ALFRESCO_HOME")
  [[ -n "$ALFRESCO_ROOT" ]] && candidate_dirs+=("$ALFRESCO_ROOT/tomcat" "$ALFRESCO_ROOT")

  local dirs="$(uniq_array "${candidate_dirs[@]}")"
  decho "  candidate tomcat_home directories: $(join_lines <<<"${dirs}")"
  local found_it
  for dir in $dirs _abort_; do
    [[ "$dir" = "_abort_" ]] && abort "ERROR: Unable to determine a valid TOMCAT_HOME"
    decho " ... trying: $dir"
    while [[ -n "$dir" ]] && [[ "$dir" != "/" ]]; do
      ##decho " ... checking: $dir"
      if [[ -d "$dir" ]] && [[ -d "$dir/conf" ]] && [[ -d "$dir/bin" ]]; then
        [[ "$dir" != "$TOMCAT_HOME" ]] && TOMCAT_HOME="$dir" && echo_fn=iecho  #be quiet if TOMCAT_HOME already set to this
        found_it=1; break
      fi
      ##decho " ... cannot use: $dir"
      dir="${dir%/*}"  # X=/a/b/c, then ${X%/*} is a/b
    done
    [[ -n "$found_it" ]] && break
  done
  $echo_fn "Using TOMCAT_HOME=${TOMCAT_HOME}"

  # If TOMCAT_PORT not set, attempt to derive it from server.xml.
  decho "initial TOMCAT_PORT=$TOMCAT_PORT"
  local echo_fn=vecho
  [[ -z "$TOMCAT_PORT" ]] && echo_fn=iecho && TOMCAT_PORT=$(find_server_port)
  [[ -z "$TOMCAT_PORT" ]] && abort "Unable to determine a valid TOMCAT_PORT"
  $echo_fn "Using TOMCAT_PORT=${TOMCAT_PORT}"


    # If Alfresco's SOLR_HOME not set, try to derive it from Alfresco's solr4/.../solrcore.properties file
  decho "initial SOLR_HOME=$SOLR_HOME"
  local echo_fn=decho
  if [[ -z "$ALFRESCO_HOME" ]]; then
     [[ -n "$SOLR_HOME" ]] && iecho "Since no ALFRESCO_HOME defined, clearing SOLR_HOME=$SOLR_HOME" && unset SOLR_HOME && echo_fn=vecho
  elif [[ ! -d "$ALFRESCO_HOME/solr4/workspace-SpacesStore/conf" ]]; then
     [[ -n "$SOLR_HOME" ]] && iecho "Since no ALFRESCO_HOME/solr4 exists, clearing SOLR_HOME=$SOLR_HOME" && unset SOLR_HOME && echo_fn=vecho
  else
    if [[ -z "$SOLR_HOME" ]]; then
      decho "SOLR_HOME not set, finding solrcore.properties"
      local data_dir_root="$(dirname "$(grep $GREP_EXTREGEX '^data\.dir\.root=.+' "$ALFRESCO_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties" | tail -n 1 | cut -d= -f2)")"
      if [[ -z "$data_dir_root" ]]; then
        abort "Unexpectedly could not find data.dir.root in $ALFRESCO_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties"
      elif [[ ! -d "$data_dir_root" ]]; then
        abort "Unexpectedly data.dir.root in $ALFRESCO_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties is a nonexistent folder: $data_dir_root"
      fi
      SOLR_HOME=$data_dir_root
      echo_fn=vecho
    fi
    [[ ! -d "$SOLR_HOME/index/workspace/SpacesStore" || ! -d "$SOLR_HOME/content" || ! -d "$SOLR_HOME/model" ]] && unset SOLR_HOME
  fi
  $echo_fn "Using SOLR_HOME=$SOLR_HOME"


  : "${SUDO_CMD:=}"
  : "${ALF_WAR_NOCLEAN:=}"
  : "${TOMCAT_UP_PRE_ACTION:=rotate_logs}"  #could also be rm_logs or purge_logs
  : "${TAIL_LOG_WAIT:=60}"            #seconds to await a log file when tailing before it exists
  : "${TAIL_LOG_INITIAL_LINES:=100}"  #lines to show initially for tail -f
  : "${TOMCAT_DOWN_WAIT:=30}"         #seconds to wait for "down"
  : "${PING_CURL_WAIT:=3}"            #seconds to wait for "ping" or "curl"
  : "${ALF_USERNAME:=admin}"
  : "${ALF_PASSWORD:=alfresco}"

  NOW_YYYYMMDD="$(date +'%Y-%m-%d')"
  NOW_HHMM="$(date +'%H%M')"

  # Keep on trucking until we run out of arguments.
  (( cmd_count = 0 ))
  while true; do

    local CMD="$1"; shift
    [[ $cmd_count -eq 0 ]] && [[ -z "$CMD" ]] && print_usage && exit 1
    (( cmd_count++ ))
    iecho "#$SCRIPT_NAME: $(date +'%Y-%m-%d %H:%M:%S'): Executing: $CMD"

    case "$CMD" in

      -?(-)d?(ebug) )     _LOG_DEBUG=1 && _IFVERBOSE=1 && unset _LOG_UNQUIET  ;;
      -?(-)D?(EBUG) )     unset _LOG_DEBUG ;;
      -?(-)v?(erbose) )   unset _LOG_DEBUG && _IFVERBOSE=1 && unset _LOG_UNQUIET  ;;
      -?(-)V?(ERBOSE) )   unset _LOG_DEBUG && unset _IFVERBOSE  ;;
      -?(-)q?(uiet) )     unset _LOG_DEBUG && unset _IFVERBOSE && _LOG_UNQUIET=1  ;;
      -?(-)Q?(UIET) )     unset _LOG_UNQUIET  ;;

      -?(-)w?(hatif) )    _WHATIF=1 && iecho "What-if mode enabled."  ;;
      -?(-)W?(HATIF) )    unset _WHATIF & iecho "# WHAT-IF mode disabled."  ;;

      ^* ) ${CMD:1} $@; echo \$?=$?; exit 0 ;; #output exit status after executing function, for testing

      ps )
        exec_ps  ;;

      ping | curl )
        local uri=$1; shift
        exec_ping_or_curl "$CMD" "$uri"  ;;

      pid )
        exec_pid  ;;

      info )
        exec_info  ;;


      u?(p) )
        exec_up  ;;

      d?(own) )
        exec_down  ;;

      b?(ounce) | restart | reload )
        exec_bounce  ;;

      k?(ill) )
        exec_kill  ;;

      clean-t?(omcat) )
        exec_clean_tomcat  ;;


      tc | t?(ail?(-cat)) )
        exec_tail "$TOMCAT_HOME/logs/catalina.out"
        ;;
      oc | open-cat )
        $OPEN_CMD "$TOMCAT_HOME/logs/catalina.out"
        ;;
      tal | tail-access?(-log) )
        exec_tail_access_log
        ;;
      ta | tail-alf?(resco) )
        [[ -z "$ALFRESCO_HOME" ]] && abort "ERROR: no ALFRESCO_HOME is set"
        exec_tail "$ALFRESCO_HOME/logs/alfresco.log"
        ;;
      oa | open-alf?(resco) )
        $OPEN_CMD "$ALFRESCO_HOME/logs/alfresco.log"
        ;;
      ts | tail-solr )
        if [[ -n "$ALFRESCO_HOME" && -f "$ALFRESCO_HOME/logs/solr.log" ]]; then
          exec_tail "$ALFRESCO_HOME/logs/solr.log"
        else
          exec_tail "$TOMCAT_HOME/logs/solr.log"
        fi
        ;;

      rot?(ate)-logs! )
        exec_rotate_logs FORCE_MV  ;;
      rot?(ate)-logs )
        exec_rotate_logs  ;;

      pur?(ge?(-logs)) )
        local ndays=$1; shift
        exec_purge_logs $ndays
        ;;

      rm?(-logs)! )
        exec_rm_logs FORCE_RM ;;
      rm?(-logs) )
        exec_rm_logs  ;;

      rot?(ate)-war )
        local war_name="$1"; shift
        exec_rotate_war "$war_name"  ;;

      clean-w?(ar) )
        local war_name="$1"; shift
        exec_clean_war "$war_name"  ;;

      war|deploy-w?(ar) )
        local war_name="$1"; shift
        exec_deploy_war "$war_name"  ;;


      ?(list-)amps )
        exec_amps "alfresco"  ;;
      ?(list-)share-amps )
        exec_amps "share"  ;;

      rotate-amp | ramp )
        local amp_file="$1"; shift
        local app_name="alfresco"
        exec_rotate_amp "$amp_file" "$app_name"  ;;
      rotate-share-amp | rsamp )
        local amp_file="$1"; shift
        local app_name="share"
        exec_rotate_amp "$amp_file" "$app_name"  ;;

      ?(install-)amp )
        local amp_name="$1"; shift
        exec_amp "$amp_name" "alfresco"  ;;
      ?(install-)share-amp )
        local amp_name="$1"; shift
        exec_amp "$amp_name" "share"  ;;

      clean-solr?(-index)|index )
        exec_clean_solr_index  ;;


      usage )
        print_usage  ;;
      ?(-)?(-)h?(elp) )
        print_help  ;;

      ?(-)?(-)info )
        print_version_string "$SCRIPT_FULL"
        print_vars  ;;

      ?(-)?(-)vers?(ion) )
        print_version_string "$SCRIPT_FULL"  ;;

      ?(-)?(-)vars )
        print_vars  ;;


      * )
        abort "Invalid command: '$CMD'" true ;;

    esac

    [[ -z "$1" ]] && break

  done
  iecho ""
}


exec_pid() {
  local pid=$(pgrep -f "$TOMCAT_HOME.+org.apache.catalina.startup.Bootstrap")
  [[ -z "$pid" ]] && return 1
  local lines="$(wc -l <<< "$pid")"; lines=${lines// /} && [[ $lines -gt 1 ]] && abort "ERROR: Unable to find pid, pgrep returned $lines items"
  echo "$pid"
}

exec_ps() {
  local pid=$(exec_pid)
  if [[ "$pid" =~ ^[[:digit:]]+$ ]]; then
    vecho_and_eval "ps -p $pid -o pid,ppid,user,stime,time,comm"
  fi
}

exec_ping_or_curl() {
  local cmd=$1; shift
  local uri=$1; shift
  vecho "exec_ping_or_curl: cmd=$cmd, uri=$uri"
  case "$uri" in
    alf?(resco) )
      uri="alfresco/service/index -u ${ALF_USERNAME}:${ALF_PASSWORD} -X POST"  ;;
    share )
      uri="share/page/site-index"  ;;
    solr )
      uri="solr/admin/"  ;;
    solr4 )
      uri="solr4/admin"  ;;
    !(?*) )
      iecho "Hitting all non-default, deployed webapps..."
      for w in $TOMCAT_HOME/webapps/!(*.*|ROOT|docs|examples|host-manager|manager|_vti_bin); do
        exec_ping_or_curl "$cmd" "$(basename "$w")"
      done
      return 0
      ;;
  esac
  case "$cmd" in
    p* | P* )
      echo -n "Pinging localhost:$TOMCAT_PORT/${uri%% *}:  "  # stop at space, don't user/pass
      decho_and_eval "curl -s -k -I --max-time $PING_CURL_WAIT --location localhost:$TOMCAT_PORT/$uri | grep -e 'HTTP' -e 'Location:' || echo \-" | awk '{if (NR==1) pad=""; else pad="                .... "; print pad $0}'
      ;;
    c* | C* )
      iecho "Curling localhost:$TOMCAT_PORT/${uri}:"
      decho_and_eval "curl -s -k --max-time $PING_CURL_WAIT localhost:$TOMCAT_PORT/$uri"
      ;;
    * )
      abort "Usage: exec_ping_or_curl CMD URI"
      ;;
  esac
}


exec_up() {
  iecho "Starting Tomcat..."
  [[ -n "$TOMCAT_UP_PRE_ACTION" ]] && iecho_and_eval "exec_${TOMCAT_UP_PRE_ACTION}" && sleep 1
  what_if "mkdir -pv $TOMCAT_HOME/{temp,work}"
  if [[ -n "$ALFRESCO_HOME" ]]; then
    what_if "(cd $ALFRESCO_HOME && $SUDO_CMD mkdir -pv $ALFRESCO_HOME/logs)"
    what_if "(cd $ALFRESCO_HOME/logs; $SUDO_CMD $TOMCAT_HOME/bin/catalina.sh start)"
  else
    what_if "(cd $TOMCAT_HOME && $SUDO_CMD mkdir -pv $TOMCAT_HOME/logs)"
    what_if "(cd $TOMCAT_HOME/logs; $SUDO_CMD $TOMCAT_HOME/bin/catalina.sh start)"
  fi
  echo ""
  exec_ps
}

exec_down() {
  iecho "Stopping Tomcat..."
  exec_ps
  echo ""

  what_if "(cd $TOMCAT_HOME; $SUDO_CMD bin/catalina.sh stop $TOMCAT_DOWN_WAIT)"

  local check_interval_seconds=2
  local wait_seconds=$TOMCAT_DOWN_WAIT
  if [[ -z "$_WHATIF" && -n "$(exec_pid)" ]]; then
    echo -n "Waiting on shutdown of pid $(exec_pid)"
    while [[ -n "$(exec_pid)" ]]; do
      echo -n "."
      sleep $check_interval_seconds
      ((wait_seconds -= check_interval_seconds))
      if [[ $wait_seconds -le 0 ]]; then
        echo $'\n'"Timed out waiting for Tomcat to stop gracefully."
        exec_kill
        break
      fi
    done
    echo "gone."
  fi
  exec_clean_tomcat
}

exec_bounce() {
  iecho "Bouncing Tomcat..."
  exec_down
  exec_up
}
exec_restart() { exec_bounce; }
exec_reload() { exec_bounce; }

exec_kill() {
  echo "Killing Tomcat..."
  local pid=$(exec_pid)
  vecho "pid=$pid"
  [[ ! "$pid" =~ ^[[:digit:]]+$ ]] && abort "ERROR: No pid found"
  what_if "$SUDO_CMD" kill -9 "$pid"
}

# Clear out tomcat's temp and work folders.
exec_clean_tomcat() {
  iecho "Cleaning Tomcat's temp and work folders..."
  local count="$($SUDO_CMD ls -R "${TOMCAT_HOME}/{temp,work}/*" 2> /dev/null | wc -c)"  # ignore stderr
  if (( !count )); then
    echo "INFO: Work folders are already empty, no logs to remove for: ${TOMCAT_HOME}/{temp,work}"
  elif [[ -n "$_WHATIF" ]]; then
    echo "# WHAT-IF: Would delete $count work and temp files"
  else
    echo "Deleted $($SUDO_CMD rm -rfv "${TOMCAT_HOME}/{temp,work}/*" | wc -l) temp and work files"
  fi
}

exec_rotate_logs() {
  local force_mv="$1"; shift
  for dir in "$ALFRESCO_HOME/logs" "$TOMCAT_HOME/logs"; do
    decho "checking existence of logs folder: $dir"
    [[ -d "$dir" ]] && iecho "Rotating logs: $dir" && rotate_log_files "$dir" "" "" "$force_mv"
  done
}

# Remove old log files.
exec_purge_logs() {
  [[ -z "$ndays" ]] && abort "ERROR: ndays not defined"
  iecho "Purging logs older than $ndays days..."
  for dir in "$ALFRESCO_HOME/logs" "$TOMCAT_HOME/logs"; do
    decho "checking existence of logs folder: $dir"
    [[ -d "$dir" ]] && iecho "Purging logs: $dir" && what_if "$SUDO_CMD find -H $FIND_EXTREGEX_SW "$dir" $FIND_EXTREGEX_PRIMARY -type f -mtime +${ndays} -regex '.*\.(log|out|txt).*' -ls -delete"
  done
}

exec_rm_logs() {
  local force_rm="$1"; shift
  iecho "Removing log files..."
  for dir in "$ALFRESCO_HOME/logs" "$TOMCAT_HOME/logs"; do
    decho "checking existence of logs folder: $dir"
    local count="$($SUDO_CMD ls -1R "${dir}/*.{log,out,txt}*" 2> /dev/null | wc -l)"  # ignore stderr
    if (( !count )); then
      iecho "INFO: Log folder is already empty, no logs to remove in: ${dir}"
    else
      for f in $($SUDO_CMD find -H $FIND_EXTREGEX_SW "${dir}" $FIND_EXTREGEX_PRIMARY -type f -regex '.+\.(log|out|txt)(\..+)?'); do
        # Truncate if file is currently open; else just delete.
        if [[ -n "$force_rm" ]]; then
          what_if "$SUDO_CMD rm -rv $f"
        elif file_opened "$f"; then
          iecho "Truncating open file: $f"
          what_if "$SUDO_CMD truncate -s 0 $f"
        else
          what_if "$SUDO_CMD rm -rv $f"
        fi
      done
    fi
  done
}

exec_tail() {
  local log_file="$1"; shift
  [[ -z "$log_file" ]] && abort "ERROR: missing log_file parameter"
  [[ ! -d $(dirname "$log_file") ]] && abort "ERROR: Invalid log_file; its directory does not exist: $log_file"
  iecho "Tailing ${log_file}..."
  [[ -f "$log_file" ]] && iecho -n "Lines: " && wc -l "$log_file"
  wait_then_tail "$log_file"
}

exec_tail_access_log() {
  latest_log="$(echo $TOMCAT_HOME/logs/$(ls -1 $TOMCAT_HOME/logs | grep $GREP_EXTREGEX localhost_access_log\.[0-9\-]{10}\.txt | tail -n 1))"
  ls -1 $TOMCAT_HOME/logs | grep $GREP_EXTREGEX localhost_access_log\.[0-9\-]{10}\.txt
  vecho "latest_log=$latest_log"
  [[ -n "$latest_log" ]] && exec_tail "$latest_log" || abort "Cannot not locate the most recent localhost_access_log in $TOMCAT_HOME/logs"
}

exec_rotate_war() {
  local war_name="${1/.war/}"; shift  # strip extension if included
  [[ -z $war_name ]] && abort "ERROR: Usage: exec_clean_war WAR_NAME"
  iecho "Rotating $war_name..."

  local war_file="${TOMCAT_HOME}/webapps/${war_name}.war"
  [[ ! -f "$war_file" ]] && abort "ERROR: war file $war_file does not exist"

  [[ -n "$ALF_WAR_NOCLEAN" ]] && [[ "$war_name" =~ ^(alfresco|share)$ ]] && abort "ALF_WAR_NOCLEAN is set, war tasks disabled"
  rotate_file $war_file "" ".BAK"
}

# Delete exploded webapp folder, backup .war and copy .war.CLEAN
exec_clean_war() {
  local war_name="${1/.war/}"; shift  # strip extension if included
  [[ -z $war_name ]] && abort "ERROR: Usage: exec_clean_war WAR_NAME"
  iecho "Cleaning $war_name..."

  local war_folder="${TOMCAT_HOME}/webapps/${war_name}"
  local war_file="${TOMCAT_HOME}/webapps/${war_name}.war"
  local clean_war_file="${war_file}.CLEAN"
  [[ ! -f "$war_file" ]] && abort "ERROR: war file does not exist: $war_file"
  [[ ! -f "${clean_war_file}" ]] && abort "ERROR: clean war does not exist: ${clean_war_file}"

  [[ -n "$ALF_WAR_NOCLEAN" ]] && [[ "$war_name" =~ ^(alfresco|share)\$ ]] && abort "ALF_WAR_NOCLEAN is set, war tasks disabled"
  [[ -d "$war_folder" ]] && iecho "Deleting $war_folder..." && what_if "rm -r $war_folder"
  rotate_file $war_file "" ".BAK"

  what_if "cp -pv ${clean_war_file} ${war_file}"
}

exec_deploy_war() {
  local war_file="$1"; shift
  [[ -z $war_file ]] && abort "ERROR: Usage: deploy_war WAR_FILE"
  [[ ! $war_file =~ .+\.war ]] && war_file="${war_file}.war"
  [[ ! -f "$war_file" ]] && abort "ERROR: File not found, war_file=$war_file"
  [[ -n "$ALF_WAR_NOCLEAN" ]] && [[ "$war_name" =~ ^(alfresco|share)\$ ]] && abort "ALF_WAR_NOCLEAN is set, war tasks disabled"
  iecho "Deploying war_file [$(file_info 'name size mtime' "$war_file")] to $TOMCAT_HOME/webapps"

  local war_name=$(basename $war_file)
  local target_war="$TOMCAT_HOME/webapps/$war_name"

  [[ -f "$target_war" ]] && exec_rotate_war $war_name
  [[ -d "${target_war/.war/}" ]] && exec_clean_war $war_name

  what_if "mv -v $war_file $target_war"
}


exec_info() {
  # grep: -r recursive, ignore symlinks; -E use extended regexp; -m 1 max 1 match per file; -o only show matched portion
  # sed: -r/-E use extended regexp; strip everything between filename and memory fields

  echo "TOMCAT_HOME: $TOMCAT_HOME"
  echo "TOMCAT_PORT: $TOMCAT_PORT"

  local mem_line=$(grep -r $GREP_EXTREGEX -m 1 -o --regexp "^[^#].+(-Xm[sx][[:digit:]]+[[:alpha:]] ?){2}" $TOMCAT_HOME --include \*.sh)
  echo -n "Memory options: "
  if [[ -z "$mem_line" ]]; then
    echo "none found, Tomcat is using defaults"
  else
    echo "$mem_line" | sed $SED_EXTREGEX -e 's/:.+(( -Xm[sx][[:digit:]]+[[:alpha:]]){2})/: \1/'
  fi
}


exec_amps() {
  local app_name="${1:-alfresco}"; shift  # or share
  war_file=${TOMCAT_HOME}/webapps/${app_name}.war
  [[ ! -f "$war_file" ]] && abort "ERROR: Cannot find war_file: $war_file"
  iecho "Listing amps in $war_file, modified $(file_info $war_file mtime)"
  vecho_and_eval "$JAVA_HOME/bin/java -jar $ALFRESCO_HOME/bin/alfresco-mmt.jar list $war_file"
}

# If amp matching name of given amp exists in $ALFRESCO_HOME/amps, (or amps_share), rotate it then copy the new one in.
exec_rotate_amp() {
  local amp_file="$1"; shift
  [[ -z "$amp_file" ]] && abort "ERROR: usage: exec_rotate_amp amp_file [alfresco|share]"

  if [[ ! "$1" =~ ^[AaSs] ]]; then
    local app_name="alfresco"
  else
    app_name="$1"; shift
    [[ "$app_name" =~ ^[Aa] ]] && app_name="alfresco" || app_name="share"
  fi

  local amp_basename="$(basename $amp_file)"
  [[ "$app_name" = "alfresco" ]] && local amps_folder="amps" || amps_folder="amps_share"
  local old_amp_file="$ALFRESCO_HOME/$amps_folder/$(basename $amp_file)"
  [[ -f "$old_amp_file" ]] && rotate_file "$old_amp_file" "" ".BAK"

  what_if "cp -pv $amp_file $old_amp_file"
}

exec_amp() {
  local amp_name="$1"; shift
  local app_name="${1:-alfresco}"; shift  # or share

  [[ -z "$amp_name" ]] && abort "ERROR: Usage: exec_amp amp_name [alfresco|share]"
  for f in "$amp_name" "${amp_name}.amp" "$ALFRESCO_HOME/amps/$amp_name" "$ALFRESCO_HOME/amps/${amp_name}.amp" _abort_; do
    [[ "$f" = _abort_ ]] && abort "ERROR: amp_file not found: $amp_name"
    [[ -f "$f" ]] && amp_file="$f" && break || vecho " ... candidate $f not found"
  done

  local war_file="${TOMCAT_HOME}/webapps/${app_name}.war"
  [[ ! -f "$war_file" ]] && abort "ERROR: Cannot find war_file: $war_file"
  iecho "Applying amp: $amp_file"

  local war_folder=${war_file%.*}  # strip after last "."
  [[ -d "$war_folder" ]] && what_if "$SUDO_CMD rm -r $war_folder" && iecho "Deleted existing webapp folder: $war_folder"
  [[ "${war_file}.CLEAN" -ot "$war_file" ]] && iecho "NOTE: war file is newer than the .CLEAN version"

  if [[ -n "$_WHATIF" ]]; then
    local mmt_mode="-force -preview"
    local mmt_verb="PREVIEWING"
  else
    local mmt_mode="-force"
    local mmt_verb="INSTALLING"
  fi
  [[ -n "$_IFVERBOSE" ]] && verbose_mode="-verbose"

  iecho "$mmt_verb $amp_file (modified $(file_info $amp_file mtime)) into $war_file ($(file_info $war_file mtime))..."
  echo "### $JAVA_HOME/bin/java -jar $ALFRESCO_HOME/bin/alfresco-mmt.jar install $amp_file $war_file $verbose_mode $mmt_mode"
  decho_and_eval "$JAVA_HOME/bin/java -jar $ALFRESCO_HOME/bin/alfresco-mmt.jar install $amp_file $war_file $verbose_mode $mmt_mode"
}

exec_clean_solr_index() {
  [[ -z "$SOLR_HOME" ]] && abort "ERROR: SOLR_HOME not set" || vecho "Using SOLR_HOME=$SOLR_HOME"
  if [[ -n "$_WHATIF" ]]; then
    wecho -n "Delete Alfresco's $SOLR_HOME/index/*/SpacesStore files: "
    decho_and_eval "find ${SOLR_HOME}/index/*/SpacesStore -mindepth 1 -print | wc -l"
    wecho -n "Delete Alfresco's $SOLR_HOME/content files: "
    decho_and_eval "find ${SOLR_HOME}/content -mindepth 1 -print | wc -l"
    wecho -n "Delete Alfresco's $SOLR_HOME/model files: "
    decho_and_eval "find ${SOLR_HOME}/model -mindepth 1 -print | wc -l"
  else
    echo -n "Delete Alfresco's $SOLR_HOME/index/*/SpacesStore files: "
    decho_and_eval "find ${SOLR_HOME}/index/*/SpacesStore -mindepth 1 -exec rm -rf -v {} + | wc -l"
    echo -n "Delete Alfresco's $SOLR_HOME/content files: "
    decho_and_eval "find ${SOLR_HOME}/content -mindepth 1 -exec rm -rf -v {} + | wc -l"
    echo -n "Delete Alfresco's $SOLR_HOME/model files: "
    decho_and_eval "find ${SOLR_HOME}/model -mindepth 1 -exec rm -rf -v {} + | wc -l"
  fi
}


find_server_port() {
  CMD1="cat $TOMCAT_HOME/conf/server.xml"
  CMD2="tr -d $'\r' | tr $'\n' ' ' | sed $SED_EXTREGEX 's/[[:space:]]+/ /g'"
  CMD3="sed $SED_EXTREGEX -e 's/-->/&ZZZ/g' | sed $SED_EXTREGEX -e 's/<!--[^>]*(>([^Z]+|$)|>Z([^Z]+|$)|>ZZ([^Z]+|$))*-->//g'"
  CMD4="sed $SED_EXTREGEX -n -e 's/(^.*(<Connector[^>]+port=\"([[:digit:]]+)\"[^>]+protocol=\"HTTP[^\"]*\"[^>]*\/?>.*)\$)/\3/; p; q'"
  CMD="$CMD1 | $CMD2 | $CMD3 | $CMD4"
  eval "$CMD"
}

# Execute 'tail -f', unless BANG in which case just 'tail'
wait_then_tail() {
  local file_name="$1"
  local check_interval_seconds=${2:-2}
  local timeout_seconds=${3:-$TAIL_LOG_WAIT}
  local initial_lines=${4:-$TAIL_LOG_INITIAL_LINES}
  [[ -z "$file_name" ]] && abort "ERROR: missing required file_name"
  [[ -z "$CMD_VERB_BANG" ]] && local follow="-f" || unset follow
  while [[ ! -f $file_name ]]; do
    [[ -z "$not_first" ]] && not_first=1 && printf "Waiting on %s" "$file_name"
    printf "."
    sleep $check_interval_seconds
    ((timeout_seconds -= check_interval_seconds))
    [[ $timeout_seconds -le 0 ]] && return 0
  done
  vecho_and_eval "tail -n $initial_lines $follow $file_name"
}

rotate_file() {
  local f="$1"; shift
  local d="$1"; shift         # optional, defaults to file's directory
  local suffix="$1"; shift    # optional; e.g., ".BAK"
  local force_mv="$1"; shift

  [[ -z "$f" ]] && abort "Usage: $CMD file_to_rotate [dir_to_rotate_to] [suffix]"
  if [[ ! -f $f ]]; then
    [[ "$f" =~ \* ]] && return 0  #called with wildcard, meh
    iecho "INFO: No file to rotate: $f" && return 1
  fi
  [[ -z "$d" ]] && d=$(dirname "$f") && decho "rotate_file: using default dir=$d"
  [[ ! -d "$d" ]] && mkdir -p "$d" && decho "rotate_log_files: created to_dir=$d"

  local f_basename="$(basename "$f")"
  local f_root=${f_basename%.*}   # up to last dot
  local f_ext=${f_basename##*.}   # after last dot

  # If file already has the rotation suffix, jump out. If file already has date at the end, only add time.
  if [[ $f_root =~ \.[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}\.[[:digit:]]{4}$ ]]; then
    vecho "File already rotated: $f"
    return 1
  elif [[ $f_root =~ \.${NOW_YYYYMMDD}$ ]]; then
    local f_newfullname=${d}/${f_root}.${NOW_HHMM}.${f_ext}${suffix}
  else
    local f_newfullname=${d}/${f_root}.${NOW_YYYYMMDD}.${NOW_HHMM}.${f_ext}${suffix}
  fi

  # Copy and truncate if file is currently open; else just move.
  if [[ -n "$force_mv" ]]; then
    echo -n "mv: "
    what_if "$SUDO_CMD mv -v $f $f_newfullname"
  elif file_opened "$f"; then
    vecho "Copying and truncating open file $f -> $f_newfullname"
    iecho -n "cp: "
    what_if "$SUDO_CMD cp -pv $f $f_newfullname"
    iecho -n "truncate: "
    what_if "$SUDO_CMD truncate -s 0 $f"
  else
    echo -n "mv: "
    what_if "$SUDO_CMD mv -v $f $f_newfullname"
  fi
  [[ -n "$_IFVERBOSE" ]] && ls -ohF "$f_newfullname"
}

rotate_log_files() {
  local from_dir="$1"; shift
  local to_dir="$1"; shift    # optional, defaults to 'from' directory
  local suffix="$1"; shift    # optional; e.g., ".BAK"
  local force_mv="$1"; shift
  decho "from_dir=$from_dir, to_dir=$to_dir, suffix=$suffix, force_mv=$force_mv"

  [[ -z "$from_dir" ]] && abort "Usage: $CMD dir_to_rotate_from [dir_to_rotate_to] [suffix]"
  [[ ! -d $from_dir ]] && abort "ERROR: No directory to rotate: $from_dir"
  [[ -z "$to_dir" ]] && to_dir=$from_dir && decho "rotate_log_files: using default to_dir=$to_dir"

  for f in $from_dir/*.{log,out,txt}; do
    rotate_file "$f" "$to_dir" "$suffix" "$force_mv"
  done

  [[ -z "$_LOG_UNQUIET" ]] && ls -ohF "$from_dir/"
}


# If _WHATIF set, what_if will only echo command. wecho prepends the what-if prefix before echoing.
what_if() {
  [[ "$1" = "-n" ]] && local e_flags="-n" && shift 1
  [[ -n "$_WHATIF" ]] && wecho $e_flags $@ || iecho_and_eval $e_flags $@
}
wecho() { [[ "$1" = "-n" ]] && local e_flags="-n" && shift 1; echo $e_flags "# WHAT-IF: $*"; }

# Print a string describing the "version" of the given file.
print_version_string() {
  file_info 'basename mdate mtime' "$1" | awk '{printf "%s [%s %s]\n", $1, $2, $3}'
}

minutes_since() {
  local start_time=$1; shift
  [[ -z "$start_time" ]] && abort "ERROR: Usage: minutes_since 'yyyy-mm-dd HH:MM'"
  if is_macos; then
    local start_time_s=$(date -j -f "%Y-%m-%dT%H:%M" "$start_time" +%s)
  else
    local start_time_s=$(date --date="$(echo $start_time | sed 's/T/ /')" +%s)
  fi
  local now_s=$(date +%s)
  echo $(( (now_s - start_time_s) / 60 ))
}


# Show environment variables used by this script.
print_vars() {
  local tmp=/var/tmp/${SCRIPT_NAME}.vars.sh
  for v in  ${!SH_*} ${!SCRIPT_*} ${!JAVA_*} ${!TOMCAT_*} ${!ALF*} ${!SOLR_*} ${!SUDO_*} ${!TAIL_*} ${!PING_*} ${!NOW_*}  ; do
    echo "$v=\"${!v}\""; done | tee "$tmp"
  chmod a+rw "$tmp"
  echo $'\n'"Variables also written to: $tmp"
}


# IF invoked via . or source, or SH_SOURCE is set, don't execute anything; just let env vars get set.
if [[ "$0" = "-bash" || -n "$SH_SOURCE" ]]; then
  decho "\$0=$0, SH_SOURCE=$SH_SOURCE"
  iecho "Not executing tomcat(); just sourcing variables and functions in $SCRIPT_NAME."
else
  tomcat $@
fi
