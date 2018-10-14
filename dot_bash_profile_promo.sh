#!/usr/bin/env bash

# This file contains Eversight (promolytics) specific items.
. "$HOME/.__login.debug.sh" ".bash_profile_promo" || __echo() { :; }
__echo "[.bash_profile_promo] starting"


[[ -e "$HOME/git-completion.sh" ]] && . "$HOME/git-completion.sh"


# Use `git branch` to list all branches with the current branch prefixed with '* ',
# then trim the prefix.
git.branch.current() {
    (git branch --color=never 2> /dev/null || return 1) | egrep '^\* ' | cut -c3- 
}

# Set PS1 command line prompt:
# - if inside a git repo, include checked out branch
# - if last command was in error, display !$ instead of $.
# - `history -a` explicitly flushes the session history to the history file
reset_prompt() {

    export PROMPT_COMMAND='(($?)) && _prompt_symbol="!\$" || _prompt_symbol="\$"; _prompt_branch="$(git.branch.current)"; history -a'
    __echo "[.bash_profile_promo reset_prompt] PROMPT_COMMAND='$PROMPT_COMMAND'"
    
    # \u = user
    # \h = hostname
    # \w = working dir
    # export PS1='\w $ '
     export PS1='$([[ "$_prompt_branch" ]] && echo "[$_prompt_branch] ")\w $_prompt_symbol '
    __echo "[.bash_profile_promo reset_prompt] PS1='$PS1'"
}
reset_prompt


# A few convenience aliases for git command line work
alias glog='iecho_and_eval      "git log --pretty=medium"'
alias gdiff='iecho_and_eval     "git diff --name-status"'

git.user.name() {
    sed -E -n '/\s*name = (.+)/s/.* = (.+)/\1/p' ~/.gitconfig
}

# The '|$' in grep prints all lines but colors only matches
git.log() {
    local cmd="log" && [[ "$1" =~ ^[1-4]$ ]] && cmd="log$1" && shift
    git $cmd "$@" | grep -E --color=always "$(git.user.name)|\$" | more -r
}

git.help.section() {
    local cmd="$1" && shift
    [[ ! "$1" ]] && eecho "usage: git.help.config command [section]" && return 1
    local section="${1:-^C.*N\\$}"
    git $cmd --help | egrep -B 1 -A 9999 '^C.*N$' | more
}


# General purpose wrapper around all sorts of dev and troubleshooting tasks.
promo() {

local USAGE="$(cat <<-EOF
usage: promo.sh [ --quiet --verbose --debug]
   followed by one or more of:
        p.bounce
        p.up
        p.down
        p.tail
        p.status
        db.rebuild
        db.bounce
        db.up
        db.down
        db.tail
        db.status
        git.log
EOF
)"

    [[ ! "$1" ]] && eecho "$USAGE" && return 0

    while [[ "$1" ]]; do
        case "$1" in
            status | s)
                echo $'\n'"PROMO"
                promo p.status
                echo $'\n'"DB"
                promo db.status
                echo ""
                ;;

            p.bounce | bounce | b)
                iecho_and_eval "gradle stopTomcat startTomcatDebug"
                ;;
            p.up | up | p.u|u)
                iecho_and_eval "gradle startTomcatDebug"
                ;;
            p.down | down | p.d|d)
                iecho_and_eval "gradle stopTomcat"
                ;;
            p.tail|p.log | tail|log | p.t|t)
                iecho_and_eval "tail -n 200 -f "$PROMO_LOG""
                ;;
            p.status)
                #TODO ps -ef
                iecho "$ nc -4 -G 1 -z localhost 8080"
                nc -4 -G 1 -z localhost 8080 || echo "Port 8080 is not listening."
                ;;
            p.db.rebuild | db.rebuild | p.dbr|dbr)
                iecho_and_eval "gradle stopTomcat rebuildDatabasePromolytics startTomcatDebug seedDataPromolytics"
                ;;
            p.db.rebuild.all | db.rebuild.all | p.dbra|dbra)
                iecho_and_eval "gradle stopTomcat rebuildDatabase startTomcatDebug seedData"
                ;;

            db.bounce | db.b)
                iecho_and_eval "brew services restart mysql@5.7"
                ;;
            db.up | db.u)
                iecho_and_eval "brew services start mysql@5.7"
                ;;
            db.down | db.d)
                iecho_and_eval  "brew services stop mysql@5.7"
                ;;
            db.tail | db.t)
                iecho_and_eval "tail -n 200 -f "$MYSQL_LOG""
                ;;
            db.status | db.s)
                iecho_and_eval "brew services list | grep 'mysql@5.7'"
                iecho "$ nc -4 -G 1 -z localhost 3306"
                nc -4 -G 1 -z localhost 3306 || echo "Port 3306 is not listening."
                ;;

            *)
                local msg="promo: $1: invalid command"
                eecho "$msg" && eecho "$USAGE" && return 1
                ;;
        esac
        shift
    done
}
alias p='promo'


__echo "[.bash_profile_promo] finished"
