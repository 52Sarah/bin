#!/usr/bin/env bash

# For debugging via . ~/.bashrc --debug, incoming SH_DEBUG=1, or existence of ~/.login_debug
[[ "$1" == "--debug" || -e "$HOME/.bashrc.debug" ]] && __BASHRC_DEBUG=1
decho() { [[ -n "$__BASHRC_DEBUG" ]] && echo "$@"; return 0; }


decho "[.bashrc] in and out"
