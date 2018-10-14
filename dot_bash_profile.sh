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


# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# In case there is anything bash-specific, I'll use .bash_profile.
#
# All non-interactive shells inherit environment variables BUT NOT FUNCTIONS. Further, by default Bash
# doesn't load ANY login files unless BASH_ENV is set to one; then it calls it when, for instance, a script
# gets run. It gets set to .bashrc at the top of .bashrc.


. "$HOME/.__login.debug.sh" ".bash_profile" || __echo() { :; }
__echo "----------------"
__echo "[.bash_profile] starting"


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

# Exclude from tab completion
export FIGNORE='DS_Store:'


[[ -e "$HOME/git-completion.sh" ]] && . "$HOME/git-completion.sh"


# Set PS1 command line prompt:
# - if last command was in error, display !$ instead of $.
# - `history -a` explicitly flushes the session history to the history file
reset_prompt() {
    export PROMPT_COMMAND='(($?)) && _prompt_symbol="!\$" || _prompt_symbol="\$"; history -a'
    # \u = user, \h = hostname, \w = working dir
    export PS1='\w $ '
}
reset_prompt


# Source OPTIONAL over-engineered shell variables and aliases.
for dotpath in $HOME/.bash_profile_*; do
    dotfile="$(basename "$dotpath")"
    if [[ -e "$dotpath" ]]; then
        __echo "[.bash_profile] sourcing $dotfile"
        . "$dotpath"
    else
        __echo "[.bash_profile] missing optional $dotfile"
    fi
done

 __echo "[.bash_profile] sourcing .bashrc"
 . "$HOME/.bashrc"


__echo "[.bash_profile] finished"
__echo "----------------"$'\n'
