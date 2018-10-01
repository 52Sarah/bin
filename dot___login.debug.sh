#!/usr/bin/env bash

# For debugging login files; this file should be included at the top of each.
# The__echo function should be called only if debugging is enabled;
# it will echo its arguments and write to __login.log if one of the following is true:
#   - the SH_DEBUG env var is already set
#   - script is callewd with --debug as its $1
#   - existence of ~/__login.debug file
#   - existence of ~/$script.debug file, where $script is ".profile", etc.

# $1 - if "1" then echo $2+; else do nothing.
__echo() {
	# echo "$(date +'%D %T')  $*" | tee -a "__login.log" 1>&2 
	echo "$(date +'%D %T')  $*" >> "__login.log" 
}

# return status 0 if debugging should be enabled
dot___login_debug() {
	[[ "$1" = "--debug" ]] && shift && return 0
	[[ -n "$SH_DEBUG" || -e "__login.debug" ]] && return 0

	local script="$1"
	[[ -n "$script" && -e "$script.debug" ]] && return 0
	
	return 1
}
dot___login_debug "$@"
