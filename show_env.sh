#!/usr/bin/env bash

echo_section() {
	local cmd="$1" && shift
	local -i max=$1 && shift
	local title="$1" && shift

	local output="$(eval "$cmd" | sort | sed 's/=/ = /')"
	local -i all_lines=0
	[[ "$output" ]] && all_lines=$(wc -l <<<"$output")

	(( max )) && output="$(head -n $max <<<"$output")"
	local -i shown_lines=0
	[[ "$output" ]] && shown_lines=$(wc -l <<<"$output")


	echo ""
	echo "${title:-$cmd}"
	echo "----------"
	echo "$output"
	echo "----------"
	echo "Showing $shown_lines of $all_lines items"
	echo "=========="
}

echo_section "export -p" 10 "Exported Variables"
echo_section "export -f" 10 "Exported Functions"
echo_section "set" 10 "Shell and Environment variables"
echo_section "declare -F" 10 "Declared Functions"
