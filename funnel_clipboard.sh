#!/usr/bin/env bash
. "$HOME/.functions"

# Pass the clipboard through the command given as $* and save its results as a new
# clipboard entry. Generally called by Alfred.)
#
# Enable vecho by setting _VERBOSE=1
# Disable iecho by setting _QUIET=1

SCRIPT_NAME="$(basename "$0")"
vecho "START $SCRIPT_NAME"

cmd="$*"
vecho "cmd=$cmd"

IN="$(pbpaste)"
pipeline="pbpaste | $cmd"
vecho "pipeline=$pipeline"
OUT="$(eval "$pipeline")"
pbcopy <<<"$OUT"

# Unless we're troubleshooting, minimize output
if [[ -n "$_VERBOSE" ]]; then
    # pass first 80 characters of IN and OUT to output
    (( ${#IN} > 80 )) && IN="${IN:1:80}..."
    echo "IN='$IN'"
    echo "--"
fi

(( ${#OUT} > 80 )) && OUT="${OUT:1:80}..."
iecho "$OUT"
