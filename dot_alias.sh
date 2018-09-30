#!/usr/bin/env bash

# For debugging via . ~/.alias --debug, incoming SH_DEBUG=1, or existence of ~/.login_debug
[[ "$1" == "--debug" || -e "$HOME/.alias.debug" ]] && __ALIAS_DEBUG=1
__echo() { [[ -n "$__ALIAS_DEBUG" ]] && echo "$@"; return 0; }

__echo "[.alias] starting"



[[ -e "$HOME/.functions" ]] && __echo "[.alias] sourcing .functions" && . "$HOME/.functions"


if [[ "$(hostname -s)" = "SHEFFIELD" ]]; then

  alias cd.sandbox='cd $HOME/Drive/sandbox'

  alias jmxterm='java -jar $HOME/lib/jmxterm-1.0.0-uber.jar'

  # For whatever reason, JD-GUI needs to have this script run from its folder.
  function jd() {
    local JD_GUI_DIR="/Applications/JD-GUI.app/Contents/MacOS"
    [[ ! -d "$JD_GUI_DIR" ]] && eecho "JD-GUI.app must be installed in order to use jd." && return 1
    iecho "Launching JD-GUI.app"
    cd "$JD_GUI_DIR" && "./universalJavaApplicationStub.sh" &
    return
  }

  # Start the GUI for groovyConsole. Requires Java 1.7+.
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
alias pfind='find -L . -path '
alias rfind='find -L -E . -regex '

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


__echo "[.alias] finished"
