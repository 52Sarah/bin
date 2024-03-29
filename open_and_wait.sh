#!/usr/bin/env bash
. "$HOME/.functions"

SCRIPT_NAME="$(basename "$0")"

USAGE="usage: $SCRIPT_NAME file [app]"

function open_and_wait() {

    local filename="$1"; shift
    local app="$1"; shift


    # Verify filename is specified and that it exists.
    [[ -z "$filename" ]] && eecho "$USAGE" && return 1
    [[ ! -e "$filename" ]] && eecho "$SCRIPT_NAME: $filename: no such file" && return 1

    # Parse extension, which is required if no app is specified.
    local file_ext
    [[ "$filename" =~ ^.+\.[^.]+$ ]] && file_ext="${filename##*.}"
    if [[ -z "$app" && -z "$file_ext" ]]; then
        eecho "$SCRIPT_NAME: $filename: no file extension and no app specified"
        eecho "$USAGE"
        return 1
    fi

    pre_cksum="$(cksum "$filename")"
    >&2 vecho "BEFORE: $(date)  $(ls -oF "$filename")  $pre_cksum"

    [[ -n "$app" ]] && app_option="-a $app" || app_option=''
    open $app_option -W -n "$filename"

    post_cksum="$(cksum "$filename")"
    >&2 vecho " AFTER: $(date)  $(ls -oF "$filename")  $post_cksum"

    if [[ "$pre_cksum" = "$post_cksum" ]]; then
         >&2 vecho "No change"
        return 1
    fi
    return 0
}
open_and_wait $@
