#!/usr/bin/env bash
. "$HOME/.functions"

# Pass the clipboard through the command given as $* and save its results as a new
# clipboard entry. Generally called by Alfred.)
#
# Enable vecho by setting SH_VERBOSE=1
# Disable iecho by setting SH_QUIET=1

SCRIPT_NAME="$(basename "$0")"
vecho "START $SCRIPT_NAME"

cmd="$*"
vecho "cmd=$cmd"

INTEXT="$( pbpaste )"
#OUTTEXT="$(pbpaste | $cmd)"
pipeline="pbpaste | $cmd"
vecho "pipeline=$pipeline"
OUTTEXT="$( eval "$pipeline" )"
pbcopy <<<"$OUTTEXT"

# Unless we're troubleshooting, minimize output
if [[ -n "$SH_VERBOSE" ]]; then
    # pass first 80 characters of IN and OUT to output
    (( ${#INTEXT} > 80 )) && INTEXT="${INTEXT:1:80}..."
    echo "INTEXT='$INTEXT'"
    echo "--"
fi

(( ${#OUTTEXT} > 80 )) && OUTTEXT="${OUTTEXT:1:80}..."
iecho "$OUTTEXT"
