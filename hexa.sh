#!/usr/bin/env bash

# Look up the color description for an RGB hex string.
# $1 - [required] #rgb, rgb, #rrggbb, rrggbb
# $2 - if "alfred", wrap results in its script filter json
#
# # Call out to /opt/bin/ntc.sh to look up the CSS color name and include it unless it es
# # an exact match to the hexa string.

function hexa() {

  local rgb_input="$1"; shift
  local out_format="$1"; shift
  #>&2 echo "rgb='$rgb', out_format='$out_format'"

  [[ -z "$rgb_input" ]] && return 1
  local rgb="${rgb_input}"

  # Strip optional leading #
  [[ "$rgb" =~ ^#.+ ]] && rgb="${rgb:1}"

  # Must be length 3 or 6
  (( ${#rgb} != 3 && ${#rgb} != 6 )) && return 1

  # If in RGB form, expand to RRGGBB
  if [[ ${#rgb} == 3 ]]; then
    local rgb_new=""
    for c in $(fold -w1 <<< "$rgb"); do
      rgb_new="$rgb_new$c$c"
    done
    rgb="$rgb_new"
  fi
  #>&2 echo "rgb='$rgb'"

  # Depending on context in which this is run, the html-xml tools may not be on the PATH.
  which hxnormalize &> /dev/null || export PATH="$PATH:/usr/local/bin"


  # On a Mac: brew install html-xml-utils
  # -x xml conventions, empty elements are written with /> at the end
  # -l 240 max line length, allow for length strings without breaking
  # -c content only ("innerHtml")
  # -s separator between matches

  local out_desc="$(hxnormalize -x -l 240 "https://www.colorhexa.com/$rgb" |\
    hxselect -c -s ' ' '#information > div.color-description > p > strong' |\
    tr '[:upper:]' '[:lower:]' |\
    sed -e 's/^[[:space:]]*//;' |\
    sed -e 's/[[:space:]]*$//;' |\
    sed 's/light /lt /g; s/dark /dk /g; s/very /v /g;' \
  )"

  # local ntc="$(/opt/bin/ntc.sh "$rgb")"
  # [[ "$out_desc" != "$ntc" ]] && out_desc="css: $ntc; $out_desc"

  # If not using Alfred output format, just return the color description
  if [[ ! "$out_format" =~ ^[aA] ]]; then
    echo "$out_desc"
    return 1
  fi

  # For Alfred, look up nearest web-safe color and wrap everything in JSON
  local out_websafe="$(hxnormalize -x -l 240 "https://www.colorhexa.com/$rgb" |\
    hxselect -c -s ' ' '#conversion > div > table.table-conversion.left > tbody > tr:nth-child(7) > td.code > code' |\
    sed -e 's/^[[:space:]]*//;' |\
    sed -e 's/[[:space:]]*$//;' \
  )"
  #>&2 echo "out_desc='$out_desc', out_websafe='$out_websafe'"

  # If web-safe RGB is not our intiial color, lookup that color's name and if it differs
  # from the original name, add it to the subtitle.
  local subtitle
  if [[ "$out_websafe" == "#$rgb" ]]; then
    subtitle="#$rgb is web-safe"
  else
    local websafe_desc="$(hexa $out_websafe)"
    #>&2 echo "websafe_desc=$websafe_desc"
    if [[ "$websafe_desc" == "$out_desc" ]]; then
      subtitle="Closest web-safe: $out_websafe"
    else
      subtitle="Closest web-safe: $out_websafe, $websafe_desc"
    fi
  fi

cat << EOB
  {
    "variables": {
      "rgb_input": "$rgb_input",
      "rgb": "$rgb",
      "out_desc": "$out_desc",
      "out_websafe": "$out_websafe",
      "subtitle": "$subtitle",
      "websafe_desc": "$websafe_desc"
    },
    "items": [{
        "title": "$out_desc",
        "subtitle": "$subtitle",
        "arg": "$out_desc"
    }]
  }
EOB

}
hexa "$@"
