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

shopt -s extglob

wrapper() {
  # eecho "wrapper: debug: #:${#*}, @:[$@]"
  local opt_verbose="$SH_VERBOSE" opt_quiet="$SH_QUIET"

  local ALL_DOMAINS="$(
    tr -s ' ' <<<'
      global
      calendar
      contacts
      finder
      music
      beyondcompare
      excel
      keyboardmaestro
    ' | tr -d '\n'
  )"

  # usage: hotkeys-list [-v] [-q] [domain]
  hotkeys-list() {
    # eecho "hotkeys-list: debug: #:${#*}, @:[$@]"
    parse-verbose-quiet "$@" || shift $?

    local abbrevs="$@"
    local target_domains="${@:-$ALL_DOMAINS}"

    local d full_domain d_total=0 d_count=0
    for d in $target_domains; do
      # eecho "hotkeys-list: info: d_total=$d_total, d_count=$d_count, d=[$d]"
      ((d_total++))
      full_domain="$(hotkeys-domain "$d")"
      hotkeys-read-domain "$full_domain" && ((d_count++))
    done

    ((d_count < d_total)) && eecho "hotkeys-list: error: only listed hotkeys for $d_count/$d_total domains" && return 1
    return 0
  }


  # Given $1 is a valid defaults domain, read/list its hotkeys and return 0; else return 1.
  hotkeys-read-domain() {
    local domain="${1//_/ }" && shift
    [[ -z "$domain" ]] && eecho "usage: hotkeys-read-domain domain" && return 1
    # eecho "hotkeys-read-domain: info: domain=[$domain]"

    printf "\n%s\n" "${domain}"
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
    awk -F '=' '{ printf "%-50s %s\n", $1, substr($2,1,length($2)-1) toupper(substr($2,length($2))); }'
  }


  # usage: hotkeys-define [-v] [-q] [domain...]
  hotkeys-define() {
    # eecho "hotkeys-define: debug: #:${#*}, @:[$@]"
    parse-verbose-quiet "$@" || shift $?

    local abbrevs="$@"
    local target_domains="${@:-$ALL_DOMAINS}"

    local d full_domain d_total=0 d_count=0
    for d in $target_domains; do
      # eecho "hotkeys-define: info: d_total=$d_total, d_count=$d_count, d=[$d]"
      ((d_total++))
      full_domain="$(hotkeys-domain "$d")"
      if hotkeys-write-domain "$full_domain"; then
        ((d_count++))
        ((!opt_quiet)) && hotkeys-list "$full_domain"
      fi
    done

    ((d_count == 0)) && eecho "hotkeys-define: error: all $d_total_domains hotkey domains failed" && return 1
    local sw_verbose= && ((opt_verbose)) && sw_verbose='-v'
    killall $sw_verbose cfprefsd
    ((d_count < d_total)) && eecho "hotkeys-define: error: only defined hotkeys for $d_count/$d_total domains" && return 1
    return 0
  }

  # Given $1 is a valid defaults domain, define its hotkeys and return 0; else return 1.
  # For the rare domains with spaces in their names, replace underscores with spaces.
  hotkeys-write-domain() {
    local domain="${1//_/ }" && shift
    [[ -z "$domain" ]] && eecho "usage: hotkeys-write-domain domain" && return 1
    # eecho "hotkeys-write-domain: info: domain=[$domain]"

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
          "\033Window\033Tile Window to Left of Screen" = "~^[";
          "\033Window\033Tile Window to Right of Screen" = "~^]";
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

          "\033Search\033Next Difference" = "\\Uf70a";
          "\033Search\033Previous Difference" = "$\\Uf70a";
        }'
        return 0;;

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
      # [^]+N           F    > N   > Playlist from Selection
      # [^]+L           Song > Love
      # [^]+D           S    > Dislike
      # [⌘]+[Shift]+L   S    > Show Album in Library
      # [⌘]+[Shift]+R   View > as Artists
      # [⌘]+[Shift]+B   V    > as Albums
      # [⌘]+[Shift]+S   V    > as Songs
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

    eecho "hotkeys-write-domain: error: unrecognized domain: $domain"
    return 1
  }

  # Given $1...
  # - abbreviation for app's domain, return full NSUserKeyEquivalents domain string
  # - blank, return blank
  # - unrecognized abbreviation, $1 as-is
  hotkeys-domain() {
    [[ -z "$1" ]] && return 0

    local domain

    local abb="$1" && shift
    case "$abb" in
      nsglobaldomain | n?(s)gd | ngd | appleglobaldemain | agd | glo*)
        domain='NSGlobalDomain';;
      beyondcompare | bc*)
        domain='com.ScooterSoftware.BeyondCompare';;
      ?(i)calendar | ?(i)cal*)
        domain='com.apple.iCal';;
      contacts | con* | addresses | add*)
        domain='com.apple.contacts';;
      excel | exc*)
        domain='com.microsoft.Excel';;
      finder | fin*)
        domain='com.apple.finder';;
      keyboardmaestro | km* | key*)
        domain='com.stairways.keyboardmaestro.editor';;
      music | mus* | itunes)
        domain='com.apple.Music';;
      # outlook | out*)
      #   domain='com.microsoft.Outlook';;
      # patina | pat*)
      #   domain='com.atek.Patina';;
      # typora | typ*)
      #   domain='abnerworks.Typora';;
      *)
        ((opt_verbose)) && eecho "hotkeys-domain: warning: unrecognized domain abbreviation: [$abb]; passing thru"
        domain="$abb";;
    esac
    
    echo "$domain"
    return 0
  }

  # Given $@ from the caller, determine if 0, 1 or 2 of the leading arguments are -v or -q,
  # set the appropriate opt_ wrapper variable, and return as the status code the number of
  # positions to shift.
  parse-verbose-quiet() {
    # eecho "parse-verbose-quiet: debug: #:${#*}, @:[$@]"
    local shift_count=0
    [[ -z "$1" ]] && return $shift_count

    for opt in $1 $2; do
      if [[ "$opt" =~ ^--?v(erbose)?$ ]]; then
        opt_verbose=1
        opt_quiet=
        ((shift_count++))
      elif [[ "$opt" =~ ^--?q(uiet)?$ ]]; then
        opt_quiet=1
        opt_verbose=
        ((shift_count++))
      fi
    done

    # eecho "parse-verbose-quiet: info: opt_verbose=[$opt_verbose], opt_quiet=[$opt_quiet], shift_count=[$shift_count]"
    return $shift_count
  }

  eecho() { >&2 echo $@; return 0; }

  if [[ "$1" =~ ^-{0,2}d ]]; then
    shift
    hotkeys-define "$@"
  elif [[ "$1" =~ ^-{0,2}l ]]; then
    shift
    hotkeys-list "$@"
  else
    eecho "Only sourced hotkeys.sh; execute hotkeys-define or hotkeys-list."
  fi

}
wrapper "$@"
