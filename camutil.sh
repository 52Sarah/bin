#!/usr/bin/env bash
. "$HOME/.functions"

# Video and photo file manipulation tools.
# - for video, using ffmpeg (brew install ffmpeg)
# - for images, using imagemagick's identify

SCRIPT_NAME="$(basename "$0" 2> /dev/null || echo 'camutil.sh')"

print_usage() {
	[[ -n "$1" ]] && eecho "$SCRIPT_NAME: $*"
	>&2 cat <<-EOF
		usage: $SCRIPT_NAME {--print --rename} [-i expr] [-e expr] [-R] [-m max] [-w|-W -v|-V -q|-Q] [file ...]

		  Manipulate video and photo files, applying one or more commands in sequence.

		  Options:
		    --print
		    --rename
		    -i EXPR
		    -e EXPR
		    -R
		    -m MAX
		    -w|-W
		    -v|-V
		    -q|-Q
	EOF
}

abort() {
	local do_print_usage=1
	[[ "$1" =~ ^(--quiet|-q)$ ]] && shift && do_print_usage=
	eecho "$SCRIPT_NAME: $*"
	[[ $do_print_usage ]] && print_usage
	exit 1
}

camutil() {

	# Inherit caller's environment variables but don't modify them
	local SH_WHATIF="$SH_WHATIF" SH_VERBOSE="$SH_VERBOSE" SH_QUIET="$SH_QUIET"

	local opt_actions=()
	local opt_files=()

	local opt_include_expr
	local opt_exclude_expr
	local opt_recurse
	local opt_max

	local count_processed=0
	while [[ -n "$1" ]]; do
		local opt="$1"; shift
		decho "opt: $opt"
		case "$opt" in

			--print)          opt_actions+=("print");;
			--rename)         opt_actions+=("rename");;

			-i | --include)
				[[ -z "$1" ]] && abort "Missing --include's expression"
				opt_include_expr="$1"; shift
				;;
			-e | --exclude)
				[[ -z "$1" ]] && abort "Missing --exclude's expression"
				opt_exclude_expr="$1"; shift
				;;

			-R | --recursive) opt_recurse=1;;

			-m | --max)
				[[ -z "$1" ]] && abort "Missing --max's value"
				opt_max="$1"; shift
				;;

			-w | --what-if)   SH_WHATIF=1;;
			-W)								SH_WHATIF=;;
			-v | --verbose)   SH_VERBOSE=1; SH_QUIET=;;
			-V)               SH_VERBOSE=;;
			-q | --qiuet)     SH_QUIET=1; SH_VERBOSE=;;
			-Q)               SH_QUIET=;;

			*)                opt_files+=("$opt");;

		esac
	done

	(( ! ${#opt_actions[@]} )) && abort -q "no actions specified"
	echo BLAH
	[[ ${#opt_actions[@]} == 0 ]] && print_usage "$SCRIPT_NAME: no actions specified" && return 1

		# Default to PWD if no files specified.
		[[ ${#opt_files[@]} == 0 ]] && opt_files=("$PWD")

		vecho "$SCRIPT_NAME: opt_files: (${#opt_files[@]}) [${opt_files[*]}]"

		process_nodes "${opt_files[@]}"

		echo "Processed $count_processed files, actions=[${actions[*]}]"
	}

	process_nodes() {
		vecho "$SCRIPT_NAME: ## process_nodes: ($#) [$*]"
		local i=0
		while [[ "$1" ]]; do
			local n="$1"; shift
			local n_tilde="$(tilde_compress "$n")"
			vecho "$SCRIPT_NAME: ## process_nodes: $n_tilde"
			[[ -n "$opt_include_expr" && ! "$n" =~ $opt_include_expr ]] && iecho "   not included: $n_tilde" && continue
			[[ -n "$opt_exclude_expr" && "$n" =~ $opt_exclude_expr ]] && iecho "   excluded: $n_tilde" && continue
			if [[ -d "$n" ]]; then
				iecho "## [$(( i++ ))] $n_tilde/"
				process_folder "$n" || return 1
			elif [[ -f "$n" ]]; then
				iecho "## [$(( i++ ))] $n_tilde"
				process_file "$n" || return 1
			else
				eecho "$SCRIPT_NAME: $n: unexpected file type: $(ls -lhFd "$n")"
				return 1
			fi
		done
		return 0
	}

	process_folder() {
		local folder="$1"; shift
		vecho "$SCRIPT_NAME: ### process_folder: $folder"
		local files
		# shellcheck disable=SC2207  # quote command output into array
		IFS=$'\n' files=( $(find -L "$folder" -mindepth 1 -maxdepth 1) )
		process_nodes "${files[@]}"
	}

	process_file() {
		local f="$1"; shift
		local f_tilde="$(tilde_compress "$f")"
		vecho "$SCRIPT_NAME: ### process_file: $f_tilde"

		for action in "${actions[@]}"; do
			case "$action" in
				print)
echo "$f_tilde"
echo "  - width x height: $(vdim "$f")"
;;
*)
echo "!!! $action($f_tilde)";;
esac
done
(( count_processed++ ))
[[ -n "$opt_max" && $count_processed -ge $opt_max ]] && echo "Reached max: $opt_max" && exit 1
return 0
}

# Return dimensions of video $1 in 'WxH' form; e.g., '800x600'.
vdim() {
	which ffprobe >& /dev/null || eecho "find_video_width_height: no ffprobe" && return 1
	local f="${1?:usage: vdim file}"
	local resolution="$(ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=width,height "$f")"
	[[ -z "$resolution" ]] && eecho "$SCRIPT_NAME: $f_tilde: unable to determine video's resolution using ffprobe" && return 1
	local width="$(grep "width=" <<< "$resolution" | cut -d'=' -f2)"
	local height="$(grep "height=" <<< "$resolution" | cut -d'=' -f2)"
	echo "${width}x${height}"
}


camutil "$@"
