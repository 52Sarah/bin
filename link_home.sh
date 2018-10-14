#!/usr/bin/env bash

link_home() {(
    set -o errexit

    local SH_VERBOSE="$SH_VERBOSE"
    [[ "$1" =~ -?-v(erbose)? ]] && SH_VERBOSE=1 && shift
    [[ "$SH_VERBOSE" ]] && SH_VERBOSE="-v"

    # ~
    for d in $DOTFILES/dot_*; do
        local hname="$(basename "$d")"
        hname="$HOME/.${hname:4}"  # minus 'dot_'
        hname="${hname%.sh*}"      # minus '.sh'
        ln -sf $SH_VERBOSE "$d" "$hname"
    done

    # iCloud
    for n in bin dotfiles; do
        local link="$HOME/$n"
        [[ -e "$link" && ! -L "$link" ]] && echo "link_homes: existing directory is not a link: $n" && return 1
        vecho_and_eval "rm -f "$link""
        vecho_and_eval "ln -s $SH_VERBOSE "$HOME/iCloud/$n" "$link""
    done
)}
link_home "$@"
