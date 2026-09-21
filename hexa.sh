#!/usr/bin/env bash

# Look up the color description for an RGB hex string.
# $1 - [required] #rgb, rgb, #rrggbb, rrggbb
# $2 - if "alfred", wrap results in its script filter json
#
# # Call out to /opt/bin/ntc.sh to look up the CSS color name and include it unless it es
# # an exact match to the hexa string.

function hexa() {

  [[ -z "$1" ]] && eecho "Usage: hexa #rgb|#rrggbb [alfred]" && return 1

  local rgb_as_input="$1"; shift
  local rgb="$rgb_as_input"
  local out_format="$1"; shift
  vecho "... rgb='$rgb', out_format='$out_format'"

  # Strip optional leading #
  [[ "$rgb" =~ ^#.+ ]] && rgb="${rgb:1}"

  # Must be length 3 or 6
  (( ${#rgb} != 3 && ${#rgb} != 6 )) && eecho "hexa: #rgb must be exactly 3 or 6 hex digits" && return 1

  # If in RGB form, expand to RRGGBB
  if [[ ${#rgb} == 3 ]]; then
    local rgb_new=""
    for c in $(fold -w1 <<< "$rgb"); do
      rgb_new="$rgb_new$c$c"
    done
    rgb="$rgb_new"
  fi
  vecho "... rgb='$rgb'"

  # On a Mac: brew install html-xml-utils
  # -x xml conventions, empty elements are written with /> at the end
  # -l 240 max line length, allow for length strings without breaking
  # -c content only ("innerHtml")
  # -s separator between matches

  # Depending on context in which this is run, the html-xml tools may not be on the PATH.
  which hxnormalize &> /dev/null || path-append "/usr/local/bin"
  if ! which hxnormalize &> /dev/null; then eecho "hexa: html-xml-utils must be installed vi Homebrew"; return 1; fi

  local out_desc="$(hxnormalize -x -l 240 "https://www.colorhexa.com/$rgb" <<< "$out_desc" |\
    hxselect -c -s ' ' '#information > div.color-description > p > strong'
  )"
  local out_desc_trimmed="$( echo $out_desc |\
    tr '[:upper:]' '[:lower:]' |\
    sed 's/light /lt /g; s/dark /dk /g; s/very /v /g;'
  )"
  vecho "... out_desc='$out_desc', out_desc_trimmed='$out_desc_trimmed'"

  # I think ntc is a custom tool to look up the official CSS name; but I've lost it.
  # local ntc="$(/opt/bin/ntc.sh $rgb)"
  # [[ "$out_desc" != "$ntc" ]] && out_desc_trimmed="css: $ntc; $out_desc_trimmed"

  # If not using Alfred output format, just return the color description
  if [[ ! "$out_format" =~ ^[aA]lfred$ ]]; then
    echo "$out_desc_trimmed"
    return 0
  fi

  # For Alfred, look up nearest web-safe color and wrap everything in JSON
  local out_websafe="$(hxnormalize -x -l 240 "https://www.colorhexa.com/$rgb" |\
    hxselect -c -s ' ' '#conversion > div > table.table-conversion.left > tbody > tr:nth-child(7) > td.code > code' |\
    sed -e 's/^[[:space:]]*//;' |\
    sed -e 's/[[:space:]]*$//;' \
  )"
  vecho "... out_websafe='$out_websafe'"

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
  vecho "... subtitle='$subtitle'"

cat << EOB
  {
    "variables": {
      "rgb_as_input": "$rgb_as_input",
      "rgb": "$rgb",
      "out_desc": "$out_desc_trimmed",
      "out_websafe": "$out_websafe",
      "subtitle": "$subtitle",
      "websafe_desc": "$websafe_desc"
    },
    "items": [{
        "title": "$out_desc",
        "subtitle": "$subtitle",
        "arg": "$out_desc_trimmed"
    }]
  }
EOB

}
hexa $@
