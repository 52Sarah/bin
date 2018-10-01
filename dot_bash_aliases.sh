#!/usr/bin/env bash

# This file contains only shortcuts that will be useful at a typical command prompt and
# generally not used by more complex functions. Most are truly aliases but a few are shorter
# functions.
. ~/.__login.debug.sh ".bash_aliases" || __echo() { :; }
__echo "[.bash_aliases] starting"


# -o show owner (-l includes group), -h human file sizes, -F suffix (/@)
alias ll='ls -ohF'
alias lltr='ls -ohFtr'
alias llsr='ls -ohFSr'
alias la='ls -AohF'
alias lA='ls -aohF'
alias latr='ls -AohFtr'

# Try and use gnu ls if possible, flexibler date formatting.
type gls >& /dev/null && ls() { gls --color=auto --group-directories-first "$@"; }

# Thinkl "ll and la but narrower": cut out permissions, link count and owner
lln() {
    #ls -ohF "$@" | sed -E -e '/^total .+$/d' -e 's/^.+ .+ .+ (.+) (.+ .+ .+) (.+)$/\1'$'\t''\2'$'\t''\3/'
    local -a args=("$@")
    [[ ${#args[@]} = 0 ]] && args=(.* *). # default to all files in current folder
    file_info 'size mdate suffixed_name target' "${args[@]}"
}
lan() {
    local -a args=("$@")
    [[ ${#args[@]} = 0 ]] && args=(.* *)
    file_info 'size mdate suffixed_name target' "${args[@]}"
}

# Display permissions in octal, from: http://askubuntu.com/a/152005
# I've tried to figure out how this works but have no fucking clue.
lso() {
    ls -ohF "$@" | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}';
}


alias nfind='find -L . -name '
alias pfind='find -L . -path '
alias rfind='find -L -E . -regex '

alias cd.dotfiles='cd $HOME/Drive/dotfiles'
alias cd.sandbox='cd $HOME/Drive/sandbox'


# Oops, return to where I was, if possible.
uncd() {
    [[ -z "$OLDPWD" ]] && eecho 'uncd: cannot determine prior directory' && return 1
    [[ ! -d "$OLDPWD" ]] && eecho 'uncd: $OLDPWD: prior directory no longer exists' && return 1
    cd "$OLDPWD"
}

# Make specified, or all in PWD, shell scripts executable.
chx() { chmod -v +x ${1:-*.sh}; }

# history-grep
hg() { if [[ -z "$1" ]]; then history; else history | grep -E "$*"; fi }

# Show my numeric public (wide area network) ip
alias myip="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'; dig +short myip.opendns.com @resolver1.opendns.com"


# View man results in sublime.
man() {
    type subl >& /dev/null || eecho "man: no 'subl' command line app; using native man"
    command man "$#" | col -b | subl --stay &
}


# For whatever reason, JD-GUI needs to have this script run from its folder.
jd() {
    local JD_GUI_DIR="/Applications/JD-GUI.app/Contents/MacOS"
    [[ ! -d "$JD_GUI_DIR" ]] && eecho "jd: JD-GUI.app must be installed" && return 1
    cd "$JD_GUI_DIR"
    "./universalJavaApplicationStub.sh" &
}


# Share login files among my different machines, since they're mostly alike.
if [[ "$(hostname -s)" = "SHEFFIELD" ]]; then

    alias jmxterm='java -jar $HOME/lib/jmxterm-1.0.0-uber.jar'

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

    if [[ -f "$HOME/tom.sh" ]]; then
        alias t="\$HOME/tom.sh"
    elif [[ -L "\$HOME/tom.sh" ]]; then
        alias t="\$(readlink "$HOME/tom.sh")"
    fi

fi #SHEFFIELD


__echo "[.bash_aliases] finished"
