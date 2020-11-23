#!/usr/bin/env bash

# Usage: xgrep [-d dir --no-log|-nl] pattern [--include|-i EXT1 [--include|-i EXT2] ...] [--exclude EXT1 [--exclude EXT2] ...]
#   -d dir  - optional root directory, default is PWD
#   --no-logs - exclude .log, .out, .csv
#   --include EXT [, EXT2, ... ]  - file extensions to limit search to
#   --exclude EXT [, EXT2, ... ]  - file extensions to exclude
#   PATT    - extended regex to search for
# Always omit .* directories
xgrep() {
    decho "\$ xgrep $*"

    read -r -d '' USAGE <<-EOF
usage:
$ xgrep PATT1 [PATT2 ...] [--dir DIR] [--all-files] [--all-folders]
[--exclude EXT1] [--exclude EXT2 ...] [--include EXT1] [--include EXT2 ...]
[--exclude-dir DIR1] [--exclude-dir DIR2 ...] [--include-dir DIR1] [--include-dir DIR2 ...]
or:
$ xgrep PATT1 [PATT2 ...] [-d DIR] [-a]
[-e EXT1] [-e EXT2 ...] [-i EXT1] [-i EXT2] ...]
[-ed DIR1] [-ed DIR2 ...] [-id DIR1] [-id DIR2] ...]
where:
--dir DIR defaults to PWD (.)
--all-files does NOT add log-like extensions to the exlcude extension list: .log .log.*  .out .out.*  .csv .csv.*
--all-folders does NOT add hidden, BAK, etc. folders to the exclude directory list
-a implies both --all-files and --all-folders
--verbose/-v sets SH_VERBOSE; --debug sets SH_DEBUG; --quiet/-q sets SH_QUIET
EOF

    local root_dir='.' all_files='' all_folders=''
    local patterns=() ext_incl=() ext_excl=() dir_incl=() dir_excl=()
    while [[ -n "$1" ]]; do
        local opt="$1" && shift
        decho "xgrep: arg: '$opt'"
        case "$opt" in
            -d* | --dir )
            local root_dir="$1"
            shift
            ;;
            --all-files )
            all_files=1
            ;;
            --all-folders )
            all_folders=1
            ;;
            -a )
            all_files=1
            all_folders=1
            ;;
            -e | --exclude )
            ext_excl+=("$1")
            shift
            ;;
            -i | --include )
            ext_incl+=("$1")
            shift
            ;;
            -ed | --exclude-dir )
            dir_excl+=("$1")
            shift
            ;;
            -id | --include-dir )
            dir_incl+=("$1")
            shift
            ;;
            -v* | --verbose )
            SH_VERBOSE=1
            unset SH_QUIET SH_DEBUG
            ;;
            --debug )
            SH_DEBUG=1 SH_VERBOSE=1
            unset SH_QUIET
            ;;
            -q* | --quiet )
            SH_QUIET=1
            unset SH_VERBOSE SH_DEBUG
            ;;
            -* )
            eecho "xgrep: illegal option $opt"
            eecho "$USAGE"
            return 1
            ;;
            * )
            patterns+=("$opt")
            ;;
        esac
    done
    [[ ${#patterns} -eq 0 ]] && eecho "xgrep: missing pattern" && eecho "$USAGE" && return 1
    ## decho_vars --prefix "  " --quote patt root_dir no_logs ext_excl ext_incl SH_VERBOSE SH_QUIET

    [[ -z "$all_files" ]] && ext_excl+=(".log\\*" ".out\\*" ".csv\\*")
    [[ -z "$all_folders" ]] && dir_excl+=("\\*/.\\*" "\\*.BAK\\*" "\\*.cache" )

    local grep_cmd=()
    grep_cmd+=("-E")     # -E extended regexp
    grep_cmd+=("-iIR")   # -i case insensitive; -I ignore binary files; -R recursive
    grep_cmd+=("'$root_dir'")

    for patt in "${patterns[@]}"; do
        grep_cmd+=("-e" "'${patt}'")
    done
    for ext in "${ext_excl[@]}"; do
        grep_cmd+=("--exclude" "\\*${ext}")
    done
    for ext in "${ext_incl[@]}"; do
        grep_cmd+=("--include" "\\*${ext}")
    done
    for dir in "${dir_excl[@]}"; do
        grep_cmd+=("--exclude-dir" "${dir}")
    done
    for dir in "${dir_incl[@]}"; do
        grep_cmd+=("--include-dir" "${dir}")
    done
    vecho_vars --prefix "  " --quote grep_cmd

    c="grep ${grep_cmd[*]}"
    iecho_and_eval "$ $c"
}
xgrep "$@"
