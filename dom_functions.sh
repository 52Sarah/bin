#!/usr/bin/env bash
. "$HOME/.functions"

# SCRIPT_DIR="$(cd "$(dirname "$0")" || return 1; pwd)"
# SCRIPT_NAME="$(basename "$0")"


tokenize_html() {
  local FN_NAME="tokenize_html"
  local USAGE="usage: $FN_NAME in_file [...]"

  local in_file="$1"; shift
  [[ -z "$in_file" ]] && eecho "$USAGE" && return 1
  [[ -e "$in_file" ]] || eecho "$FN_NAME: $in_file: No such file"

  # for some reason, in sed \1 is not working for the closing quote
  # 1. put each id= and class= onto its own line so sed gets all of them
  # 2. extract id and class names and rewrite with # and . prefixes
  # 3. split multiple classes
  # shellcheck disable=SC1004  # linefeed literal
  sed -E -n \
    -e 's/ (id|class)=/\
 \1=/g p;' \
    "$in_file" \
  | \
  sed -E -n \
    -e 's/^.* id=["$'\'']([^[:space:]]+)["$'\''].*$/#\1/g p;'  \
    -e 's/^.* class=["$'\'']([^"$'\'']+)["$'\''].*$/.\1/ p;' \
  | \
  sed -E -n \
    -e 's/^(\.[^[:space:]\.]+)([[:space:]]+|\.)(.+)$/\1\
.\3/; p;' \
  | \
  sort | \
  uniq | \
  tee "${in_file}.TOKENS.txt"

}

tokenize_css() {
  local FN_NAME="tokenize_css"
  local USAGE="usage: $FN_NAME in_file [...]"

  local in_file="$1"; shift
  [[ -z "$in_file" ]] && eecho "$USAGE" && return 1
  [[ -e "$in_file" ]] || eecho "$FN_NAME: $in_file: No such file"

  # for some reason, in sed \1 is not working for the closing quote
  # 1. put each id= and class= onto its own line so sed gets all of them
  # 2. extract id and class names and rewrite with # and . prefixes
  # 3. split multiple classes
  # shellcheck disable=SC1004  # linefeed literal
  sed -E -n \
    -e 's/^.* id=["$'\'']([^[:space:]]+)["$'\''].*$/#\1/g p;'  \
    -e 's/^.* class=["$'\'']([^"$'\'']+)["$'\''].*$/.\1/ p;' \
  | \
  sed -E -n \
    -e 's/^(\.[^[:space:]\.]+)([[:space:]]+|\.)(.+)$/\1\
.\3/; p;' \
  | \
  sort | \
  uniq | \
  tee "${in_file}.TOKENS.txt"

}
