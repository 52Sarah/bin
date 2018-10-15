#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# In case there is anything bash-specific, I'll use .bash_profile.
#
# All non-interactive shells inherit environment variables BUT NOT FUNCTIONS. Further, by default Bash
# doesn't load ANY login files unless BASH_ENV is set to one; then it calls it when, for instance, a script
# gets run. It gets set to .bashrc at the top of .bashrc.


# If debugging is not enabled, overwrite __echo with a no-op.
. $HOME/.__login.debug ".bash_profile" || __echo() { :; }
__echo "----------------"
__echo "[.bash_profile] starting; pid: $$, shell type: $(__shell_type), PS1='$PS1'"


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
export HISTSIZE=100000
export HISTFILESIZE=$HISTSIZE
export HISTTIMEFORMAT=' %F %T  '

# Exclude from tab completion
export FIGNORE='DS_Store:'


[[ -e $HOME/git-completion.sh ]] && . $HOME/git-completion.sh


# Change PS1 command line prompt:
# - if unset, leave unset (non-interactive shell)
# - if last command was in error, display !$ instead of $.
# - `history -a` explicitly flushes the session history to the history file
# - \u = user, \h = hostname, \w = working dir
reset_prompt() {
    : ${PS1:?}
    export PROMPT_COMMAND='(($?)) && _prompt_symbol="!\$" || _prompt_symbol="\$"; history -a'
    export PS1='\w $ '
}
reset_prompt


# Source over-engineered shell variables and aliases.
for dotpath in $HOME/.bash_profile__*; do
    dotfile="$(basename "$dotpath")"
    __echo "[.bash_profile] sourcing $dotfile"
    . "$dotpath"
done

# Source .bashrc
 __echo "[.bash_profile] sourcing .bashrc"
 . $HOME/.bashrc


__echo "[.bash_profile] finished"
__echo "----------------"$'\n'
