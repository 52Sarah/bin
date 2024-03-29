#!/usr/bin/env bash

pull_backups() {
    local dirs=("$@")
    [[ ! "$1" ]] && dirs=("$BIN" "$DOTFILES" "$HOME/notes" "$PREFS")

    for d in "${dirs[@]}"; do
        iecho "pull_backups: $d"
        pull_one_backup "$d"
    done
}

pull_one_backup() {
    local USAGE="usage: pull_one_backup from_path"
    local dstamp=$(date +'%Y%m%d')
    
    local from_path="${1:?$USAGE}"
    [[ ! -d "$from_path" ]] && eecho "pull_one_backup: $from_path: not a directory" && return 1
    
    local to_dir_name="$(basename "$from_path")"
    local to_dir_path="$BAK/${to_dir_name}-backup/$to_dir_name.BAK.$dstamp"

    iecho "pull_one_backup: $from_path -> $(tilde_compress "$to_dir_path")"
    mkdir -p -v "$to_dir_path"
    find -L "$from_path" -depth 1 ! -name '.git' -print -exec cp -p -R -L "{}" "$to_dir_path/" \;
}

pull_backups $@