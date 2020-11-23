#!/usr/bin/env bash

# see https://www.scootersoftware.com/support.php?zz=kb_vcs_osx#svn

echo "$0"
echo "\$1 = $1"
echo "\$2 = $2"
echo "\$3 [title1] = $3"
echo "\$4 = $4"
echo "\$5 [title2] = $5"
echo "\$6 [file1] =  ${6/$HOME/\~}"
echo "\$7 [file2] =  ${7/$HOME/\~}"
echo "-------------------------------------------------------------------"

/usr/local/bin/bcompare  -ro1  -title1="$3" -title2="$5"  "$6" "$7"
