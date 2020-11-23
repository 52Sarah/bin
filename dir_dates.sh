#!/usr/bin/env bash

TAB=$'\t'
IFS=$'\n'
for d in $(find . -type d); do
	echo "$(stat -t '%F %H:%M' -f "%Sm" "$d/$(ls -1t "$d" | tail -n 1)")  $d"
	# stat -t '%F %T' -f "%8z${TAB}%Sm${TAB}%N" "$d/$(ls -1t "$d" | tail -n 1)"
done | sort