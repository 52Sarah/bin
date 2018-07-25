#!/usr/bin/env bash
[[ -n "$SH_VERBOSE" ]] && echo "[.alias]"

[[ -e "$HOME/.functions" ]] && . "$HOME/.functions"


if [[ "$(hostname -s)" = "SHEFFIELD" ]]; then

  alias cd.clients='cd $HOME/Drive/clients'

  # If client-specific .alias_* files exist in or are linked to $HOME, source them.
  for f in $HOME/.alias_*; do
    . "$f"
  done

  export MPS_SVN="$HOME/svn/mps"
  export MPS_SVN_OC_PROJECT="$MPS_SVN/mps-opencontent/projects/clients/mps"
  alias mps.cd.svn="cd \"\$MPS_SVN\""
  alias mps.cd.oc="cd \"\$MPS_SVN_OC_PROJECT\""
  alias mps.cd.home="cd \"\$MPS_SVN_OC_PROJECT/support/HOME\""

  alias cd.sandbox='cd $HOME/Dropbox/sandbox'
  alias cd.webscripts='cd $HOME/svn/tsg-alfresco-scripts/webscripts'
  alias cd.om='cd $HOME/svn/tsg-openmigrate/'


  function cd.alf() {
    local home="$(find_alfresco_home "$@")"
    [[ ! -d "$home" ]] && return 1
    cd "$home" || return 1
  }
  function cd.alf.tomcat() {
    local home="$(find_alfresco_home "$@")"
    [[ ! -d "$home" ]] && return 1
    local dir="$home/tomcat"
    [[ ! -d "$dir" ]] && evecho "cd.alf.tomcat: cannot find tomcat under $home" && return 1
    cd "$dir" || return 1
  }
  function cd.alf.extension() {
    local home="$(find_alfresco_home "$@")"
    [[ ! -d "$home" ]] && return 1
    local dir="$home/tomcat/shared/classes/alfresco/extension"
    [[ ! -d "$dir" ]] && evecho "cd.alf.extension: cannot find extension under $home" && return 1
    cd "$dir" || return 1
  }
  function cd.alf.webapps() {
    local home="$(find_alfresco_home "$@")"
    [[ ! -d "$home" ]] && return 1
    local dir="$home/tomcat/webapps"
    [[ ! -d "$dir" ]] && evecho "cd.alf.webapps: cannot find webapps under $home" && return 1
    cd "$dir" || return 1
  }

  export ALFRESCO_ROOT="/opt/alfresco"
  export ALFRESCO_HOME="$(find_alfresco_home 5)"


  alias up='$HOME/svn/tsg-alfresco-scripts/bash/up.sh'


  alias r8080='./api-refresh.sh --port 8080 | grep -E -o "Reset Web Scripts.+ there were \d+\."'

  alias jmxterm='java -jar $HOME/lib/jmxterm-1.0.0-uber.jar'
  alias jmxterm.alf='java -jar $HOME/lib/jmxterm-1.0.0-uber.jar --url service:jmx:rmi:///jndi/rmi://localhost:50500/alfresco/jmxrmi --user controlRole --password change_asap'


  # For whatever reason, JD-GUI needs to have this script run from its folder.
  function jd() {
    local JD_GUI_DIR="/Applications/JD-GUI.app/Contents/MacOS"
    [[ ! -d "$JD_GUI_DIR" ]] && eecho "JD-GUI.app must be installed in order to use jd." && return 1
    iecho "Launching JD-GUI.app"
    (cd "$JD_GUI_DIR" && "./universalJavaApplicationStub.sh" &) && return 0
    return 1
  }

  # Start the GUI for groocyConsole. Requires Java 1.7+.
  function gconsole() {
    export JAVA_HOME="$(cd "$GROOVY_HOME/bin" || return 1; jenv javahome)"
    # nohup groovyConsole \
    #     --classpath "$( \
    #         find "$HOME/.groovy/lib" -name '*.jar'; \
    #         find "$HOME/.grails/ivy-cache" -name '*.jar' | grep -E -v '/ant|/grails|groovy|hibernate|spring|tomcat' \
    #     )" > /dev/null &
    nohup groovyConsole > /dev/null &
  }


  # alias start.ub64='VBoxManage startvm ub64 --type headless'
  # alias stop.ub64='VBoxManage controlvm ub64 poweroff'
  # alias ssh.ub64='ssh todd@192.168.56.101'

    # video's dimensions, returned as "height=H \n width=W"
  [[ "$(which ffprobe >& /dev/null)" ]] && vdim() {
    local v_file="$1"
    [ -z "$v_file" ] && echo "ERROR: No video_file specified.  Usage: vdim video_file" && return 1
    [ ! -e "$v_file" ] && echo "ERROR: video_file does not exist: $v_file" && return 1
    ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=width,height "$v_file" | grep -E "^height=|^width="
  }
fi # if SHEFFIELD


if [ -f "$HOME/tom.sh" ]; then
  alias t="\$HOME/tom.sh"
elif [ -L "\$HOME/tom.sh" ]; then
  alias t="\$(readlink \$HOME/tom.sh)"
fi

# Try and use gnu ls if possible, flexibler date formatting.
type gls >& /dev/null && function ls() {
  # eecho "\$*: $*"
  # eecho "\$@: $@"
  gls --color=auto --group-directories-first "$@"
}

# -o show owner (-l includes group), -h human file sizes, -F suffix (/@)
alias ll='ls -ohF'
alias lltr='ls -ohFtr'
alias llsr='ls -ohFSr'
alias la='ls -AohF'
alias lA='ls -aohF'
alias latr='ls -AohFtr'

# "ll and la narrow": cut out permissions, link count and owner
function lln() {
  #ls -ohF "$@" | sed -E -e '/^total .+$/d' -e 's/^.+ .+ .+ (.+) (.+ .+ .+) (.+)$/\1'$'\t''\2'$'\t''\3/'
  local -a args=("$@")
  [[ ${#args[@]} = 0 ]] && args=(*)
  file_info 'size mdate suffixed_name target' "${args[@]}"
}
function lan() {
  local -a args=("$@")
  [[ ${#args[@]} = 0 ]] && args=(.* *)
  file_info 'size mdate suffixed_name target' "${args[@]}"
}

# history-grep
function hg() {
  : ${HG_LINES:=20}

  [[ -z "$1" ]] && eecho "Usage: hg [nlines] pattern" && return 1
  [[ "$1" =~ ^[[:digit:]]+$ ]] && nlines="$1" && shift
  [[ -z "$1" ]] && eecho "Usage: hg [nlines] pattern" && return 1
  echo_and_eval history | grep -E --max-count $nlines "$1"
}

alias uncd='[ -n "$OLDPWD" ] && cd "$OLDPWD"'

# Make shell scripts executable.
chx() { chmod -v +x ${1:-*.sh}; }

alias nfind='find -L . -name '
alias infind='find -L . -iname '
alias pfind='find -L . -path '
alias ipfind='find -L . -ipath '
alias rfind='find -L -E . -regex '
alias irfind='find -L -E . -regex '

# Display permissions in octal, from: http://askubuntu.com/a/152005
# function lso() {
#   ls -ohF "$@" | awk -v HOME="$HOME" '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)HOME/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}'
# }
lso() {
    ls -ohF "$@" | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}';
}


# Show my numeric public (wide area network) ip
alias myip="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'; dig +short myip.opendns.com @resolver1.opendns.com"

function man() {
  command man "${1:-man}" | col -b | subl --stay &
}
# Check out this low-rent method to colorize man pages, from https://www.cyberciti.biz/faq/linux-unix-colored-man-pages-with-less-command/#more-11860
# man() {
#   env \
#     LESS_TERMCAP_mb=$(printf "\e[1;31m") \
#     LESS_TERMCAP_md=$(printf "\e[1;31m") \
#     LESS_TERMCAP_me=$(printf "\e[0m") \
#     LESS_TERMCAP_se=$(printf "\e[0m") \
#     LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
#     LESS_TERMCAP_ue=$(printf "\e[0m") \
#     LESS_TERMCAP_us=$(printf "\e[1;32m") \
#       man "$@"
# }
