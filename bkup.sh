#!/usr/bin/env bash

# Source only; execute functions after loading file.

bkup-gmail-filters() {
  bkup "$HOME/ttpp/gmail-filters" "$HOME/bak/bak.gmail-filters"
}

bkup-iterm() {
  bkup "$HOME/prefs/iterm" "$HOME/bak/bak.iterm" -i '*.plist'
}

bkup-notes() {
  bkup "$HOME/notes/notes-main" "$HOME/bak/bak.notes"
}


# Usage: bkup from_dir to_dir [--include or --exclude lists]
bkup() {
  local from_dir="$1" && shift
  local to_dir="$1" && shift
  local opt_zip="$*"

  [[ -z "$from_dir" ]] && >&2 echo "usage: bkup from_dir to_dir" && return 1
  [[ ! -d "$from_dir" ]] && >&2 echo "bkup: from_dir does not exist" && return 1

  local from_dirname="$(basename "$from_dir")"
  local bak_file="${to_dir}/${from_dirname}.BAK.$(today-formatted).zip"

  mkdir -pv "$to_dir"
  rm -fv "$bak_file"

  # zip options:
  #   --quiet
  #   --recurse-paths
  #   --latest-time     set timestamp on archive to match newest file inside
  #   -9                maximum compression
  #   -x                exclude-files
  pushd "$from_dir" >/dev/null
  zip --quiet --recurse-paths --latest-time -9 \
    "$bak_file" . \
    -x .DS_Store $opt_zip
  popd >/dev/null

  ls -ohF "$bak_file"
  unzip -l "$bak_file" | head
}

# Print today's date in any format, defaulting to YYYYMMDD.
today-formatted() {
  local opt_format="${1:-%Y%m%d}" && shift
  date +"$opt_format"
}


# # Print the given filename's basename root, not including the extension or its period.
# # If file has no period in it in its basename, print full filename.
# filename-root() {
#   local in_file="$1" && shift
#   [[ -z "$in_file" ]] && >&2 echo "usage: filename-root: filename" && return 1

#   # Ensure name includes text after the last slash (if any), then after the last dot
#   [[ ! "$in_file" =~ /?[^/]*\.[^/.]+$ ]] && echo "$in_file" && return 0

#   # Return everything before the last dot
#   echo "${in_file%.*}"
# }

# # Print the given filename's extension only, excluding the leading period.
# # If file has no period in it in its basename, print ''.
# filename-ext() {
#   local in_file="$1" && shift
#   [[ -z "$in_file" ]] && >&2 echo "usage: filename-ext: filename" && return 1

#   # Ensure name includes text after the last slash (if any), then after the last dot
#   [[ ! "$in_file" =~ /?[^/]*\.[^/.]+$ ]] && return 0

#   # Return everything after the last dot
#   echo "${in_file##*.}"
# }

# # Convert the given filename into its "BAK" version.
# bak-filename() {
#   local in_file="$1" && shift
#   [[ -z "$in_file" ]] && >&2 echo "usage: bak-filename: filename" && return 1

#   local bak_date="BAK.$(today-formatted)"
#   local root="$(filename-root "$in_file")"
#   local ext="$(filename-ext "$in_file")"
#   echo "${root}.${bak_date}.${ext}"
# }
