#!/usr/bin/env bash

# Only source (.) this file; it loads functions but does not do anything.

bkup-gmail-filters() {
  bkup "$HOME/prefs/gmail-filters" "$HOME/bak/bak.gmail-filters"
}

bkup-iterm() {
  bkup "$HOME/prefs/iterm" "$HOME/bak/bak.iterm" -i '*.plist'
}

bkup-notes() {
  bkup "$HOME/notes/notes-main" "$HOME/bak/bak.notes"
}


# Usage: bkup [-q] from_dir to_dir [--include or --exclude lists]
bkup() {
  local _QUIET=$_VERBOSE && [[ "$1" =~ ^(-q|--quiet)$ ]] && _QUIET=1 && shift
  local sw_verbose='' && ((!_QUIET)) && sw_verbose='v'

  local from_dir="$1" && shift
  local to_dir="$1" && shift
  local opt_zip="$*"

  [[ -z "$from_dir" ]] && >&2 echo "usage: bkup from_dir to_dir" && return 1
  [[ ! -d "$from_dir" ]] && >&2 echo "bkup: from_dir does not exist" && return 1

  local from_dirname="$(basename "$from_dir")"
  local today_formatted="$(date +'%Y%m%m')"
  local bak_file="${to_dir}/${from_dirname}.BAK.$today_formatted.zip"

  mkdir -p$sw_verbose "$to_dir" | tilde-compress
  rm -f$sw_verbose "$bak_file" | tilde-compress

  # zip options:
  #   --quiet
  #   --recurse-paths
  #   --latest-time     set timestamp on archive to match newest file inside
  #   -9                maximum compression
  #   -x                exclude-files
  pushd "$from_dir" >/dev/null
  zip --quiet --recurse-paths --latest-time -9 \
    "$bak_file" . \
    -x .DS_Store *.sublime-workspace $opt_zip
  popd >/dev/null

  if type -t lln >&/dev/null; then
    ((!_QUIET)) && lln "$bak_file"
  else
    ((!_QUIET)) && ls -ohF "$bak_file"
  fi

  printf "\n"
  unzip -l "$bak_file" | head -n $((LINES/2)) | tilde-compress
}


# Print the given filename's root, not including the extension or its period.
# If file has no period in it in its basename, print full filename.
filename-root() {
  local in_file="$1" && shift
  [[ -z "$in_file" ]] && >&2 echo "usage: filename-root filename" && return 1

  # Ensure name includes text after the last slash (if any)
  [[ ! "$in_file" =~ /?[^/]*[^/]+$ ]] && echo "$in_file" && return 0

  # Return everything before the last dot
  echo "${in_file%.*}"
}

# Print the given filename's extension only, including the leading period.
# If file has no period in it in its basename, print ''.
filename-extension() {
  local in_file="$1" && shift
  [[ -z "$in_file" ]] && >&2 echo "usage: filename-ext: filename" && return 1

  # Ensure the basename includes a period; else ''
  [[ ! "$in_file" =~ \. ]] && return 0

  # Return everything after and including the last period
  echo ".${in_file##*.}"
}

# Convert the given filename into its "BAK" version.
filename-bak() {
  local in_file="$1" && shift
  [[ -z "$in_file" ]] && >&2 echo "usage: filename-bak filename" && return 1

  local today_formatted="$(date +'%Y%m%m')"
  local bak_date="BAK.$today_formatted"
  local root="$(filename-root "$in_file")"
  local ext="$(filename-extension "$in_file")"
  echo "${root}.BAK.${today_formatted}${ext}"
}

# Create a dated BAK copy of given file(s).
# Skip and filenames already in the BAK format.
# cp options:
#   -i  prompt if target bak file, if it exists [used by default]
#   -n  fail if target bak file exists
#   -p  preserve attributes like modify time, permissions, etc.
#   -R  recursively copy directory
bak() {
  [[ -z "$1" ]] && >&2 echo "usage: bak [cp options ...] filename [...]" && return 1

  local cp_options='-i'
  ((_VERBOSE)) && cp_options="$cp_options -v"
  for arg in $@; do
    if [[ "$arg" =~ ^- ]]; then
      cp_options="$cp_options $arg"
    else
      local f="$arg"
      [[ "$f" =~ .+\.BAK\.[0-9]{8} ]] && eecho "bak: skipping BAK file: $f" && continue
      local f_bak="$(filename-bak "$arg")"
      cp -p $cp_options "$f" "$f_bak" || return $?
    fi
  done
}
