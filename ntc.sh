#!/usr/bin/env bash

# Use chir.ag's Name That Color library (ntc.js) to find the closest css color name
# for the RGB hex string in $1
#   $1 - [required] #rgb, rgb, #rrggbb, rrggbb

function ntc() {

  local rgb="${1,,}"; shift
  [[ -z "$rgb" ]] && return 1

  IFS=$'\t' read -r n_rgb n_name n_exactmatch <<< "$(node -e "
    var ntc = require('$(dirname "$0")/ntc.js');
    var n_match = ntc.name('$rgb');
    var n_rgb = n_match[0];
    var n_name = n_match[1];
    var n_exactmatch = n_match[2];
    console.log(n_rgb + '\\t' + n_name + '\\t' + n_exactmatch);
  ")"

  #echo "1 $n_rgb   2 $n_name   3 $n_exactmatch"

  local out_desc="$n_name"
  [[ "$n_exactmatch" != "true" ]] && out_desc="~$out_desc"

  echo "${out_desc,,}"
}
ntc "$@"
