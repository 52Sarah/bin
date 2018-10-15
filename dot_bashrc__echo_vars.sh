#!/usr/bin/env bash

. $HOME/.__login.debug ".bashrc__echo_vars" || __echo() { :; }
__echo "[.bashrc__echo_vars] starting"


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
        ## decho "var: $var, _typeof: $var_typeof, _array: $var_array, _length: $var_array_length, _value: $var_array_length_value"

        local var_array_value="$(eval "echo $var_array")"
        [[ -n "$ECHO_VARS_SUB_HOME" ]] && var_array_value="${var_array_value/$HOME/\~}"
        local var_array_keys="$(eval "echo \$\\{!${var}[@]\\}")"
        local var_array_keys_value="$(eval "echo $var_array_keys")"
        ## decho "var: $var, _array_value: $var_array_value, _array_keys: $var_array_keys, _value: $var_array_keys_value"

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
            ## decho "scalar: var = $var, var_array_keys_value = '$var_array_keys_value'"
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
            ## decho "echo_vars: val_cmd: '$val_cmd'"

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


__echo "[.bashrc__echo_vars] finished"
