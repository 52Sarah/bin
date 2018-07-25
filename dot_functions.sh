#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2010,SC2012,SC2155,SC2156
#   SC1091 - not following (file)
#   SC2010 - don't use ls | grep, rather use glob or for
#   SC2012 - use find instead of ls
#   SC2155 - declare and assign separately
#   SC2156 - injecting filenames in find -exec

[[ -n "$SH_VERBOSE" ]] && echo "[.functions]"

shopt -s extglob

# Try and use gnu ls if possible, flexibler date formatting.
type gls >& /dev/null && function ls() { gls "$@"; }

# error, info, verbose and debug levels; uses SH_ vars which can be set pre-execution or via -q, -v and -d
echo_with_optional_nl() {
    if [[ "$1" = "-n" ]]; then
        shift
        echo -n "$*"
    else
        echo "$*"
    fi
}
iecho() { [[ -z "$SH_QUIET" ]] && echo_with_optional_nl "$@"; return 0; }
eecho() { >&2 echo_with_optional_nl "$@"; return 0; }  # to stderr
vecho() { ([[ -n "$SH_VERBOSE" ]] || [[ -n "$SH_DEBUG" ]]) && echo_with_optional_nl "$@"; return 0; }
decho() { [[ -n "$SH_DEBUG" ]] && echo_with_optional_nl "$@"; return 0; }
evecho() { ([[ -n "$SH_VERBOSE" ]] || [[ -n "$SH_DEBUG" ]]) && >&2 echo_with_optional_nl "$@"; return 0; }

# If $1, $2 are --echo xecho then use 'xecho' instead of 'echo', where x is i, v, d or e
echo_and_eval()  {
    local echo_fn="echo"
    [[ "$1" == "--echo" ]] && echo_fn="$2" && shift 2
    local cmd="$(strip_prefix "$*" "$ ")"
    $echo_fn "$ $cmd"
    eval "$cmd"
}
eecho_and_eval() { echo_and_eval --echo eecho "$@"; }
iecho_and_eval() { echo_and_eval --echo iecho "$@"; }
vecho_and_eval() { echo_and_eval --echo vecho "$@"; }
decho_and_eval() { echo_and_eval --echo decho "$@"; }

# "What-if" echo: if WHAT_IF env var is set, simply echo the given command; else iecho then execute it.
wecho_and_eval() {
    local cmd="$*"
    [[ -n "$SH_WHATIF" && ! "${SH_WHATIF,,}" =~ 0|false ]] && echo "# WHATIF> $cmd" && return 0
    iecho_and_eval "$cmd"
}
alias wecho='wecho_and_eval'

is_macos()  { [[ "$(uname -s)" == "Darwin" ]]; }
is_cygwin() { [[ "$(uname -s | tr [[:upper:]] [[:lower:]])" =~ ^cygwin.* ]]; }
is_ubuntu() { grep -s "ID=.?ubuntu.?" /etc/os-release >& /dev/null; }
is_centos() { grep -E -s "ID=.?centos.?" /etc/os-release >& /dev/null; }
is_amazon() { grep -E -s "ID=.?amzn.?" /etc/os-release >& /dev/null; }

# If $1 is defined, echo "alias", "keyword", "function", "builtin" or "file".
# If not defined, echo "" and return error status.
typeof_command() {
    type -t "$1"
    return  # type -t fails silently if not defined
}
alias_defined() { [[ "$(typeof_command "$1")" = "alias" ]]; }
function_defined() { [[ "$(typeof_command "$1")" = "function" ]]; }
executable_exists() { [[ "$(typeof_command "$1")" = "file" ]]; }


# Perform the prefixed command only on the newest file in the given folder (or PWD).
llnew() {
    [[ "${1:0:2}" = "-n" ]] && local lines=$2 && shift 2
    ls -ohtr "$@" | tail -n "${lines:-10}"
}
catnew() {
    local d="${1:-$PWD}"
    local f="$d/$(ls -1tr "$d" | tail -n 1)"
    echo "cat $f ..."
    cat "$f"
}
cdnew() {
    local d="${1:-$PWD}"
    local f="$d/$(ls -1trF "$d" | grep -E '/$' | tail -n 1)"
    echo "cd $f ..."
    cd "$f" || return 1
}
headnew() {
    local d="${1:-$PWD}"
    local lines="${2:-10}"
    local f="$d/$(ls -1tr "$d" | tail -n 1)"
    echo "head $f ..."
    head -n "$lines" "$f"
}
opennew() {
    local d="${1:-$PWD}"
    local f="$d/$(ls -1tr "$d" | tail -n 1)"
    echo "open $f ..."
    # shellcheck disable=SC2015  # && and ||
    is_macos && open "$f" || vi "$f"
}

# Change directory to the given link's target, either the file's parent or the directory itself.
cdln() {
    local link="$1"
    local target="$(readlink "$link")"
    # shellcheck disable=SC2015  # && and ||
    if [[ -d "$target" ]]; then
        cd "$target" || return 1
    else
        cd "$(dirname "$target")" || return 1
    fi
}

# If any listed file is a symlink, operate on its target
cpln() {
    local opts=()
    while [[ -n "$1" ]]; do
        local opt="$1"
        [[ -L "$opt" ]] && opt="$(readlink "$opt")" && echo "cpln: $1 -> $opt"
        opts+=("$opt")
        shift
    done
    #shellcheck disable=2068 #double quote array expansion
    cp -pv ${opts[@]}
}

# Show directory of the given link's target, either the file's parent or the directory itself.
lsln() {
    local sw=()
    while [[ "${1:0:1}" = "-" ]]; do sw+=("$1") && shift; done
    for link in "$@"; do
        local target="$(readlink "$link")"
        [[ ! -d "$target" ]] && target="$(dirname "$target")"
        local c="ls ${sw[*]} $target"
        [[ -z "$SH_QUIET" ]] && echo $'\n'"\$ $c"
        eval "$c"
    done
}
llln() { lsln -ohtr "$@"; }

# Touch each symlink to match its target's modification date.
# Usage: touchln [--quiet | --verbose] link1 [...]
touchln() {
    local count=0
    for link in "$@"; do
        [[ "$link" =~ ^-?-q(uiet)?$ ]] && SH_QUIET=1 && unset SH_VERBOSE && continue
        [[ "$link" =~ ^-?-v(erbose)?$ ]] && SH_VERBOSE=1 && unset SH_QUIET && continue
        [[ ! -e "$link" ]] && eecho "touchln: ${link}: no such file" && return 1
        [[ ! -L "$link" ]] && vecho "touchln: ${link}: not a symlink" && continue
        local target="$(readlink "$link")"
        [[ "$(file_modified_seconds "$link")" = "$(file_modified_seconds "$target")" ]] && vecho "touchln: $link: mtime already matches" && continue
        touch -h "$link" -r "$target"
        ((count++))
        [[ -z "$SH_QUIET" ]] && ls -ohF -d "$link"
    done
    ((!count)) && return 1
    iecho "INFO: touchln: updated $count links"
}
touchln_R() {
    # shellcheck disable=SC2206  # quote to avoid split
    local dirs=($@)
    (( ! ${#dirs[@]} )) && dirs+=("$PWD")
    for dir in "${dirs[@]}"; do
        for link in $(find "$dir" -type l | sort); do
            touchln "$link"
        done
    done
}

touchdir() {
    [[ -z "$1" ]] && eecho "usage: touchdir dir [...]" && return 1
    local count=0
    for dir in "$@"; do
        # vecho "touchdir: dir='$dir'"
        [[ "$dir" =~ ^-?-q(uiet)?$ ]] && SH_QUIET=1 && unset SH_VERBOSE && continue
        [[ "$dir" =~ ^-?-v(erbose)?$ ]] && SH_VERBOSE=1 && unset SH_QUIET && continue
        [[ ! -e "$dir" ]] && eecho "touchdir: ${dir}: no such directory" && return 1
        [[ ! -d "$dir" ]] && vecho "touchdir: ${dir}: not a directory" && continue

        local newest_child_name="$(ls -A1t "$dir/"| head -n 1)"
        # vecho "touchdir: newest_child_name = $newest_child_name"
        [[ -z "$newest_child_name" ]] && vecho "touchdir: empty directory: $dir" && continue
        local newest_child="$dir/$newest_child_name"

        [[ "$(file_modified_seconds "$dir")" == "$(file_modified_seconds "$newest_child")" ]] && vecho "touchdir: $dir: mtime already matches $newest_child" && continue
        iecho "Updating mtime of ${dir/$HOME/~} from $(file_info 'mdate mtime' "$dir") to match $newest_child_name, $(file_info 'mdate mtime' "$newest_child")"

        touch -h -r "$newest_child" "$dir"
        ((count++))
    done
    ((!count)) && return 1
    vecho "INFO: touchdir: updated $count directories"
}
touchdir_R() {
    # shellcheck disable=SC2206  # quote to avoid split
    local dirs=($@); [[ ${#dirs[@]} == 0 ]] && dirs=("$PWD")
    for dir in "${dirs[@]}"; do
        # local subdirs="$(find "$dir" -depth ! -type f)"
        # vecho "touchdir_R: for $dir, found subdirs: $subdirs"
        # for subdir in $subdirs; do
        local subdirs="$(find "$dir" -depth ! -type f -print)"
        # vecho "touchdir_R: for $dir, found subdirs: [$subdirs]"
        while read -r subdir; do
            # vecho "touchdir_R: calling touchdir for subdir='$subdir'"
            touchdir "$subdir"
        done <<< $subdirs
        # vecho "touchdir_R: calling touchdir for dir='$dir'"
        touchdir "$dir"
    done
}


# find . -name $1, then echo the first result in sorted order
find_1() {
    local name="$1" && shift
    local find_opts="$*"
    [[ -z "$name" ]] && eecho "ERROR: Usage: find_1 name NAME" && return 1

    local c="find . -name '$name' ${find_opts} -print -quit | sort -s | head -n 1"
#decho_vars name find_opts c

local path="$(eval "$c")"
[[ -n "$path" && -e "$path" ]] && echo "$path" && return 0

[[ -n "$path" ]] && eecho "find_1: $path: Invalid path, somehow"
return 1
}

cdf() {
    local path="$(find_1 "$1" -type d)"
    [[ -z "$path" ]] && eecho "cdf: $1: No such file or directory" && return 1

    vecho_and_eval "cd '$path'"
}

headf() {
    local lines=10
    [[ "$1" = "-n" ]] && lines=$2 && shift 2

    local path="$(find_1 "$1" -type f)"
    [[ -z "$path" ]] && eecho "headf: $1: No such file or directory" && return 1

    vecho_and_eval "head -n $lines '$path'"
}

catf() {
    local path="$(find_1 "$1" -type f)"
    [[ -z "$path" ]] && eecho "catf: $1: No such file" && return 1

    vecho_and_eval " cat '$path'"
}


# Delete 0-byte files. If $1 == -r recurse; else only check files directly in the target folders.
# If no folders are specifed, default to PWD.
# Usage: rm0 [-r] [dir...]
rm0() {
    local maxdepth="-maxdepth 1"
    [[ "$1" =~ -[rR] ]] && maxdepth= && shift

    local dirs="${@:-.}"
    for d in $dirs; do
        [[ ! -d "$d" ]] && eecho "rm0: missing or non-folder: $d" && return 1
        iecho_and_eval "find $d $maxdepth -size 0  -print -delete"
    done
}



# Display selected info from a jar's manifest.
# If --all is $1, show the entire manifest.
jar_info() {
    if ! typeof_command "unzip"; then
        eecho "jar_info: unzip is not installed"
        return 1
    fi

    [[ "$1" =~ --?a(ll)? ]] && local opt_all=1 && shift

    local jar_file="$1"
    [[ -z "$jar_file" ]] && eecho "jar_info: missing jar_file operand" && return 1
    [[ ! -e "$jar_file" ]] && eecho "jar_info: $jar_file: not found" && return 1

    if [[ -z "$opt_all" ]]; then
        unzip -c "$jar_file" "META-INF/MANIFEST.MF" | grep -E -i -e "build-jdk" -e "Implementation-(Title|Version)" -e "Bundle-(SymbolicName|Doc-URL)"
    else
        unzip -c "$jar_file" "META-INF/MANIFEST.MF"
    fi
}

# Check each archive recursively from PWD for the given filename expression.
# $1 - filename expression
# $2 - archive type, default 'zip'
zip_find() {
    if ! typeof_command "unzip"; then
        eecho "zip_find: unzip is not installed"
        return 1
    fi

    local filename_expr="$1"; shift
    [[ -z "$filename_expr" ]] && eecho "zip_find: missing filename_expr operand; usage: zip_find filename_expr [archive_type]" && return 1

    local archive_type="${1:-zip}"; shift
    [[ "${archive_type:0:1}" = "." ]] && archive_type="${archive_type:1}"

    # shellcheck disable=0
    find . -name "*.$archive_type" -exec sh -c "unzip -l '{}' | grep -i -e '$filename_expr' -e 'Archive:'" \; \
    | grep -B 1 "$filename_expr" \
    | sort
}
jar_find() {
    zip_find "$1" "jar"
}

# Rename all files in a given directory, by substituting NEW_TEXT for OLD_TEXT;
# regular expressions allowed. Files not macthing OLD_TEXT are left alone.
# Usage: xmv ...
#   old_text  - text to find and replace
#   new_text - replacement text, or blank to simply remove old_text
#   dir  - optional, directory, default is PWD
#   limit - optional, max number of files
xmv() {
    local old_text="$1" && shift
    local new_text="$1" && shift
    local dir="${1:-.}" && shift
    local limit=${1:-0}
    decho_vars old_text new_text dir limit

    [[ -z "$old_text" ]] || [[ -z "$new_text" ]] && eecho "usage: xmv old new [dir]" && return 1

    local sed_cmd="s/^(.*)${old_text}(.*)$/\\1${new_text}\\2/g"
    decho_vars sed_cmd

    for old_name in $dir/*; do
        decho_vars old_name
        local new_name="$(echo "$old_name" | sed -E -e "$sed_cmd")"
        [[ "$old_name" = "$new_name" ]] && continue
        decho_vars new_name
        local mv_cmd="mv -v \"$dir/$old_name\" \"$dir/$new_name\""
        decho_vars mv_cmd
        wecho --quiet "$mv_cmd"
        (( --limit <= 0 )) && break
    done
}

cksum_R() {
    local root="${1:-$PWD}" && shift
    for f in $(find "$root" -type f | sort); do
        local trimmed_f="$(sed -E -e "s_^$PWD/__;" <<< "$f")"
        cksum "$trimmed_f" | awk -v PWD="$PWD" -e '{printf "%12d %12'\''d %s\n", $1, $2, $3}'
    done
}


# Recursively list size in kb, modification date, and name, sorted by date ascending.
# Usage: $0 [root [pattern]]
lltr_R() {
    local root="${1:-.}"; shift
    local patt="$1"; shift

    local find_cmd=("find")
    is_macos && find_cmd+=("-E")
    find_cmd+=("\"$root\"")
    is_macos || find_cmd+=("-regextype posix-extended")
    find_cmd+=("! -type l")
    [[ -n "$patt" ]] && find_cmd+=("-name '$patt'")
    find_cmd+=("! -regex '.*/(bin|BUILD|DIST|.*\\.BAK).*'")
    if is_macos; then
        find_cmd+=("-exec stat -t '%F %T' -f '%Sm %z"$'\t'"%N' {} \\;")
    else
        find_cmd+=("-printf '%TY-%Tm-%Td %TH:%TM\\t%p\\n'")
    fi
    decho_vars root patt find_cmd

    vecho "${find_cmd[*]}"
    eval "${find_cmd[*]}" \
    | awk -v FS=$'\t' -v HOME="$HOME" -v PWD="$PWD"  '{gsub(PWD,".",$2); gsub("^" HOME,"~",$2); printf "%s  %s\n", $1, $2};' \
    | sort --stable
}

# Display counts of files, directories and links in each directory, computed recursively.
# Default is every directory in PWD.
countf() {
    local directories="$*"
    # shellcheck disable=SC2125  # unquoted brace expansion
    [[ -z "$directories" ]] && directories="$(echo {.??,}*)"

    for dir in $directories; do
        [[ "$dir" =~ ^-?-q(uiet)?$ ]] && SH_QUIET=1 && unset SH_VERBOSE && continue
        [[ "$dir" =~ ^-?-v(erbose)?$ ]] && SH_VERBOSE=1 && unset SH_QUIET && continue
        [[ ! -d "$dir" ]] && vecho "countf: ${dir}: not a directory" && continue

        local files="$(find "$dir" -type f | wc -l)"
        local directories="$(find "$dir" -type d | wc -l)"
        local links="$(find "$dir" -type l | wc -l)"

        #printf '%5d files  %4d directories  %3d links  %12s  %s  %s\n' \
        printf '%5d %4d/ %3d@  %12s  %s  %s\n' \
            "$files" "$directories" "$links" \
            "$(local bytes="$(du -s "$dir" | cut -f1)"; commafy "$bytes")" \
            "$(file_info 'mdate mtime' "$dir")" \
            "$dir"
    done
}

type realpath >& /dev/null || \
realpath() {
    while [[ "${1:0:1}" = "-" ]]; do
        [[ "$1" = "-v" ]] && local VERBOSE=1 && shift && continue
        [[ "$1" = "-t" ]] && local TILDE=1 && shift && continue
    done
    local target="${1:-$PWD}" && shift
    [[ -n "$VERBOSE" ]] && echo "target = $target"

    [[ -L "$target" ]] && eecho "$(readlink "$target")" && return 0

    local path="$(cd "$(dirname "$target")" || return 1; pwd)"
    [[ -n "$VERBOSE" ]] && echo "path   = $path"
    local lhs="$path/$(basename "$target")"
    [[ -n "$VERBOSE" ]] && echo "lhs    = $lhs"
    lhs="$(sed -E "s:/+:/:g" <<<"$lhs")"
    [[ -n "$VERBOSE" ]] && echo "lhs    = $lhs"
    local rhs=""
    while true; do
        [[ -n "$VERBOSE" ]] && echo "  ........"
        [[ -n "$VERBOSE" ]] && echo "  lhs    = $lhs"
        [[ -n "$VERBOSE" ]] && echo "  rhs    = $rhs"

[[ -d "$lhs" ]] && lhs="$(cd "$lhs" || return 1; pwd)"  #normalize ., ..
if [[ -L "$lhs" ]]; then
    local ret="$(readlink "${lhs}")"
    [[ -n "$rhs" ]] && ret+="/${rhs}"
    [[ -n "$TILDE" ]] && ret="${ret/$HOME/\~}"
    echo "$ret"
    return 0
fi

local leaf="${lhs##*/}"  # ##*/ = after last /, or input if no /
[[ -n "$VERBOSE" ]] && echo "  leaf   = $leaf"
if [[ "$lhs" = "/" ]] || [[ "$lhs" = "$leaf" ]]; then
    local ret="${lhs}/${rhs}" && [[ -z "$rhs" ]] && ret="${lhs}"
    [[ -n "$TILDE" ]] && ret="${ret/$HOME/\~}"
    echo "$ret"
    return 0
fi

lhs="${lhs%/*}"  # %/* = before last /
[[ "$leaf" = "." ]] && continue
[[ -n "$rhs" ]] && rhs="${leaf}/${rhs}" || rhs="${leaf}"
done
}


# For each variable name, echo as "var = value"; display arrays and hashes nicely.
echo_vars() {
    local USAGE=$(cat <<-EOF
	echo_vars: usage: echo_vars [-e env_prefix] [-t title -p prefix -q quote -w nchars -h] var [var ...]
	In addition to switches, corresponding env vars can be set:
	-e --env-prefix ECHO_VARS_ENV_PREFIX  V for vecho, D for decho, W for wecho; prefix for env vars
	E.g., use VECHO_VARS_TITLE if env-prefix is 'V'
	-t --title      ECHO_VARS_TITLE       Row written above the loop, with no added indentation
	-p --prefix     ECHO_VARS_PREFIX      Text, often whitespace, to write at start of each line
	-q --quote      ECHO_VARS_QUOTE       Delimit each value with single quotes
	-w --width      ECHO_VARS_WIDTH       Minimum width for variable name; default is 8
	-h --home       ECHO_VARS_HOME        Substitue ~ for $HOME
	-n --noblanks   ECHO_VARS_NOBLANKS    Suppress blank/undefined variables
	-f --files      ECHO_VARS_FILES       Note existing filenames with [*] at end
	EOF
    )

    # Incoming environment variables act as defaults. The prefix allows the caller to have different
    # defaults in place for each command.
    if [[ "$1" =~ ^-e|^--env-prefix ]]; then
        ECHO_VARS_ENV_PREFIX="$2" && shift 2
    fi
    if [[ -n "$ECHO_VARS_ENV_PREFIX" ]]; then
        for var in  ECHO_VARS_TITLE ECHO_VARS_PREFIX ECHO_VARS_QUOTE ECHO_VARS_WIDTH ECHO_VARS_HOME ECHO_VARS_NOBLANKS; do
            # Excellent or horriblw bash scripting...basically doing this, for each ECHO_VARS_ variable (assuming prefix V):
            # if [[ -n "$VECHO_VARS_TITLE" ]]; then ECHO_VARS_TITLE="$VECHO_VARS_TITLE"; fi
            if [[ -n $(eval echo "\$$ECHO_VARS_ENV_PREFIX$var") ]]; then
                eval "${var}=\$$ECHO_VARS_ENV_PREFIX$var"
            fi
        done
        # decho "After ECHO_VARS_ prefix copying:"
        # [[ -n "$ECHO_VARS_ENV_PREFIX" ]] && decho "  ECHO_VARS_ENV_PREFIX = $ECHO_VARS_ENV_PREFIX"
        # [[ -n "$ECHO_VARS_TITLE" ]] && decho "  ECHO_VARS_TITLE = $ECHO_VARS_TITLE"
        # [[ -n "$ECHO_VARS_PREFIX" ]] && decho "  ECHO_VARS_PREFIX = $ECHO_VARS_PREFIX"
        # [[ -n "$ECHO_VARS_QUOTE" ]] && decho "  ECHO_VARS_QUOTE = $ECHO_VARS_QUOTE"
        # [[ -n "$ECHO_VARS_WIDTH" ]] && decho "  ECHO_VARS_WIDTH = $ECHO_VARS_WIDTH"
        # [[ -n "$ECHO_VARS_HOME" ]] && decho "  ECHO_VARS_HOME = $ECHO_VARS_HOME"
        # [[ -n "$ECHO_VARS_NOBLANKS" ]] && decho "  ECHO_VARS_NOBLANKS = $ECHO_VARS_NOBLANKS"
    fi

    while [[ "$1" =~ ^- ]]; do
        case "$1" in
            -t|--title )    ECHO_VARS_TITLE="$2" && shift  ;;
            -p|--prefix )   ECHO_VARS_PREFIX="$2" && shift  ;;
            -q|--quote )    ECHO_VARS_QUOTE=1  ;;
            -w|--width )    ECHO_VARS_WIDTH="$2" && shift  ;;
            -h|--home )     ECHO_VARS_SUB_HOME=1  ;;
            -n|--noblanks ) ECHO_VARS_NOBLANKS=1  ;;
            -f|--files )    ECHO_VARS_FILES=1  ;;
            -v|--verbose )  SH_VERBOSE=1  ;;
            -- )            break  ;;
            * )             eecho "Unexpected switch: '$1'" && return 1  ;;
        esac
        shift
    done
    [[ -z "$1" ]] && echo "$USAGE" && return 1

    ECHO_VARS_WIDTH=$(( - ${ECHO_VARS_WIDTH:-0} ))  #left-justify
    [[ -n "$ECHO_VARS_QUOTE" ]] && ECHO_VARS_QUOTE="'"
    # decho "After options parsed:"
    # decho "  ECHO_VARS_TITLE = $ECHO_VARS_TITLE"
    # decho "  ECHO_VARS_PREFIX = $ECHO_VARS_PREFIX"
    # decho "  ECHO_VARS_QUOTE = $ECHO_VARS_QUOTE"
    # decho "  ECHO_VARS_WIDTH = $ECHO_VARS_WIDTH"
    # decho "  ECHO_VARS_HOME = $ECHO_VARS_HOME"
    # decho "  ECHO_VARS_NOBLANKS = $ECHO_VARS_NOBLANKS"

    [[ -n "$ECHO_VARS_TITLE" ]] && echo "$ECHO_VARS_TITLE"
    for var in "$@"; do
        #local var="$(echo "$var" | xargs)"

        local var_typeof=$(eval "typeof $var")
        if [[ "$var_typeof" =~ undefined|null ]]; then
            [[ -z "$ECHO_VARS_NOBLANKS" ]] && printf "%s%${ECHO_VARS_WIDTH}s = %s\\n" "$ECHO_VARS_PREFIX" "$var" "<$var_typeof>"
            continue
        fi

        local var_array="$(eval "echo \$\\{${var}[@]\\}")"
        local var_array_length="$(eval "echo \$\\{#${var}[@]\\}")"
        local var_array_length_value="$(eval "echo $var_array_length")"
        decho "var: $var, _typeof: $var_typeof, _array: $var_array, _length: $var_array_length, _value: $var_array_length_value"

        local var_array_value="$(eval "echo $var_array")"
        [[ -n "$ECHO_VARS_SUB_HOME" ]] && var_array_value="${var_array_value/$HOME/\~}"
        local var_array_keys="$(eval "echo \$\\{!${var}[@]\\}")"
        local var_array_keys_value="$(eval "echo $var_array_keys")"
        decho "var: $var, _array_value: $var_array_value, _array_keys: $var_array_keys, _value: $var_array_keys_value"

        # empty array or hash
        if [[ $var_array_length_value -eq 0 && -z "$ECHO_VARS_NOBLANKS" ]]; then
            if [[ "$var_typeof" = "array" ]]; then
                printf "%s%${ECHO_VARS_WIDTH}s = %s\\n" "$ECHO_VARS_PREFIX" "$var" "[]"
                continue
            elif [[ "$var_typeof" = "hash" ]]; then
                printf "%s%${ECHO_VARS_WIDTH}s = %s\\n" "$ECHO_VARS_PREFIX" "$var" "{}"
                continue
            fi
        fi

        # scalar
        if [[ "$var_array_keys_value" = "0" ]]; then
            decho "scalar: var = $var, var_array_keys_value = '$var_array_keys_value'"
            if [[ -n "$var_array_value" || -z "$ECHO_VARS_NOBLANKS" ]]; then
                # note if this is an existing filename
                if [[ -n "$ECHO_VARS_FILES" && -e "$var_array_value" ]]; then
                    if [[ -L "$var_array_value" ]]; then
                        var_array_value="$var_array_value [l]"
                    elif [[ -d "$var_array_value" ]]; then
                        var_array_value="$var_array_value [d]"
                    else
                        var_array_value="$var_array_value [f]"
                    fi
                fi
                printf "%s%${ECHO_VARS_WIDTH}s = ${ECHO_VARS_QUOTE}%s${ECHO_VARS_QUOTE}\\n" \
                "$ECHO_VARS_PREFIX" "$var" "$var_array_value"
            fi
            continue
        fi

        # array or hash
        # local maxlen=$(( 0 - $ECHO_VARS_WIDTH))
        # for k in $(eval echo "$var_array_keys"); do
        #   [[ $maxlen -lt ${#k} ]] && maxlen=${#k}
        # done
        # decho -n "$ECHO_VARS_PREFIX" && echo -n "$var = "
        echo -n "$var "
        [[ "${var_array_keys_value:0:2}" = "0 " ]] && echo "[" || echo "{"
        for k in $(eval echo "$var_array_keys"); do
            local val_cmd="printf '%s' \"\${${var}[$k]}\""
            decho "echo_vars: val_cmd: '$val_cmd'"

            local val="$(eval "$val_cmd")"
            [[ -n "$SH_DEBUG" ]] && printf "echo_vars: k: '%s', val: '%s'\\n" "$k" "$val"

            # note if this is an existing filename
            if [[ -n "$ECHO_VARS_FILES" && -e "$val" ]]; then
                if [[ -L "$val" ]]; then
                    val="$val [l]"
                elif [[ -d "$val" ]]; then
                    val="$val [d]"
                else
                    val="$val [f]"
                fi
            fi
            printf "%s  %${ECHO_VARS_WIDTH}s : ${ECHO_VARS_QUOTE}%s${ECHO_VARS_QUOTE}\\n" \
            "$ECHO_VARS_PREFIX" "$k" "$val"
        done
        [[ "${var_array_keys_value:0:2}" = "0 " ]] && echo "$ECHO_VARS_PREFIX]" || echo "$ECHO_VARS_PREFIX}"

    done
}
iecho_vars() { [[ -z "$SH_QUIET" ]] && echo_vars -e I "$@"; return 0; }
eecho_vars() { >&2 echo_vars -e E "$@"; }
vecho_vars() { ([[ -n "$SH_VERBOSE"||-n "$SH_DEBUG" ]]) && echo_vars -e V "$@"; return 0; }
decho_vars() { [[ -n "$SH_DEBUG" ]] && echo_vars -e D "$@"; return 0; }

# Returns 1 of:
# - undefined
# - null
# - scalar
# - array
# - hash
# - unknown
typeof() {
    local var="$1"
    [[ -z "$var" ]] && eecho "usage: typeof var" && return 1

    read -r opt expr <<< "$(declare -p "$var" 2> /dev/null | cut -d' ' -f 2-3)"
    #decho "var=$var, opt=$opt, expr=$expr"
    [[ -z "$opt$expr" ]] && echo "undefined" && return 0
    [[ "$opt" = "-A" ]] && echo "hash" && return 0
    [[ "$opt" = "-a" ]] && echo "array" && return 0
    [[ "$expr" =~ .+=.+ ]] && echo "scalar" && return 0
    [[ "$expr" =~ .+ ]] && echo "null" && return 0
    echo "unknown"
}


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
    decho_vars --prefix "  " --quote patt root_dir no_logs ext_excl ext_incl SH_VERBOSE SH_QUIET

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


# Move file $1 to folder/file $2, then create symlink to it in its original place.
mv_and_ln() {
    while [[ "${1:0:1}" = "-" ]]; do
        case "$1" in
            -w|--what?(-)if )   SH_WHATIF=1 && shift  ;;
            -v|--verbose )      SH_VERBOSE=1 && shift  ;;
            *)                  break  ::
        esac
    done

    local orig_file="$1"; shift
    [[ -z "$orig_file" ]] && eecho "ERROR: Usage: mv_and_ln orig target -- missing orig" && return 1
    [[ ! -e "$orig_file" ]] && eecho "ERROR: Usage: mv_and_ln orig target -- orig '$orig_file' not found" && return 1
    [[ -L "$orig_file" ]] && eecho "ERROR: Usage: mv_and_ln orig target -- orig '$orig_file' cannot be a link" && return 1

    local target_file="${1:-$(basename "$orig_file")}"; shift
    if [[ -d "$target_file" ]]; then
        target_file="$target_file/$(basename "$orig_file")"
    fi
    [[ -e "$target_file" ]] && eecho "ERROR: Usage: mv_and_ln orig target -- target '$target_file' already exists" && return 1

    echo -n "mv: "; wecho "mv -i -v \"$orig_file\" \"$target_file\""
    echo -n "ln: "; wecho "ln -sv \"$target_file\" \"$orig_file\""
    [[ -n "$SH_VERBOSE" ]] && ls -ohF  "$target_file" "$orig_file"
}

# Given a link $1, swap it with its target.
ln_swap() {
    local link_file="$1"; shift
    [[ -z "$link_file" ]] && >&2 eecho "ERROR: Usage: ln_swap link_file" && return 1
    [[ ! -e "$link_file" ]] && >&2 eecho "ERROR: File not found: $link_file" && return 1
    [[ ! -L "$link_file" ]] && >&2 eecho "ERROR: Not a symlink: $link_file" && return 1
    local target_file="$(readlink "$link_file")"
    [[ ! -e "$target_file" ]] &&  >&2 eecho "ERROR: Link's target not found: $target_file" && return 1

    echo -n "bak_link: " && wecho "bak \"$link_file\""
    echo -n "bak_file: " && wecho "bak \"$target_file\""
    echo -n "rm_link:  " && wecho "rm -v \"$link_file\""
    echo -n "mv_file:  " && wecho "mv -v \"$target_file\" \"$link_file\""
    echo -n "link:     " && wecho "ln -s \"$link_file\" \"${target_file}\""
    echo -n "touchln:  " && wecho "touchln \"${target_file}\""
    ls -ohF "${target_file}" "${link_file}"
}


# Echo whatever was piped in to stdout, so it can be assigned via $().
# Return 0 if there was something piped in; else 1.
from_stdin() {
    [[ ! -p /dev/stdin ]] && return 1
    read -r piped_in
    echo -n "${piped_in}"
}

# Inspect $1 and, using javascript-like truthy rules, return status 0 (true) or 1 (false).
# Usage: parse_bool [--echo] value
# If --echo is specified, 1 or nothing is echoed to stdout; else just the status is returned.
# Examples, in each case leaving some_var == 1 (if value is true) or empty (false).
# - parse_bool "true" && some_var=1
# - some_var=$(parse_bool --echo "true")
# Truthiness:
# - false: <unset>, "", "0", "false", "no", "null" or "undefined"
# - true:  any non-blank that doesn't evaluate to false is true
parse_bool() {
    [[ "$1" =~ -?-e(cho)? ]] && do_echo=1 && shift
    val="$1"; shift

    # ret=0: true; ret=1: false; but echo 1 for true, nothing for false. Nice.
    ret=0
    [[ -z "$val" || "$val" =~ ^(0|false|no|null|undefined)$ ]] && ret=1

    [[ -n "$do_echo" && $ret == 0 ]] && echo "1"
    return $ret
}

join_array() {
    local delim="$1" && shift
    local i_first=1
    [[ -n "$SH_DEBUG" ]] && echo_vars delim i_first "$@"
    for i in "$@"; do
        [[ -n "$SH_VERBOSE" ]] && eecho "i=$i"
        [[ -n "$i_first" ]] && printf "%s" "$i" && unset i_first || printf "%s%s" "$delim" "$i"
    done
    printf '\n'
}

uniq_array() {
    local i_first=1
    [[ -n "$SH_DEBUG" ]] && eecho_vars delim i_first "$@"
    local buff=
    for i in "$@"; do
        [[ -n "$SH_VERBOSE" ]] && eecho "i=$i"
        if (( i_first )); then
            buff="$i"
            unset i_first
        else
            buff="$(printf '%s\n%s' "$buff" "$i")"
        fi
    done
    echo "$buff" | sort -s | uniq
}

strip_prefix() {
    text="$1" && shift
    prefix="$1" && shift
    ([[ -z "$text" ]] || [[ -z "$prefix" ]]) && eecho "ERROR: Usage strip_prefix text prefix" && return 1
    echo "$text" | sed -E -e "s:^${prefix//\:\\:}::; s:^${prefix//\$/\\$}::;"
}

# Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
join_lines() {
    delim="${1:-, }"
    sed -E -n -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/p' | while read -r ln; do [[ -n "$not1st" ]] && printf "%s" "$delim" || not1st=1; printf "%s" "$ln"; done; printf '\n'
}

seconds_apart() {
    local before="$1" && shift
    local after="$1" && shift
    echo $(( $(date +%s -d "$after") - $(date +%s -d "$before") ))
}

# Scale memory numbers to TB/GB/MB/KB; $1 = bytes, $2 = places [1]
nice_byte_size() {
    local orig="$(from_stdin)"
    [[ -z "$orig" ]] && orig="$1" && shift
    local places="${1:-1}" && shift

    cleaned_orig="${orig//,/}"
    [[ -z "$cleaned_orig" ]] && return 1
    [[ ! $cleaned_orig =~ ^[[:digit:]]+$ ]] && echo "$orig" && return 0

    local nice="$cleaned_orig"
    if [[ $nice -ge $((1024*1024*1024*1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024*1024*1024*1024)")\ TB
    elif [[ $nice -ge $((1024*1024*1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024*1024*1024)")\ GB
    elif [[ $nice -ge $((1024*1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024*1024)")\ MB
    elif [[ $nice -ge $((1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024)")\ kb
    fi

    echo "$nice"
}

# Scale milliseconds to d/h/m/s; $1 = milliseconds, $2 = places [1]
nice_milliseconds() {
    local orig="$1"; shift
    local places="${1:-1}"; shift
    cleaned_orig="${orig//,/}"
    [[ -z "$cleaned_orig" ]] && return 1
    [[ ! $cleaned_orig =~ ^[[:digit:]]+$ ]] && echo "$orig" && return 0

    local nice=$cleaned_orig
    if [[ $nice -gt $((1000*60*60*24)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000*60*60*24)")d
    elif [[ $nice -gt $((1000*60*60)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000*60*60)")h
    elif [[ $nice -gt $((1000*60)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000*60)")m
    elif [[ $nice -gt $((1000)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000)")s
    fi

    echo "$nice"
}

# Insert commas into large numbers
commafy() {
    local orig="$1"; shift
    cleaned_orig="${orig//,/}"
    [[ -z "$cleaned_orig" ]] && return 1
    [[ ! $cleaned_orig =~ ^[[:digit:]]+.*$ ]] && eecho "$orig" && return 1

    local nice=$cleaned_orig
    for i in {1..10}; do
        [[ ! $nice =~ [[:digit:]]{4,} ]] && break
        nice=$(echo "$nice" | sed -E 's/([[:digit:]])([[:digit:]]{3})([^[:digit:]]|$)/\1,\2\3/g;')
    done

    echo "$nice"
}

# Expand '~' to $HOME, or compress $HOME to ~
tilde_expand()   { echo "${1//\~/$HOME}"; }
tilde_compress() { echo "${1//$HOME/\~}"; }

file_opened() {
    local file=$1
    [[ -z $file ]] && eecho "ERROR: file_opened: no file specified" && exit 1
    [[ ! -e $file ]] && echo "ERROR: file_opened: file not found: '$file'" && exit 1
    local dir=$(dirname "$file")
    local bname=$(basename "$file")
    decho "file=$file, dir=$dir, bname=$bname"
    nopen=$(sudo lsof +d "$dir" | grep -c "$bname")
    decho "nopen=$nopen"
    [[ -n "$nopen" && $nopen -gt 0 ]] && return 0 || return 1
}

# $1 is seconds since epoch; return 2017-12-21, or "null" if seconds is 0 or null
iso_date() {
    local s="${1:-0}"
    [[ "$s" = "0" ]] && echo "null" && return 0
    if is_macos; then
        date -r "$s" +'%Y-%m-%d' || return 1
    else
        date --date="@$s" +'%Y-%m-%d' || return 1
    fi
}
# $1 is seconds since epoch; return 16:45:00, or "null" if seconds is 0 or null
iso_time() {
    local s="$1"
    [[ "$s" = "0" ]] && echo "null" && return 0
    if is_macos; then
        date -r "$s" +'%H:%M:%S' || return 1
    else
        date --date="@$s" +'%H:%M:%S' || return 1
    fi
}


file_modified_seconds() {
    if is_macos; then
        stat -f '%m' "$@"
    else
        stat -c '%Y' "$@"
    fi
}

file_info() {
    local all_fields="user size bdate btime cdate ctime mdate mtime adate atime size name basename suffixed_name target"
    local usage="usage: file_info 'flag_1 flag_2 ... flag_n' FILE [...], where flags are 1+ of [$all_fields]"

    [[ -z "$1" ]] && eecho "file_info: $usage" && return 1
    # shellcheck disable=2206  # quote to avoid split
    local -a fields=( $1 ) && shift
    decho_vars all_fields fields

    local files=( "$@" )
    if [[ ${#files[*]} = 0 ]]; then
        decho "INFO: no file()s) specified; using .* *"
        files=( .* * )
    fi

    for file in "${files[@]}"; do
        [[ "$SH_VERBOSE" ]] && eecho -n "$file "
        [[ ! -e "$file" ]] && eecho "file_info: file not found: $file" && return 1

        if is_macos; then
            eval "$(stat -s "$file" || return 1)"  # put a dozen+ fields into env, all starting w 'st_'
        else
            eval "$(stat --format='st_uid=%u st_size=%s st_birthtime=%W st_ctime=%Z st_mtime=%Y st_atime=%X' "$file" || return 1)"
        fi

        local out=()
        for f in  ${fields[*]}; do
            case $f in
                user*)     out+=("$(id -nu "$st_uid" || return 1)")  ;;
                size*)     out+=("$(printf "%7d" "$st_size")")  ;;
                bdate*|birthdate*)    out+=("$(iso_date "$st_birthtime" || return 1)")  ;;
                btime*|birthtime*)    out+=("$(iso_time "$st_birthtime" || return 1)")  ;;
                cdate*)    out+=("$(iso_date "$st_ctime" || return 1)")  ;;
                ctime*)    out+=("$(iso_time "$st_ctime" || return 1)")  ;;
                mdate*)    out+=("$(iso_date "$st_mtime" || return 1)")  ;;
                mtime*)    out+=("$(iso_time "$st_mtime" || return 1)")  ;;
                adate*)    out+=("$(iso_date "$st_atime" || return 1)")  ;;
                atime*)    out+=("$(iso_time "$st_atime" || return 1)")  ;;
                name*)     out+=("$(CLICOLOR_FORCE=1 ls -1dA "$file")")  ;;
                basename*) out+=("$(basename "$file" || return 1)")  ;;
                suffixed_name*)
                out+=("$(CLICOLOR_FORCE=1 ls -1dAF "$file")")  ;;
                target*)
                if target="$(readlink "$file")"; then
                    out+=("-> $target")
                else
                    out+=(" ")
                fi
                ;;
                *)  eecho "file_info: invalid option '$f'; must specify 1+ of $all_fields"; return 1 ;;
            esac
            decho_vars out
        done
        echo "${out[@]}"
        # else
        #   local awk_p=
        #   local awk_a=
        #   for f in  ${fields[*]}  ; do
            #     awk_p="$awk_p %s"
            #     case $f in
            #       user*)     out+=("$(stat --format='%U' "$file" || return 1)")  ;;
            #       size*)     out+=("$(stat --format='%s' "$file" || return 1)")  ;;
            #       bdate*|birthdate*)    out+=("$(date -r "$(stat --format='%W' "$file" || return 1)" +'%Y-%m-%d' || return 1)")  ;;
            #       btime*|birthtime*)    out+=("$(date -r "$(stat --format='%W' "$file" || return 1)" +'%Y-%m-%d' || return 1)")  ;;
            #       cdate*)    out+=("$(date -r "$st_ctime" +'%Y-%m-%d' || return 1)")  ;;
            #       ctime*)    out+=("$(date -r "$st_ctime" +'%H:%M:%S' || return 1)")  ;;
            #       mdate*)    out+=("$(date -r "$st_mtime" +'%Y-%m-%d' || return 1)")  ;;
            #       mtime*)    out+=("$(date -r "$st_mtime" +'%H:%M:%S' || return 1)")  ;;
            #       adate*)    out+=("$(date -r "$st_atime" +'%Y-%m-%d' || return 1)")  ;;
            #       atime*)    out+=("$(date -r "$st_atime" +'%H:%M:%S' || return 1)")  ;;
            #       name*)     out+=("$file")  ;;
            #       basename*) out+=("$(basename "$file" || return 1)")  ;;
            #       *)  eecho "file_info: invalid option '$f'; must specify 1+ of $all_fields"; return 1 ;;
            #       # user*)     awk_a="$awk_a, \$3"  ;;
            #       # size*)     awk_a="$awk_a, \$4"  ;;
            #       # mdate*)    awk_a="$awk_a, \$5"  ;;
            #       # mtime*)    awk_a="$awk_a, \$6"  ;;
            #       # name*)     awk_a="$awk_a, \$7"  ;;
            #       # basename*) awk_a="$awk_a, bname"  ;;
            #       *)  eecho "file_info: invalid option $f; must specify 1+ of $all_fields"; return 1
            #     esac
            #     decho_vars awk_p awk_a
            #   done
            #   # ls -oh --time-style=+"%Y-%m-%d %H:%M:%S" $file | awk "{fc=split(\$7,fn,/\//); bname=fn[fc];  printf \"${awk_p:1}\", ${awk_a:2}}"
            #   ls -oh --time-style=long-iso "'$file'" | awk "{fc=split(\$7,fn,/\//); bname=fn[fc];  printf \"${awk_p:1}\", ${awk_a:2}}"
            # fi

    done
}


# Reverse lookup environment variable, using complete value.
# $1 - value to match
# $2 - optional pattern to exclude
vne() {
    local value="$1"; shift
    local exclude="$1"

    #env | awk -F'=' -v v="$value" 'BEGIN {s=1}  $0 ~ ".*=" v "$" {print $1; s=0; exit}  END {exit s}'
    local c="env | grep -E '=${value}\$' | awk -F'=' ' {print \$1;}'"
    [[ -n "$exclude" ]] && c="$c | grep -E -v '$exclude'"
    #decho "$c"

    local var=$(eval "$c")
    [[ -n "$var" ]] && echo "$var"
}

# Using pwd (or $1 if specified), replace the longest string possible with an environemnt variable.
pwd_vne() {
    local dir="${1:-$PWD}"
    local prefix="${1:-$dir}"
    local suffix=""
    #eecho_vars --quote prefix suffix
    while [[ "$prefix" =~ [^/]+/[^/]+ ]]; do
        local v="$(vne "$prefix" 'PWD|HOME')"
        #eecho_vars --quote v
        if [[ -n "$v" ]]; then
            echo "${v}${suffix}"
            return 0
        fi
        suffix="/${prefix##*/}${suffix}"
        prefix="${prefix%/*}"
        #eecho_vars --quote prefix suffix
    done
    echo "$dir"
    return 1
}

# $1 is LONG (default prompt) or SHORT (sub env var if possible)
# From .profile (color):
#   PROMPT_COMMAND='[[ $? = 0 ]] && _prompt_symbol="\$" || _prompt_symbol="$term_red!\$"'
#   export PS1='\h:\u:\w $_prompt_symbol$term_reset '
ps1() {
    if [[ -z "$PS1_ORIGINAL" ]]; then
        # original -> short
        export PS1_ORIGINAL="$PS1"
        export PROMPT_COMMAND_ORIGINAL="$PROMPT_COMMAND"
        export PS1="${PS1_ORIGINAL/\\w/\$_prompt_working_dir}"
        export PROMPT_COMMAND="$PROMPT_COMMAND_ORIGINAL; _prompt_working_dir=\"\\\$\$(pwd_vne)\""
    else
        # short -> original
        export PS1="$PS1_ORIGINAL"
        export PROMPT_COMMAND="$PROMPT_COMMAND_ORIGINAL"
        unset PS1_ORIGINAL PROMPT_COMMAND_ORIGINAL
    fi
    vecho_vars PS1 PROMPT_COMMAND PS1_ORIGINAL PROMPT_COMMAND_ORIGINAL
}

# Add a .BAK.YYYYMMDD suffix, using the file's modification date.
# If file is a folder, first update its modification date, then copy/move it.
# Optional $1 can be -m to move the file rather than copy it.
# Ignore any files already backed up with this scheme.
bak() {
    local verb="cp -P -pvR"; [[ "${1:0:2}" = "-m" ]] && verb="mv -v"
    [[ "${1:0:1}" = "-" ]] && shift
    [[ -z "$1" ]] && eecho "usage: bak [-m] file [...]" && return 1

    for f in "$@"; do
        [[ ! -e "$f" ]] && eecho "bak: $f: No such file or directory" && return 1
        [[ "$f" =~ .+\.BAK.[[:digit:]]{8} ]] && eecho "bak: $f: Ignoring .BAK.* file" && return 1
        [[ -d "$f" ]] && touchdir_R "$f"
        local tstamp=$(file_info 'mdate' "$f")
        [[ -z "$tstamp" ]] && eecho "bak: $f: Cannot determine mdate" && return 1
        tstamp="${tstamp//-/}"  #yyymmdd
        vecho_and_eval "$verb \"$f\" \"${f}.BAK.${tstamp}\""
    done
}

# Rename a *.BAK.YYYYMMDD suffix file to the original name; if target exists, first 'bak' it.
unbak() {
    for f in "$@"; do
        [[ -z "$f" ]] && eecho "ERROR: Usage: unbak file" && return 1
        [[ ! -f "$f" ]] && eecho "ERROR: File not found: $f" && return 1
        [[ ! "$f" =~ .+\.BAK\.[0-9]{8} ]] && eecho "ERROR: File not in *.BAK.yyyymmdd format: $f" && return 1
        local orig_name="${f:0:-13}"
        [[ -f "$orig_name" ]] && bak -m "$orig_name"
        wecho mv -v "$f" "$orig_name"
    done
}


# Convenience version of [[ -e "file*" ]] since test won't take wildcards/globs.
glob_exists() {
    [[ -z "$1" ]] && return 1
    ls "$@" >& /dev/null
}

# Print the machine's physical memory size; units specified as $1:
#  -bytes, -kilobytes (default), -megabytes, -gigabytes
memsize() {
    local units="${1/-/}"; shift
    [[ -z "$units" ]] && units="k"

    local kb
    if is_macos; then
      kb=$(( $(sysctl hw.memsize | cut -d' ' -f2) / 1024 ))
    else
      kb=$( awk -e '/MemTotal/ {print $2}' /proc/meminfo)
    fi

    case "$units" in
        b*)  echo "$(( kb * 1024))" ;;
        k*)  echo "$kb" ;;
        m*)  echo "$(( kb / 1024))" ;;
        g*)  echo "$(( kb / (1024 * 1024) ))" ;;
        *)   >&2 echo "memsize: invalid units: $units"; return 1 ;;
    esac
    return 0
}

# Write a script, "mk_links.sh", to re-create each soft link in the given folder.
# Useful to create links on a separate server.
# Optional $1 can be -f or --force to overwrite existing mk_links.sh
# Optional $2 is root folder
links_to_sh() {
    [[ "$1" =~ ^-?-f(orce)?$ ]] && local opt_force=1 && shift
    local d="${1:-$PWD}"

    local sh_file="$d/mk_links.sh"
    [[ -z "$opt_force" && -f "$sh_file" ]] && eecho "ERROR: $sh_file alrady exists." && return 1

    echo '#!/usr/bin/env bash' > "$sh_file"
    # shellcheck disable=SC2016  # $ inside ''
    echo 'opt_force="$1"  # "f" to add to ln -s command' >> "$sh_file"

    local dir_count=0
    for dir in $(find "$d" -type d | sort); do
        (( dir_count++ ))
        if [[ "$(dirname "$dir")" != "$prev_dirname" ]]; then
            prev_dirname="$(dirname "$dir")"
            echo "" >> "$sh_file"
            echo "cd $prev_dirname" >> "$sh_file"
        fi
        decho_vars count dir
        echo "mkdir -pv $(basename "$dir")" >> "$sh_file"
    done

    local link_count=0
    for link in $(find "$d" -type l | sort); do
        (( link_count++ ))
        if [[ "$(dirname "$link")" != "$prev_dirname" ]]; then
            prev_dirname="$(dirname "$link")"
            echo "" >> "$sh_file"
            echo "cd ${prev_dirname/$HOME/\~}" >> "$sh_file"
        fi
        local real_file="$(readlink "$link")"
        local real_file_compressed="${real_file/$HOME/\~}"
        decho_vars count link real_file real_file_compressed
        if [[ "$(basename "$link")" = "$(basename "$real_file")" ]]; then
            echo "ln -sv\${opt_force} $real_file_compressed" >> "$sh_file"
        else
            echo "ln -sv\${opt_force} $real_file_compressed $(basename "$link")" >> "$sh_file"
        fi
    done

    (( link_count = 0 )) && eecho "No links." && return 1

    chx "$sh_file"
    echo ""
    ll "$sh_file"
    [[ -z "$SH_QUIET" ]] && cat "$sh_file"
}


# Optional version prefix can be used to limit to, e.g., 5.* or 3.4.*
find_alfresco_home() {
    local version_prefix="${1:-[[:digit:]]\\.[[:digit:]]}"; shift
    [[ -d "$ALFRESCO_HOME" ]] && cd "$ALFRESCO_HOME" && return 0
    local root="${ALFRESCO_ROOT:-/opt/alfresco}"
    [[ ! -d "$root" ]] && eecho "find_alfresco_home: cannot determine ALFRESCO_ROOT" && return 1
    local c="command find -E -s '$root' -maxdepth 1 -regex '.+/alfresco(-enterprise)?(-sdk)?-${version_prefix}.*' -print -quit"
    local home="$(eval "$c")"
    [[ -z "$home" ]] && evecho "find_alfresco_home: cannot determine ALFRESCO_HOME" && return 1
    echo "$home"
}


# svn info returns, e.g., Working Copy Root Path: /Users/tpierzina/svn/ucp/ucp-alfresco-liferay/ucp-olc-2017
branch_name() {
    local dir="${1:-.}"
    local root_path=$(svn info "$dir" 2> /dev/null | grep "Working Copy Root Path:")
    [[ -z "$root_path" ]] && vecho "ERROR: Cannot determine working copy root path" && return 1
    echo "${root_path##*/}"  # after last /
}


# Apply a CSS selector to the results of the given URL or file.
# Requires html-xml-utils; macOS: brew install html-xml-utils
cssgrep() {
    local FN_USAGE="usage: cssgrep url 'selector' [--inner | --outer]"

    if (! which hxnormalize >& /dev/null); then
        eecho "cssgrep: html-xml-utils must be installed; try 'brew install html-xml-utils'"
        return 1
    fi

    local in="$1"; shift
    [[ -z "$in" ]] && eecho "$FN_USAGE" && return 1
    local selector="$1"; shift
    [[ -z "$selector" ]] && eecho "$FN_USAGE" && return 1
    local inner_opt=""
    [[ "$1" =~ -i ]] && inner_opt="-c"  #content only

    # hxnormalize:
    # -x xml conventions, empty elements are written with /> at the end
    # -l 240 max line length, allow for length strings without breaking
    #
    # hxselect:
    # -c content only ("innerHtml")
    # -s separator between matches
    hxnormalize -x -l 240 "$in" | hxselect $inner_opt -s '\n' "$selector"
}


# Backup all MacOS keyboard shortcuts by creating a shell script to restore them and saving to Dropbox.
# From https://superuser.com/questions/670584/how-can-i-migrate-all-keyboard-shortcuts-from-one-mac-to-another
save_hotkeys() {
    DESTFILE="$HOME/Dropbox/backup/install-hotkeys-$(date +'%Y%m%d').sh"
    echo '#!/usr/bin/env bash' > "$DESTFILE"

    defaults find NSUserKeyEquivalents | \
    sed \
    -e "s/Found [0-9]* keys in domain '\\([^']*\\)':/defaults write \\1 NSUserKeyEquivalents '/" \
    -e "s/    NSUserKeyEquivalents =     {//" \
    -e "s/};//" -e "s/}/}'/" >> "$DESTFILE"

    echo killall cfprefsd >> "$DESTFILE"
    chmod a+x "$DESTFILE"

    echo "Wrote $(grep -E -c '=.+;$' "$DESTFILE") key mappings to: $DESTFILE"
}
