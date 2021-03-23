#!/usr/bin/env bash

# Source only; execute functions after loading file.

bkup-iterm() {
  local FROM_DIR="$HOME/prefs/iterm"
  local TO_DIR="$HOME/bak/bak.iterm"
  local bak_file="${TO_DIR}/iterm_prefs.BAK.$(today-formatted).zip"

  rm -f "$bak_file"

  # zip options:
  #   --latest-time   set timestamp on archive to match newest file inside
  #   --quiet         minimal output
  #   -J              omit (junk) folders
  #   -9              maximum compression
  zip --latest-time --quiet -J -9 \
    "$bak_file" "$FROM_DIR"/*.plist

  ls -ohF "$bak_file"
}

bkup-notes() {
  local FROM_DIR="$HOME/notes/notes-main"
  local TO_DIR="$HOME/bak/bak.notes"
  local bak_file="${TO_DIR}/notes-main.BAK.$(today-formatted).zip"

  rm -f "$bak_file"

  # zip options:
  #   --latest-time   set timestamp on archive to match newest file inside
  #   --quiet         minimal output
  #   -r              recurse
  #   -x              exclude file(s)
  #   -9              maximum compression
  pushd "$FROM_DIR"
  zip --latest-time --quiet -r -9 \
    "$bak_file" . \
    -x .DS_Store
  popd

  ls -ohF "$bak_file"
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
