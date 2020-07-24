#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# Our stuff is in .bash_profile.

# All non-interactive shells inherit environment variables BUT NOT FUNCTIONS. Further, by default Bash
# doesn't load ANY login files unless BASH_ENV is set to one; then it calls it when, for instance, a script
# gets run. It gets set to .bashrc at the top of .bashrc.
export BASH_ENV="$HOME/.bashrc"


# If debugging is not enabled, overwrite __echo with a no-op.
. $HOME/.__login.debug ".bashrc" || __echo() { :; }
__echo $"--------"
__echo "[.bashrc] starting; pid: $$, PS1='$PS1'"


export ICLOUD="$HOME/iCloud"
export DRIVE="$HOME/Drive"
export DROPBOX="$HOME/Dropbox"

export BAK="$HOME/bak"
export BIN="$HOME/bin"
export DOTFILES="$HOME/dotfiles"
export PREFS="$HOME/prefs"
export BACKUP_LOCAL="/usr/local/backup"

alias cd.bak='cd "$BAK"'
alias cd.bin='cd "$BIN"'
alias cd.dotfiles='cd "$DOTFILES"'
alias cd.prefs='cd "$PREFS"'


# Put my homemade scripts and other miscellany here at the end of the classpath.
[[ -d "$HOME/bin" ]] && export PATH="$PATH:$HOME/bin"


# Load over-engineered shell functions and aliases.
ls "$HOME/.bash_profile__*" >& /dev/null && \
	for dotpath in $HOME/.bashrc__*; do
	    dotfile="$(basename "$dotpath")"
	    __echo "[.bashrc] sourcing $dotfile"
	    . "$dotpath"
	done


__echo "[.bashrc] finished"
__echo $"--------"
