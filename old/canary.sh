#!/usr/bin/env bash
. "$HOME/.functions"

# This is a valiant attempt to run Canary and have it play nice with other apps, especially Alfred.
# Ultimately, I gave up.

function canary() {
  local CANARY_LOG="/var/tmp/canary.log"

  echo "$(date): $0 args: ${*:-<none>}" | tee -a "$CANARY_LOG"

  local exe_dir="/Applications/Google Chrome Canary.app/Contents/MacOS"
  local exe_file="$exe_dir/Google Chrome Canary"

  if [[ "$1" = "--install" ]]; then
    shift
    . "$HOME/.alias"

    if [[ ! -e "${exe_file}-bin" ]]; then
      bak "$exe_file"
      mv -v "$exe_file" "${exe_file}-bin"
    fi

    cp -pv "$0" "$exe_file"
    chmod -v +x "$exe_file"
    ls -ohF "$exe_dir"

  else

    echo "$(date): Started Canary for URL(s): ${*:-<none>}" | tee -a "$CANARY_LOG"
    exec "${exe_file}-bin" "--args" "--disable-gpu" $@

  fi
}
canary $@
