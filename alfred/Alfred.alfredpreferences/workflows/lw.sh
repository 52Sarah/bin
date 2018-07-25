#!/usr/bin/env bash
>&2 pwd

# if running from Alfred, use parent dir; else (for testing) WORKFLOWS_DIR should be set on entry
: "${WORKFLOWS_DIR:="$(cd .. || exit 1; pwd)"}"

# bash is NOT the right tool for this, but it's fun to try...
# - use grep to extract the first <key>name</key> line from each info.plist file
# - include the next line, which should be <string>Workflow Name</string>
# - use sed to filter through only the <string> lines' text value
# wrap that output to represent an array of json hashes, value as the title property
CR=$'\n'
workflows="[${CR}$(for f in $WORKFLOWS_DIR/*/info.plist; do
  grep --max-count=2 --after-context=1 '<key>name</key>' "$f"
done | \
    sed -E -n -e '/^.*<string>(.+ \| .+)<\/string>.*$/s//{title: "\1"},/p' | \
    sort \
)${CR}]"

>&2 echo "$workflows"
