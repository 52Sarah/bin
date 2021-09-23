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

_hotkeys_domains="global beyondcompare calendar contacts dupin excel finder iterm2 keyboardmaestro music preview"

# usage: hotkeys-list [--verbose] [--quiet] [--all] [domain]
hotkeys-list() {
  ((SH_VERBOSE)) && printf 'hotkeys-list: start: "%s"\n' "$*"
  parse-verbose-quiet "$@" || shift $?

  if [[ "$1" =~ ^(-a|--all)$ ]]; then
    shift
    _read_all_domains_keys
    return
  fi

  local target_domains="${@:-$_hotkeys_domains}"
  vecho "target_domains: [$target_domains]"

  local full_domain d_total=0 d_count=0
  for d in $target_domains; do
    ((d_total++))
    full_domain="$(_map_domain "$d")"
    _read_one_domain_keys "$full_domain" && ((d_count++))
  done

  ((d_count < d_total)) && eecho "hotkeys-list: error: only listed hotkeys for $d_count/$d_total domains" && return 1
  return 0
}

# usage: hotkeys-define [-v] [-q] [domain...]
hotkeys-define() {
  ((SH_VERBOSE)) && printf 'hotkeys-define: start: "%s"\n' "$*"
  parse-verbose-quiet "$@" || shift $?

  local target_domains="${@:-$_hotkeys_domains}"

  local d full_domain d_total=0 d_count=0
  for d in $target_domains; do
    ((d_total++))
    full_domain="$(_map_domain "$d")"
    if _write_one_domain "$full_domain"; then
      ((d_count++))
      ((!SH_QUIET)) && hotkeys-list "$full_domain"
    fi
  done

  ((! d_count)) && eecho "hotkeys-define: error: all $d_total_domains hotkey domains failed" && return 1
  local sw_verbose= && ((SH_VERBOSE)) && sw_verbose='-v'
  killall $sw_verbose cfprefsd

  ((d_count < d_total)) && eecho "hotkeys-define: error: only defined hotkeys for $d_count/$d_total domains" && return 1
  return 0
}

# Given $1...
# - abbreviation for app's domain, return full NSUserKeyEquivalents domain string
# - blank, return blank
# - unrecognized abbreviation, $1 as-is
_map_domain() {
  [[ -z "$1" ]] && return 0

  local domain

  local abb="$(lower $1)" && shift
  case "$abb" in
    nsglobaldomain|nsgd|ngd | appleglobaldomain|agd | global|globaldomain)
                                        domain='NSGlobalDomain';;
    beyondcompare|*.beyondcompare|bc)   domain='com.ScooterSoftware.BeyondCompare' ;;
    calendar | icalendar|*.ical|ical)   domain='com.apple.iCal' ;;
    contacts|*.contacts | addresses)    domain='com.apple.contacts' ;;
    dupin|*.dupin)                      domain='com.dougscripts.Dupin' ;;
    excel|*.excel)                      domain='com.microsoft.Excel' ;;
    finder|*.finder)                    domain='com.apple.finder' ;;
    iterm|iterm2|*.iterm2)              domain='com.googlecode.iterm2' ;;
    keyboardmaestro|km*|*.keyb)         domain='com.stairways.keyboardmaestro.editor' ;;
    music|*.music | itunes)             domain='com.apple.Music' ;;
    preview|*.preview)                  domain='com.apple.Preview' ;;
    # outlook | out*)  domain='com.microsoft.Outlook';;
    # patina | pat*)   domain='com.atek.Patina';;
    # typora | typ*)   domain='abnerworks.Typora';;
    *)
      vecho "_map_domain: info: unrecognized domain abbreviation: $abb; passing thru"
      domain="$abb";;
  esac
  
  echo "$domain"
  return 0
}

# Given $1 is a valid defaults domain, read/list its hotkeys and return 0; else return 1.
_read_one_domain_keys() {
  local domain="${1//_/ }" && shift
  [[ -z "$domain" ]] && eecho "usage: _read_one_domain_keys domain" && return 1

  printf "%s\n" "${domain}"
  defaults read "$domain" NSUserKeyEquivalents | sed -E \
    -e '/:|=.+;$/! d' \
    -e 's/"\\033//g' \
    -e 's/\\033/ > /g' \
    -e 's/[";]//g' \
    -e 's/( = .*)@/\1[⌘] + /' \
    -e 's/( = .*)~/\1[⌥] + /' \
    -e 's/( = .*)\^/\1[^] + /' \
    -e 's/( = .*)\$/\1[Shift] + /' \
    -e 's/( = .*)\\\\\\\\U21a9/\1Return/' \
    -e 's/( = .*)\\\\\\\\Uf70a/\1F7/' |\
  awk -F '=' '{ printf "%-60s %s\n", $1, substr($2,1,length($2)-1) toupper(substr($2,length($2))); }'
}

_read_all_domains_keys() {
  defaults find 'NSUserKeyEquivalents' | sed -E \
    -e '/:|=.+;$/! d' \
    -e "s/^Found 1 keys in domain '(.+)': \{/\\1:/" \
    -e 's/"\\033//g' \
    -e 's/\\033/ > /g' \
    -e 's/[";]//g' \
    -e 's/( = .*)@/\1[⌘] + /' \
    -e 's/( = .*)~/\1[⌥] + /' \
    -e 's/( = .*)\^/\1[^] + /' \
    -e 's/( = .*)\$/\1[Shift] + /' \
    -e 's/( = .*)\\\\\\\\U21a9/\1Return/' \
    -e 's/( = .*)\\\\\\\\Uf70a/\1F7/' |\
  awk -F '=' '{ printf "%-60s %s\n", $1, substr($2,1,length($2)-1) toupper(substr($2,length($2))); }'
}

# Given $1 is a valid defaults domain, define its hotkeys and return 0; else return 1.
# For the rare domains with spaces in their names, replace underscores with spaces.
_write_one_domain() {
  ((SH_VERBOSE)) && printf '_write_one_domain: start: "%s"\n' "$*"
  local domain="${1//_/ }" && shift
  [[ -z "$domain" ]] && eecho "usage: _write_one_domain domain" && return 1

  case "$domain" in

    # APPLE GLOBAL DOMAIN
    #
    # [⌥]+[^]+1   Window > Move to VX228
    # [⌥]+[^]+2   Window > Move to Thunderbolt Display
    # [⌥]+[^]+3   Window > Move to Built-in Retina Display
    # [⌥]+[^]+[   Window > Tile Window to Left of Screen
    # [⌥]+[^]+]   Window > Tile Window to Right of Screen
    #
    NSGlobalDomain)
      defaults write "$domain" NSUserKeyEquivalents '{
        "\033Window\033Move to VX228" = "~^1";
        "\033Window\033Move to Thunderbolt Display" = "~^2";
        "\033Window\033Move to Built-in Retina Display" = "~^3";
        "\033Window\033Move Window to Left Side of Screen" = "~^[";
        "\033Window\033Move Window to Right Side of Screen" = "~^]";
        "\033Window\033Tile Window to Left of Screen" = "~^$[";
        "\033Window\033Tile Window to Right of Screen" = "~^$]";
      }'
      return 0;;

    # BEYOND COMPARE
    #
    # [⌘]+[Shift]+O   Actions > Open
    # [⌘]+O           A       > Open With > Associated Application
    # [⌘]+B           A       > Set as Base Folder
    # [⌘]+[Shift]+B   A       > Set as Base Folders
    # [⌘]+[^]+C       A       > Compare Contents
    # [^]+L           A       > Copy to Left
    # [^]+R           A       > Copy to Right
    # [⌘]+[⌥]+T       A       > Touch...
    # [⌘]+[⌥]+X       A       > Exclude
    # [⌘]+[Shift]+=   Edit > Expand All
    # [⌘]+[Shift]+-   E    > Collapse All
    # F7              Search > Next Difference
    # [Shift]+F7      S      > Previous Difference
    #
    com.ScooterSoftware.BeyondCompare)
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
      }'
      return 0;;

        # 5/5 these were interpreted as the actual keystroke "U".
        # "\033Search\033Next Difference" = "\\Uf70a";
        # "\033Search\033Previous Difference" = "$\\Uf70a";

    # CONTACTS
    #
    # [⌘]+[⌥]+S   View > Show|Hide Groups
    #
    com.apple.contacts)
      defaults write "$domain" NSUserKeyEquivalents '{
        "\033View\033Show Groups" = "@~s";
        "\033View\033Hide Groups" = "@~s";
      }'
      return 0;;
  
    # CALENDAR
    #
    # [⌘]+[⌥]+S   View > Show|Hide Calendar List
    #
    com.apple.iCal)
      defaults write "$domain" NSUserKeyEquivalents '{
        "\033View\033Show Calendar List" = "@~s";
        "\033View\033Hide Calendar List" = "@~s";
      }'
      return 0;;
  
    # DUPIN
    #
    com.dougscripts.Dupin)
      defaults write "$domain" NSUserKeyEquivalents '{
        "\033Tools\033Purge..." = "@~$p";
        "\033Tools\033Re-Playlist..." = "@$p";
        "\033Tools\033Remove Duplicate Entries From Playlists..." = "@$d";
      }'
      return 0;;
  
    # EXCEL
    #
    # [⌘]+[^]+A   Format > Column -> AutoFit Selection
    #
    com.microsoft.Excel)
      defaults write "$domain" NSUserKeyEquivalents '{
        "\033Format\033Column\033AutoFit Selection" = "@^a";
      }'
      return 0;;

    # FINDER
    #
    # [^]+R       File > Rename|Rename n Items...
    #
    com.apple.finder)
      defaults write "$domain" NSUserKeyEquivalents '{
        "\033File\033Rename Item" = "^r";
        "\033File\033Rename 2 Items..." = "^r";
        "\033File\033Rename 3 Items..." = "^r";
        "\033File\033Rename 4 Items..." = "^r";
        "\033File\033Rename 5 Items..." = "^r";
        "\033File\033Rename 6 Items..." = "^r";
      }'
      return 0;;

    # ITERM2
    #
    # [^]+SPACE   Session > Open Autocomplete...
    # [⌥]+/       Session > Open Autocomplete...
    #
    com.googlecode.iterm2)
      defaults write "$domain" NSUserKeyEquivalents '{
      }'
      return 0;;
  
    # KEYBOARD MAESTRO
    #
    # [⌘]+[⌥]+X   File > Export Macros...
    # [⌘]+[⌥]+E   View > Enable|Disable Macro|Group|Action
    # [⌘]+[⌥]+K   Actions > Try Action
    # [⌘]+[⌥]+H   A       > Help
    #
    #   [^]+R       View|Actions / Rename...
    #   "\033View\033Rename..." = "^r";
    #   "\033Actions\033Rename..." = "^r";
    #
    com.stairways.keyboardmaestro.editor)
      defaults write "$domain" NSUserKeyEquivalents '{
        "\033File\033Export Macros..." = "@~x";

        "\033View\033Enable Action" = "@~e";
        "\033View\033Disable Action" = "@~e";

        "\033Actions\033Try Action" = "@~k";
        "\033Actions\033Enable Action" = "@~e";
        "\033Actions\033Disable Action" = "@~e";
        "\033Actions\033Help" = "@~h";
      }'
      return 0;;
  
    # MUSIC.APP
    #
    # [⌘]+[Shift]+N   File > New > Playlist Folder
    # [^]+N                > N   > Playlist from Selection
    # [^]+L           Song > Love
    # [^]+D                > Dislike
    # [⌘]+[Shift]+L        > Show Album in Library
    # [⌘]+[Shift]+R   View > as Artists
    # [⌘]+[Shift]+B        > as Albums
    # [⌘]+[Shift]+S        > as Songs
    # [^]+[Shift]+P   Scrpt> Append to Selected Tag
    # [^]+[Shift]+H        > Search-Replace Tag Text
    # [^]+[Shift]+M        > Song Title to Movement
    # [^]+[Shift]+W        > Song Title to Work
    #
    com.apple.Music)
      defaults write "$domain" NSUserKeyEquivalents '{
        "\033File\033New\033Playlist Folder" = "@$n";
        "\033File\033New\033Playlist from Selection" = "^n";
        "\033Song\033Love" = "^l";
        "\033Song\033Dislike" = "^d";
        "\033Song\033Show Album in Library" = "@$l";
        "\033View\033as Artists" = "@$r";
        "\033View\033as Albums" = "@$b";
        "\033View\033as Songs" = "@$s";
        "\033Scripts\033Append to Selected Tag" = "^$p";
        "\033Scripts\033Search-Replace Tag Text" = "^$h";
        "\033Scripts\033Song Title to Movement" = "^$m";
        "\033Scripts\033Song Title to Work" = "^$w";
    }'
    ## removed, implemented in KM:
    ## # [⌘]+[⌥]+D            > Library > Show Duplicate|All Items
    ## "\033File\033Library\033Show Duplicate Items" = "@~d";
    ## "\033File\033Library\033Show All Items" = "@~d";

    return 0;;

    # PREVIEW
    #
    com.apple.Preview)
      defaults write "$domain" NSUserKeyEquivalents '{
        "\033File\033Move To..." = "@~s";
        "\033File\033Rename..." = "@~s";
      }'
      return 0;;
  
  # # OUTLOOK
  # com.microsoft.Outlook)
  #   defaults write "$domain" NSUserKeyEquivalents '{
  #     "\033Message\033Archive" = "@$e";
  #     "\033Tools\033Rules..." = "@$u";
  #   }'
  #   return 0;;

  # # PATINA
  # com.atek.Patina)
  #   defaults write "$domain" NSUserKeyEquivalents '{
  #     "\033Image\033Adjust Selection Size..." = "@~s";
  #   }'
  #   return 0;;

  # # TYPORA
  # abnerworks.Typora)
  #   defaults write "$domain" NSUserKeyEquivalents '{
  #   "\033Paragraph\033Ordered List" = "@$7";
  #   "\033Paragraph\033Unordered List" = "@$8";
  # }'
  #   return 0;;
  esac

  eecho "_write_one_domain: error: unrecognized domain: $domain"
  return 1
}

# Given $@ from the caller, determine if 0, 1 or 2 of the leading arguments are -v or -q,
# set the appropriate SH_ wrapper variable, and return as the status code the number of
# positions to shift.
#
# Example ussage: parse-verbose-quiet "$@" || shift $?
#
parse-verbose-quiet() {
  ((SH_VERBOSE)) && printf 'parse-verbose-quiet: start: \"%s\" $V=%s $Q=%s\n' "$*" $SH_VERBOSE $SH_QUIET
  [[ -z "$1" ]] && return 0
  
  local shift_count=0
  for opt in $1 $2; do
    if [[ "$opt" =~ ^(-v|--verbose)$ ]]; then
      SH_VERBOSE=1
      SH_QUIET=
      ((shift_count++))
    elif [[ "$opt" =~ ^(-q|--quiet)$ ]]; then
      SH_QUIET=1
      SH_VERBOSE=
      ((shift_count++))
    fi
  done
  
  ((SH_VERBOSE)) && printf 'parse-verbose-quiet: finish: $shift_count=%s $V=%s $Q=%s\n' $shift_count $SH_VERBOSE $SH_QUIET
  return $shift_count
}


# During sourcing, -d|--define or list, -l|--list, call the appropriate function.
_wrapper() {
  ((SH_VERBOSE)) && printf 'hotkeys.sh: start: "%s"\n' "$*"
  local opt_action="$1" && shift
  parse-verbose-quiet "$@" || shift $?
  if [[ "$opt_action" =~ ^(-d|(--)?define)$ ]]; then
    hotkeys-define "$@"
  elif [[ "$opt_action" =~ ^(-l|(--)?list)$ ]]; then
    hotkeys-list "$@"
  else
    eecho "Sourced hotkeys.sh; use hotkeys-define or hotkeys-list"
  fi
  ((SH_VERBOSE)) && printf 'hotkeys.sh: finish\n'
}
_wrapper "$@"
unset _wrapper
