# DISABLED:
# Bash reads .bash_profile || .bash_login || .profile, whichever it finds first,
# for interactive shells. Since there's nothing bash-specific in .profile (as far as I know),
# I will put all commands into .bashrc (called by non-interactive shells) and have it source
# .bashrc.
#
# https://apple.stackexchange.com/a/13019/39935


#!/usr/bin/env bash

# . ~/.__login.debug.sh ".bash_profile" || __echo() { :; }
# __echo "[.bash_profile] starting, PATH=$PATH"


# for dotfile in .bashrc .profile; do
# 	[[ -e "$HOME/$dotfile" ]] && __echo "[.bash_profile] sourcing $dotfile" && source "$HOME/$dotfile"
# done


# __echo "[.bash_profile] finished, PATH=$PATH, PWD=$PWD"
