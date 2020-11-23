#!/usr/bin/env bash

# see https://www.scootersoftware.com/support.php?zz=kb_vcs_osx#cornerstone

# For example, comparing against last update (BASE), Cornerstone 3.1 sends in the following:
# bcdiff_cornerstone.sh
# $1 = /Users/tpierzina/Library/Containers/com.zennaware.cornerstone3/Data/Library/Caches/Cornerstone/Store/http%3A%2F%2Ftpierzina%40svn.tsgrp.com%2Frepos%2FAlfrescoModules/0000009749/branches/ucp/branches/ucp-olc-2017/liferay/build-common-plugin.xml
# $2 = build-common-plugin.xml
# $3 = -
# $4 = Last
# $5 = Update
# $6 = (BASE)
# $7 = -
# $8 = 9,749
# $9 = /Users/tpierzina/svn/ucp/ucp-alfresco-liferay/ucp-olc-2017/liferay/build-common-plugin.xml
# $10 = build-common-plugin.xml
# $11 = -
# $12 = Working
# $13 = Version
# $14 = -
# $15 = 9,749+

echo_params() {
  basename "$0"
  while [[ -n "$1" ]]; do
    echo " \$$((++argv_idx)) = $1"
    shift 1
  done
  echo "-------------------------------------------------------------------"
}

exec_bcomp() {

  local file1="$1"; shift 1
  local base1="$1"; shift 1
  shift 1
  local label1=""
  while [[ -n "$1" && "$1" != "-" ]]; do
    [[ -n "$label1" ]] && label1="$label1 $1" || label1="$1"
    shift 1
  done
  shift 1
  local rev1="$1"; shift 1

  local file2="$1"; shift 1
  local base2="$1"; shift 1
  shift 1
  local label2=""
  while [[ -n "$1" && "$1" != "-" ]]; do
    [[ -n "$label2" ]] && label2="$label2 $1" || label2="$1"
    shift 1
  done
  shift 1
  local rev2="$1"; shift 1

  echo "left:"
  echo " - file1 = ${file1/$HOME/\~}"
  echo " - base1 = $base1"
  echo " - label1 = $label1"
  echo " - rev1 = $rev1"
  echo "right:"
  echo " - file2 = ${file2/$HOME/\~}"
  echo " - base2 = $base2"
  echo " - label2 = $label2"
  echo " - rev2 = $rev2"
  echo "-------------------------------------------------------------------"

  /usr/local/bin/bcomp  -ro1  -title1="$base1  - $label1 - $rev1" -title2="$base2  - $label2 - $rev2"  "$file1" "$file2"
}


out="$HOME/tmp/bcdiff_cornerstone.log"
date >> $out
echo_params $@ >> $out

exec_bcomp $@ >> $out


exit 0
