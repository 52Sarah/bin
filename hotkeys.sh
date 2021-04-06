#!/usr/bin/env bash

# @  =  ⌘ command
# ~  =  ⌥ option
# ^  =  ⌃ control
# $  =  shift
#
# \\U21a9  =  ↩︎  return
#
# \\U2191  =  ▲  up arrow 
# \\U2193  =  ▼  down arrow 
#
# \\Uf70a  =  F7

define-hotkeys() {
  local opt_verbose="$SH_VERBOSE" opt_quiet="$SH_QUIET"
  [[ "$1" =~ ^--?v ]] && opt_verbose=1 && opt_quiet= && shift 1
  [[ "$1" =~ ^--?q ]] && opt_verbose= && opt_quiet=1 && shift 1

  shopt -s extglob
  local target

  local opt="$1" && shift
  case "$opt" in
    '')
      target=;;
    beyondcompare | bc | bey* | b*com*)
      target="com.ScooterSoftware.BeyondCompare";;
    contacts | con* | addresses | add*)
      target="com.apple.contacts";;
    excel | exc* | xl)
      target="com.microsoft.Excel";;
    finder | fin*)
      target="com.apple.finder";;
    keyboardmaestro | km* | key*)
      target="com.stairways.keyboardmaestro.editor";;
    music | mus* | itunes)
      target="com.apple.Music";;
    # outlook | out*)
    #   target="com.microsoft.Outlook";;
    # patina | pat*)
    #   target="com.atek.Patina";;
    # typora | typ*)
    #   target="abnerworks.Typora";;
    *)
      >&2 echo "define-hotkeys: warning: invalid option: $opt; passing thru"
      target="opt";;
  esac
  if [[ -n "$target" ]]; then
    ((opt_verbose)) && echo "opt: $opt, target: $target"
  else
    ((!opt_quiet)) && echo "Loading all domains."
  fi

  #
  # BEYOND COMPARE
  #
  domain="com.ScooterSoftware.BeyondCompare"
  if [[ -z "$target" || "$target" = "$domain" ]]; then
    defaults write "$domain" NSUserKeyEquivalents '{
      "\033Session\033Session Settings..." = "@~,";

      "\033Actions\033Open" = "@$o";
      "\033Actions\033Open With\033Associated Application" = "@o";
      "\033Actions\033Set as Base Folder" = "@b";
      "\033Actions\033Set as Base Folders" = "@$b";
      "\033Actions\033Compare Contents" = "@^c";
      "\033Actions\033Copy to Left" = "^l";
      "\033Actions\033Copy to Right" = "^r";
      "\033Actions\033Touch..." = "@~t";
      "\033Actions\033Exclude" = "@~x";

      "\033Edit\033Expand All" = "@$=";
      "\033Edit\033Collapse All" = "@$-";

      "\033Search\033Next Difference" = "\\Uf70a";
      "\033Search\033Previous Difference" = "$\\Uf70a";
    }'
    ((!opt_quiet)) && list-hotkeys "$domain"
  fi

  #
  # CONTACTS
  #
  domain="com.apple.contacts"
  if [[ -z "$target" || "$target" = "$domain" ]]; then
    defaults write "$domain" NSUserKeyEquivalents '{
    }'
    ((!opt_quiet)) && list-hotkeys "$domain"
  fi
  
  #
  # EXCEL
  #
  domain="com.microsoft.Excel"
  if [[ -z "$target" || "$target" = "$domain" ]]; then
    defaults write "$domain" NSUserKeyEquivalents '{
      "\033Format\033Column\033AutoFit Selection" = "@^a";
    }'
    ((!opt_quiet)) && list-hotkeys "$domain"
  fi

  #
  # FINDER
  #
  domain="com.apple.finder"
  if [[ -z "$target" || "$target" = "$domain" ]]; then
    defaults write "$domain" NSUserKeyEquivalents '{
      "\033File\033Rename Item" = "^r";
      "\033File\033Rename 2 Items..." = "^r";
      "\033File\033Rename 3 Items..." = "^r";
      "\033File\033Rename 4 Items..." = "^r";
      "\033File\033Rename 5 Items..." = "^r";
      "\033File\033Rename 6 Items..." = "^r";
    }'
    ((!opt_quiet)) && list-hotkeys "$domain"
  fi

  #
  # KEYBOARD MAESTRO
  #   ⌘⌥X (command-option-X)  File / Export Macros...
  #   ⌘⌥E (command-option-E)  View / [Enable|Disable] [Macro|Group|Action]
  #   ⌘⌥K (command-option-K)  Actions / Try Action
  #   ^U  (Control-U)         View / Rename...
  #   ⌘⌥L (command-option-H)  Actions/ Help
  #
  domain="com.stairways.keyboardmaestro.editor"
  if [[ -z "$target" || "$target" = "$domain" ]]; then
      # "\033View\033Rename..." = "^r";
      # "\033Actions\033Rename..." = "^r";
    defaults write "$domain" NSUserKeyEquivalents '{
      "\033File\033Export Macros..." = "@~x";

      "\033View\033Enable Action" = "@~e";
      "\033View\033Disable Action" = "@~e";

      "\033Actions\033Try Action" = "@~r";
      "\033Actions\033Enable Action" = "@~e";
      "\033Actions\033Disable Action" = "@~e";
      "\033Actions\033Help" = "@~h";
    }'
    ((!opt_quiet)) && list-hotkeys "$domain"
  fi
  
  #
  # MUSIC.APP
  #
  domain="com.apple.Music"
  if [[ -z "$target" || "$target" = "$domain" ]]; then
    defaults write "$domain" NSUserKeyEquivalents '{
      "\033File\033New\033Playlist Folder" = "^@$";
      "\033File\033New\033Playlist from Selection" = "^n";
      "\033Song\033Love" = "^l";
      "\033Song\033Loved" = "^l";
      "\033Song\033Dislike" = "^d";
      "\033Song\033Disliked" = "^d";
      "\033Song\033Show Album in Library" = "@$l";
      "\033View\033as Artists" = "@$r";
      "\033View\033as Albums" = "@$b";
      "\033View\033as Songs" = "@$s";
    }'
    ((!opt_quiet)) && list-hotkeys "$domain"
  fi

  # #
  # # OUTLOOK
  # #
  # domain="com.microsoft.Outlook"
  # if [[ -z "$target" || "$target" = "$domain" ]]; then
  #   defaults write "$domain" NSUserKeyEquivalents '{
  #     "\033Message\033Archive" = "@$e";
  #     "\033Tools\033Rules..." = "@$u";
  #   }'
  #   ((!opt_quiet)) && list-hotkeys "$domain"
  # fi

  # #
  # # PATINA
  # #
  # domain="com.atek.Patina"
  # if [[ -z "$target" || "$target" = "$domain" ]]; then
  #   defaults write "$domain" NSUserKeyEquivalents '{
  #     "\033Image\033Adjust Selection Size..." = "@~s";
  #   }'
  #   ((!opt_quiet)) && list-hotkeys "$domain"
  # fi

#   #
#   # TYPORA
#   #
#   domain="abnerworks.Typora"
#   if [[ -z "$target" || "$target" = "$domain" ]]; then
#     defaults write "$domain" NSUserKeyEquivalents '{
#       "\033Paragraph\033Ordered List" = "@$7";
#       "\033Paragraph\033Unordered List" = "@$8";
#     }'
#     ((!opt_quiet)) && list-hotkeys "$domain"
#   fi

  killall cfprefsd
}

# usage: list-hotkeys [domain]
list-hotkeys() {
  local domain="$1"; shift 1

  if [[ -z "$domain" ]]; then
    defaults find NSUserKeyEquivalents |\
    grep -E -A 100 "^Found 1 keys in domain '[^']" |\
      sed -E \
        -e '/:|=.+;$/! d;' \
        -e "/^Found 1 keys in domain '[^']+': \{$/ s/^.+ '([^']+)'.+$/\1:/" \
        -e 's/"\\033/"/g; s/\\033/ -> /g' \
        -e 's/ = "/ = /; s/";$//;' \
        -e 's/( = .*)@/\1Command-/;' \
        -e 's/( = .*)~/\1Option-/;' \
        -e 's/( = .*)\^/\1Control-/;' \
        -e 's/( = .*)\$/\1Shift-/;' \
      -e 's/( = .*)\\\\\\\\U21a9/\1Return/;' \
      -e 's/( = .*)\\\\\\\\Uf70a/\1F7/;'
    # /:|=.+;$/! d;  ...  if line has no = or : in it, delete
    # /^Found 1 keys ... s/^.+ '([^']+)'.+$/\1:/  ...  trim header to only domain and colon
    # s/"\\033/"/g; s/\\033/ -> /g  ...  remove leading \033s, replace innner with ' -> ''
    # s/ = "/ = /; s/";$//;  ...  remove double quotes around key sequence

  else
    echo "${domain}:"
    defaults read "$domain" NSUserKeyEquivalents | sed -E \
      -e '/:|=.+;$/! d;' \
      -e 's/"\\033/"/g; s/\\033/ -> /g' \
      -e 's/ = "/ = /;' \
      -e 's/";$//;' \
      -e 's/( = .*)@/\1Command-/;' \
      -e 's/( = .*)~/\1Option-/;' \
      -e 's/( = .*)\^/\1Control-/;' \
      -e 's/( = .*)\$/\1Shift-/;' \
      -e 's/( = .*)\\\\\\\\U21a9/\1Return/;' \
      -e 's/( = .*)\\\\\\\\Uf70a/\1F7/;'
  fi
}

>&2 echo "Only sourced hotkeys.sh; execute define-hotkeys or list-hotkeys."
