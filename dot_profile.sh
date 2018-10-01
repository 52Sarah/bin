#!/usr/bin/env bash
#
# shellcheck disable=1090,2009,2015,2154,2155
#
# SublimeLinter/ShellCheck excluded issues; see https://github.com/koalaman/shellcheck/wiki/Ignore
# - 1090 (https://github.com/koalaman/shellcheck/wiki/SC1090): Can't follow non-constant source.
#        Use a 'source' directive to specify location.
# - 2009 (https://github.com/koalaman/shellcheck/wiki/SC2009): Consider using pgrep instead of
#        grepping ps output.
# - 2015 (https://github.com/koalaman/shellcheck/wiki/SC2015): Note that A && B || C is not
#        if-then-else. C may run when A is true.
# - 2154 (https://github.com/koalaman/shellcheck/wiki/SC2154): var is referenced but not assigned.
# - 2155 (https://github.com/koalaman/shellcheck/wiki/SC2155): Declare and assign separately to
#        avoid masking return values.

# Bash reads .bash_profile || .bash_login || .profile, whichever it finds first,
# for interactive shells. Since there's nothing bash-specific in .profile (as far as I know),
# I will put all non-interactive-ish commands into .bashrc (called by non-interactive shells) and
# have it source .bashrc.
#
# https://apple.stackexchange.com/a/13019/39935


. "$HOME/.__login.debug.sh" ".profile" || __echo() { :; }
__echo "-------------------"
__echo "[.profile] starting"


[[ -e "${HOME}/.iterm2_shell_integration.bash" ]] && source "${HOME}/.iterm2_shell_integration.bash"

set -o vi
export EDITOR=vim
export CLICOLOR=true


# WHen closing a session, add to history instead of overwriting
shopt -s histappend

shopt -s cdspell

# Store multi-line commands as one line in history
shopt -s cmdhist


# Ignore repeated lines and lines starting with ' '
export HISTCONTROL='ignoreboth'

# Number of entries to keep in history
export HISTSIZE=100000
export HISTFILESIZE=${HISTSIZE}

# Show full date, time at beginning of each line
export HISTTIMEFORMAT=' %F %T  '


# If last command was in error, display !$ instead of $.
# history -a flushes the session history to the history file
export PROMPT_COMMAND='(($?)) && _prompt_symbol="!\$" || _prompt_symbol="\$"; history -a'
# \u = user
# \h = hostname
# \w = working dir
# myinf-prod: ubuntu: ~ $
## export PS1='\h:\u \w $_prompt_symbol '
export PS1='\w $_prompt_symbol '

# Exclude from tab completion
export FIGNORE='DS_Store:'


__echo "[.profile] sourcing .bashrc"
. "$HOME/.bashrc"


__echo "[.profile] finished"
