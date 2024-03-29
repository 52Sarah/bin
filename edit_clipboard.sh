#!/usr/bin/env bash

function edit_clipboard() {
    tempfile="/var/tmp/edit_clipboard_$(date +%s).txt"
    pbpaste > "$tempfile"
    pre_cksum="$(cksum "$tempfile")"

     >&2 date; >&2 ls -l "$tempfile"

    /opt/bin/subl --new --wait "$tempfile"

     >&2 date; >&2 ls -l "$tempfile"
    post_cksum="$(cksum "$tempfile")"

    if [[ "$pre_cksum" = "$post_cksum" ]]; then
         >&2 echo "No change"
        return 0
    fi

    pbcopy < "$tempfile"
    rm "$tempfile"
}
edit_clipboard $@
