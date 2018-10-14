#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# Our stuff is in .bash_profile.

# All non-interactive shells inherit environment variables BUT NOT FUNCTIONS. Further, by default Bash
# doesn't load ANY login files unless BASH_ENV is set to one; then it calls it when, for instance, a script
# gets run. It gets set to .bashrc at the top of .bashrc.
export BASH_ENV="$HOME/.bashrc"


. "$HOME/.__login.debug.sh" ".bashrc" || __echo() { :; }
__echo $"--------"
__echo "[.bashrc] starting, PATH=$PATH"


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
for dotfile in .bash_functions .bash_aliases; do
    __echo "[.bashrc] sourcing $dotfile"
    . "$HOME/$dotfile"
done

# Load OPTIONAL over-engineered shell functions and aliases.
for dotpath in $HOME/.bashrc_* $HOME/.bash_login_temp; do
    dotfile="$(basename "$dotpath")"
    if [[ -e "$dotpath" ]]; then
        __echo "[.bashrc] sourcing $dotfile"
        . "$dotpath"
    else
        __echo "[.bashrc] missing optional $dotfile"
    fi
done


__echo "[.bashrc] finished"
__echo $"--------"
