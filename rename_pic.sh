#!/usr/bin/env bash
shopt -s extglob  # Enable extended pattern matching in case statements

abort() {
  echo ""
  [ -n "$@" ] && echo $@
  echo "Usage: $(basename $0) --filename filename --title title [--what-if --verbose|-V]"
  exit 1
}
vecho() { [ -n "$SH_VERBOSE" ] && echo "${SCRIPT_NAME}: $@"; }

SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)

while [ -n "$1" ]; do
  opt=$1; shift 1
  vecho "opt=$opt"
  case "$opt" in

    -f | --file@(name) ) 
      FILENAME="$1"; shift 1
      vecho "... --filename FILENAME=$FILENAME"
      ;;

    -t | --title ) 
      TITLE="$1"; shift 1
      vecho "... --title TITLE=$TITLE"
      ;;

    -w ) 
      export SH_WHATIF=1
      vecho "... --what-if ENABLED"
      ;;
    -W )
      unset SH_WHATIF
      vecho "... -W what-if DISABLED"
      ;;

    -v ) 
      export SH_VERBOSE=1
      vecho "... --verbose maximum verbosity"
      ;;
    -V )
      unset SH_VERBOSE
      ;;

    * )
      abort "ERROR: Unexpected option: $opt"
      ;;
  esac
done
vecho "FILENAME=$FILENAME, TITLE=$TITLE, SH_WHATIF=$WH_WHATIF, SH_VERBOSE=$SH_VERBOSE"

[ -z "$FILENAME" ] && abort "ERROR: missing required filename"
[ ! -e "$FILENAME" ] && abort "ERROR: file not found: $FILENAME"
[ -z "$TITLE" ] && abort "ERROR: missing required title"

new_filename=$(echo $FILENAME | sed -E "s/([[:digit:]]{4}(-[[:digit:]]{2}){2} [[:digit:]]{2}(.[[:digit:]]{2}){2})( [[:digit:]]{3,4}[pi])?\.([[:alnum:]]{3,4})/\1 $TITLE\4\.\5/")
vecho "new_filename=$new_filename"

[ "$FILENAME" = "$new_filename" ] && echo "Skipping $FILENAME, no pattern match" && exit 1

[ -z $SH_WHATIF ] && mv -v "$FILENAME" "$new_filename" || echo "WHAT-IF: mv -v \"$FILENAME\" \"$new_filename\""
