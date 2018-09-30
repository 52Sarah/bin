#!/usr/bin/env bash

# For debugging via . ~/.bash_profile --debug, incoming __BASH_PROFILE_DEBUG=1, or existence of ~/.login_debug
[[ "$1" == "--debug" || -e "$HOME/.bash_profile.debug" ]] && __BASH_PROFILE_DEBUG=1
__echo() { [[ -n "$__BASH_PROFILE_DEBUG" ]] && echo "$@"; return 0; }

__echo "[.bash_profile] starting, PATH=$PATH, PWD=$PWD"


for dotfile in .bashrc .profile; do
	[[ -e "$HOME/$dotfile" ]] && __echo "[.bash_profile] sourcing $dotfile" && source "$HOME/$dotfile"
done


__echo "[.bash_profile] finished, PATH=$PATH, PWD=$PWD"
