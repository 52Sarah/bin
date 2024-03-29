#!/usr/bin/env bash
shopt -s extglob  # Enable extended pattern matching in case statements

abort() {
  echo ""
  [ -n $@ ] && echo $@
  echo "Usage: $(basename $0) --filename filename [--resolution 720|480|360|240 --replace] [--what-if --quiet|-Q --verbose|-V]"
  exit 1
}
iecho() { [ -z "$_QUIET" ] && echo $@; }
vecho() { [ -n "$_VERBOSE" ] && echo "${SCRIPT_NAME}: $@"; }

SCRIPT_NAME=$(basename $0)


RESOLUTION="720"

while [ -n "$1" ]; do
  opt=$1; shift 1
  vecho "opt=$opt"
  case "$opt" in

    -f | --file@(name) ) 
      FILENAME="$1"; shift 1
      vecho "... --filename FILENAME=$FILENAME"
      ;;

    -r | --replace ) 
      REPLACE=1; shift 1
      vecho "... --replace ENABLED"
      ;;

    --res@(olution) ) 
      RESOLUTION="$1"; shift 1
      vecho "... --resolution RESOLUTION=$RESOLUTION"
      ;;

    -w | --what-if ) 
      export _WHATIF=1
      vecho "... --what-if ENABLED"
      ;;
    -W )
      unset _WHATIF
      vecho "... -W what-if DISABLED"
      ;;

    -q | --quiet ) 
      export _QUIET=1; unset _VERBOSE
      ;;
    -Q )
      unset _QUIET
      ;;

    -v | --verbose ) 
      export _VERBOSE=1; unset _QUIET
      vecho "... --verbose maximum verbosity"
      ;;
    -V )
      unset _VERBOSE
      ;;

    * )
      abort "ERROR: Unexpected option: $opt"
      ;;
  esac
done
vecho "FILENAME=$FILENAME, REPLACE=$REPLACE, RESOLUTION=$RESOLUTION, _WHATIF=$_WHATIF, _VERBOSE=$_VERBOSE"

[ -z "$FILENAME" ] && abort "ERROR: missing required filename"
[ ! -e "$FILENAME" ] && abort "ERROR: file not found: $FILENAME"
[ -z "$_QUIET" ] && ls -oh "$FILENAME"

# If resolution already appended, bail.
[[ "$FILENAME" =~ ^.+\ ${RESOLUTION}p\..{3,4}$ ]] && echo "Skipping $FILENAME, resolution '$RESOLUTION' already appended" && exit 0

# Save old extension and remove old resolution, if present.
extension="${FILENAME##*.}"
if [[ "$FILENAME" =~ ^.+\ [0-9]{3,4}p\..{3,4}$ ]]; then
  new_filename="${FILENAME% *}"  # everything before the last space
else
  new_filename="${FILENAME%.*}"  # everything before the last period
fi
new_filename="${new_filename} ${RESOLUTION}p.${extension}"
vecho "new_filename=$new_filename"


c="ffmpeg -i \"$FILENAME\" -hide_banner -v warning -vf scale=-1:${RESOLUTION} -c:v libx264 -crf 18 -preset slow -c:a copy \"$new_filename\" || abort 'ffmpeg did not exit cleanly'"
if [ -n "$_WHATIF" ]; then
  echo "WHAT-IF: $c"
else
  vecho "\$ $c"
  eval $c
  [ -z "$_QUIET" ] && ls -oh "$new_filename"
fi

if [ -n "$REPLACE" ]; then
  if [ -n "$_WHATIF" -o -s "$new_filename" ]; then
    c="rm -v \"$FILENAME\""
    [ -n "$_WHATIF" ] && echo "WHAT-IF: $c" || (vecho "\$ $c"; eval $c)
  else
    abort "ERROR: New file $new_filename not found, not removing old file $FILENAME"
  fi
fi
