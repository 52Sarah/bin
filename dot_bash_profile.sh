#!/usr/bin/env bash
[[ -n "$SH_VERBOSE" ]] && echo "[.bash_profile]"

[[ -e ~/.bashrc ]] && source ~/.bashrc || ([[ -n "$SH_VERBOSE" ]] && echo "[no .bashrc]")
[[ -e ~/.profile ]] && source ~/.profile || ([[ -n "$SH_VERBOSE" ]] && echo "[no .profile]")
