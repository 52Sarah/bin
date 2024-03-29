#!/usr/bin/env bash

# entry point to run tox on all tox projects below PWD, or for a specific list of folders
# usage: toxx -a|--all
#		 toxx -s|--summary  <- summarizes the last generated toxx.log file
#		 toxx toxx_path1 [... toxx_pathN]
toxx() {
	[[ -z "$1" ]] && eecho "usage: toxx [-] [-q] [--fast/er/est] [--append] [lint | summary | logs | tail | toxx_lib [ ... toxx_libN]" && return 1

	[[ -z "$PPF_HOME" ]] && eprintf "toxx: PPF_HOME must point to the root of the P-Pipeline-Framework project/repo" && return 1

	local _VERBOSE=$_VERBOSE && [[ "$1" =~ ^(-v|--verbose)$ ]] && shift && _VERBOSE=1 && _QUIET=
	local _QUIET=$_QUIET && [[ "$1" =~ ^(-q|--quiet)$ ]] && shift && _QUIET=1 && _VERBOSE=

	iprintf "toxx: starting({v=%s, q=%s} %s)\n" "$_VERBOSE" "$_QUIET" "$*"

	local TOXX_LOGS="$HOME/log"
	local TOXX_SUMMARY="$TOXX_LOGS/toxx-summary.log"

	# --fast* options will disable some of these testenv's:
	#clean,lint-check,py36,manifest,pypi-description,coverage-report,lint,artifactory-build,artifactory-publish
	local TOXX_ENV=
	[[ "$1" =~ -f1|-f|--fast ]] && shift && TOXX_ENV='clean,lint-check,py36,lint'
	[[ "$1" =~ -f2|--faster ]] && shift && TOXX_ENV='lint-check,py36,lint'
	[[ "$1" =~ -f3|--fastest ]] && shift && TOXX_ENV='py36'

	local opt_append= && [[ "$1" =~ -a|--append ]] && shift && opt_append=1
	local opt_check= && [[ "$1" =~ -c|--check ]] && shift && opt_check=1
	local opt_json= && [[ "$1" =~ -j|--json ]] && shift && opt_json=1

	if [[ "$1" = "lint" ]]; then
		shift && toxx_lint $@
	elif [[ "$1" =~ ^(logs?)$ ]]; then
		shift && toxx_logs $@
	elif [[ "$1" =~ ^(summ(ary)?)$ ]]; then
		shift && toxx_summary $@
	elif [[ "$1" = "tail" ]]; then
		shift && toxx_tail $@
	# elif [[ "$1" =~ -a|--all ]]; then
	# 	shift && toxx_all $@
	else
		toxx_many $@
	fi
	iprintf "toxx: finished(%s)\n" "$*"
}

# run tox on all projects passed in on the command line
# usage: toxx-many toxx_path1 [... toxx_pathN]
toxx_many() {
	vprintf "toxx_many: starting(%s)\n" "$*"
	[[ -z "$1" ]] && eecho "usage: toxx_many toxx_path [ ... toxx_pathN]" && return 1
	local toxx_paths="$*"
	local toxx_path_count=$#

	if [[ -z "$opt_append" && -s "$TOXX_SUMMARY" ]]; then
		vprintf "Deleting existing summary file: %s\n" "$(tilde_compress "$TOXX_SUMMARY")"
		rm -f "$TOXX_SUMMARY"
	fi

	local i=1
	while [[ "$1" ]]; do
		local toxx_path="$1" && shift
		vprintf "toxx_many: starting %d of %d: %s\n" $((i)) $toxx_path_count "$toxx_path"
		toxx_one "$toxx_path" || return 1
		vprintf "toxx_many: finished %d of %d: %s\n" $((i++)) $toxx_path_count "$toxx_path"
	done

	vprintf "toxx_many: finished(%s)\n" "$toxx_paths"
}


# run tox on a single lib, then filter key lines from the output into a summary
# usage: toxx_one toxx_path
toxx_one() {
	iprintf "toxx_one: starting(%s)\n" "$*"
	[[ -z "$1" ]] && eecho "usage: toxx_one toxx_lib" && return 1
	
	local toxx_lib="$1" && shift
	[[ ! -f "$toxx_lib/tox.ini" ]] && eprintf "toxx_one: %s: no tox.ini found\n" "$toxx_lib" && return 1

	local toxx_log_file="$TOXX_LOGS/toxx_${toxx_path}.log"
	rm -f "$toxx_log_file"
	
	local result_json=
	if [[ -n "$opt_json" ]]; then
		local toxx_json_file="$TOXX_LOGS/toxx_${toxx_path}.json"
		rm -f "$toxx_json_file"
		result_json="--result-json '$toxx_json_file'"
	fi

	iprintf "toxx_one: starting tox; lib=%s, TOXENV=(%s), log=%s, json=%s\n" "$toxx_lib" "$TOXX_ENV" "$(tilde_compress $toxx_log_file)" "$(tilde_compress $toxx_json_file)" >> "$toxx_log_file"
	pushd "$toxx_lib" > /dev/null
	if [[ -n "$TOXX_ENV" ]]; then
		1>&2 tox --develop $result_json -e "$TOXX_ENV" >> "$toxx_log_file"
	else
		1>&2 tox --develop $result_json "$toxx_json_file" >> "$toxx_log_file"
	fi
	popd > /dev/null
	eprintf "toxx_one: finished tox; wrote lines: %s\n" "$(wc -l "$toxx_log_file")"

	toxx_summary_one "$toxx_lib" |tee "$TOXX_SUMMARY"

	iprintf "toxx_one: finished(%s)\n" "$toxx_path"
}

# # run tox on all projects found beneath the current directory
# # usafe: toxx_all
# toxx_all() {
# 	eecho "starting toxx_all($@)"
# 	for toxx_path in $(find "." -name "tox.ini" -exec dirname "{}"\;); do
# 		printf "toxx_all: starting %s\n" "$toxx_path"
# 		toxx_one "$toxx_path"
# 		printf "toxx_all: finished %s\n" "$toxx_path"
# 	done
# }

# summarize all tox runs, compressing oft-repeteated text and only what's relevant from a dev perspective
toxx_summary() {
	vprintf "toxx_summary: starting(%s)\n" "$*"

	if [[ -z "$opt_append" && -s "$TOXX_SUMMARY" ]]; then
		vprintf "Deleting existing summary file: %s\n" "$(tilde_compress "$TOXX_SUMMARY")"
		rm -f "$TOXX_SUMMARY"
	fi

	if [[ -n "$1" ]]; then
		while [[ -n "$1" ]]; do
			local toxx_lib="$1" && shift
			vprintf "toxx_summary: summarizing lib '%s'\n" "$toxx_lib"
			toxx_summary_one "$toxx_lib" |tee "$TOXX_SUMMARY"
		done
	else
		for toxx_file in $TOXX_LOGS/toxx_*.log; do
			local toxx_lib="$(echo "$toxx_file" | sed -E -e 's^.*/toxx_(.+)\.log$^\1^;')"
			vprintf "toxx_summary: summarizing lib '%s'\n" "$toxx_lib"
			toxx_summary_one "$toxx_lib"
		done
	fi

	vprintf "toxx_summary: finished(%s)\n" "$*"
}

# summarize the given lib's tox run and append result to TOXX_SUMMARY
toxx_summary_one() {
	iprintf "toxx_summary_one: starting(%s)\n" "$*"
	[[ -z "$1" ]] && eecho "usage: toxx_summary_one toxx_lib" && return 1

	local toxx_lib="$1" && shift

	local toxx_log_file="$TOXX_LOGS/toxx_${toxx_lib}.log"
	[[ ! -s "$toxx_file" ]] && eprintf "Skipping module '%s' missing or empty log file: %s\n" "$toxx_lib" "$toxx_file" && return 1

	local toxx_summ_temp_file="$HOME/tmp/toxx_${toxx_lib}.log.tmp"
	rm -f "$toxx_summ_temp_file"

	sed -E \
		-e "s^$HOME/git/P-Pipeline-Framework/Components^\${pf_root}^;" \
		\
		"$toxx_log_file" > "$toxx_summ_temp_file"

	iprintf "\n>>> SUMMARIZING $toxx_lib at $(date +'%a, %Y-%m-%d %H:%M:%S') <<<\n\n" #>> "$TOXX_SUMMARY"
	grep -E --color=never \
		\
		-e '^would .*reformat' \
		-e '^Oh no!' \
		\
		-e 'ERROR' \
		-e 'FAILED' \
		-e 'SKIPPED' \
		\
		-e '^==+ .+ ==+$' \
		-e '^__.*' \
		\
		-e 'collecting \.\.\. ' \
		\
		-e "tests/${toxx_lib}/.+\\.py:\\d+: " \
		-e "^\\s+from pipeline_framework\\.${toxx_lib}\\.\\w+" \
		\
		-e '^Traceback ' \
		-e '^.+/pipeline_framework/src/lib(/[^/]+)+\.py", line \d+, in .+' \
		-e '\.exceptions\.\w+: .+' \
		\
		-e '^\s+ .+: commands .+$' \
		-e '^\s+ congratulations' \
		\
		"$toxx_summ_temp_file" \
		|\
	grep -E -v --color=never \
		-e '\.reports'
	printf "\n"

	# -e '^Name\s* Stmts\s* Miss\s* Cover$' \
	# -e '^(pipeline_framework/.+\.py|TOTAL)\s* \d+\s* [1-9]\d*\s* \d+%$' \
	# -e '^--.*' \
	# -e '^tests/.+\.py::\w+::.+ FAILED \[ \d+%\]$' \
	# sed -E -e 's/^([[:digit:]]+):/\1: /;' \
	# 	\
	
	# removed PASSED tests above, but may want to restore them
	# renoved: -e '^lint-check create:\s.+$'
	# removed: -e '^[>E]\s.*$' as it seemed to pull random info that was useless without the big picture

	iprintf "toxx_summary_one: finished(%s)\n" "$toxx_lib"
}
toxx_lint() {
	iprintf "toxx_lint: starting(%s)\n" "$*"
	[[ -z "$1" ]] && eecho "usage: toxx_lint toxx_lib [...]" && return 1

	local toxx_lib="$1" && shift
	pushd "$toxx_lib" > /dev/null

	iprintf ">>> isort(%s): <<<\n" "$toxx_lib"
	isort --settings-path="$PPF_HOME/.isort.cfg" -y || return 1 && iprintf ">>> isort(%s): SUCCESS <<<\n\n" "$toxx_lib"

	iprintf ">>> black(%s): <<<\n" "$toxx_lib"
	black -v --config="$PPF_HOME/pyproject.toml" . || return 1 && iprintf ">>> black(%s): SUCCESS <<<\n\n" "$toxx_lib"

	iprintf ">>> flake8(%s): <<<\n" "$toxx_lib"
	flake8 --config="$PPF_HOME/.flake8" --black-config="../../../../../pyproject.toml" . || return 1 && iprintf ">>> flake8(%s): SUCCESS <<<\n\n" "$toxx_lib"
	
	popd > /dev/null

	vprintf "\ntoxx_lint: finished\n"
}

toxx_logs() {
	vprintf "toxx_logs: starting(%s)\n" "$*"

	ls -oHtr "$TOXX_LOGS"/toxx_*.log |\
		grep -E -v -e '^[td].+' -e '^(\S+\s+){3}0\s.+$' |\
		sed -E -e "s:$HOME:~:;"

	vprintf "toxx_logs: finished(%s)\n" "$*"
}

toxx_tail() {
	vprintf "toxx_tail: starting\n"
	tail $TOXX_LOGS/toxx_*.log
	vprintf "toxx_tail: finished\n"
}


eecho() { 1>&2 echo $@; }
eprintf() { 1>&2 printf $@; }

vprintf() { [[ -n "$_VERBOSE" ]] && eprintf $@; }
iprintf() { [[ -z "$_QUIET" ]] && eprintf $@; }


alias .reload-toxx=". $HOME/bin/toxx.sh"

return 0