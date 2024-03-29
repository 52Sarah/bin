#!/usr/bin/env bash

# Create a shell script with commands needed to re-create all current hotkeys
# defined in the Keyboard prefs pane, App Shortcuts.

print_usage() {
	[[ "$1" ]] && eecho "$*"
	cat <<-EOF
	usage: export_hotkeys.sh [-v] [out_file]
	       Default output_file is mac-hotkeys-YYYYMMDD.sh
	EOF
}

export_hotkeys() {
	[[ "$1" = "-v" ]] && local _VERBOSE=1 && shift
	local OUT="$1"
	[[ -z "$OUT" ]] && OUT="mac-hotkeys-$(date +'%Y%m%d').sh"

    echo '#!/usr/bin/env bash' > "$OUT"

    defaults find NSUserKeyEquivalents | \
    sed \
    -e "s/Found [0-9]* keys in domain '\\([^']*\\)':/defaults write \\1 NSUserKeyEquivalents '/" \
    -e "s/    NSUserKeyEquivalents =     {//" \
    -e "s/};//" -e "s/}/}'/" >> "$OUT"

    echo killall cfprefsd >> "$OUT"
    chmod a+x "$OUT"

    iecho "Wrote $(grep -E -c '=.+;$' "$OUT") key mappings to $OUT"
}
export_hotkeys $@
