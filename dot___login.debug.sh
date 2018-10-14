#!/usr/bin/env bash

# For debugging login files; this file should be included at the top of each.
# The__echo function should be called only if debugging is enabled;
# it will echo its arguments and write to __login.log if one of the following is true:
#   - the SH_DEBUG env var is already set
#   - script is called with --debug as its $1
#   - existence of ~/__login.debug file
#   - existence of ~/$script.debug file, where $script is ".profile", etc.

__echo() {
    echo "$(date +'%D %T')  $*" >> "$HOME/__login.log" 
}

# return status 0 if debugging should be enabled
dot___login_debug() {
    [[ "$1" = "--debug" ]] && shift && return 0
    [[ -n "$SH_DEBUG" || -e "$HOME/__login.debug" ]] && return 0

    local script="$1"
    [[ -n "$script" && -e "$script.debug" ]] && return 0
    
    return 1
}
dot___login_debug "$@"
