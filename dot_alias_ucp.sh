#!/usr/bin/env bash
[ -n "$SH_VERBOSE" ] && echo "[.alias_ucp]"

if [[ "$(hostname -s)" = "SHEFFIELD" ]]; then

  export UCP_SVN="$HOME/svn/ucp"
  alias ucp.cd.svn="cd \"\$UCP_SVN\""

  export UCP_WORK="$HOME/work/ucp-work"
  alias ucp.cd.work="cd \"\$UCP_WORK\""

  export UCP_CLIENT="$HOME/Drive/clients/ucp"
  alias ucp.cd="cd \"\$UCP_CLIENT\""


  # Derive proper environment URL prefix from $1 (dev, staging, www), echo it and export UCP_ENV
  # with the proper value. If we can't figure it out, default to dev and return status 1.
  ucp.setenv() {
    local status=0
    UCP_ENV="${1^^}"
    [[ -z "$UCP_ENV" ]] && UCP_ENV="DEV" && status=1
    case "$UCP_ENV" in
      P* | WWW )  UCP_ENV="www";;
      S* )        UCP_ENV="staging";;
      D* )        UCP_ENV="dev";;
      *)          UCP_ENV="dev"; status=1;;
    esac
    export UCP_ENV
    echo "$UCP_ENV"
    return $status
  }

  # Set branch to $1 if specified; else use PWD. If not in an svn working copy, default to trunk.
  # : ${UCP_SVN_BRANCH:=trunk}
  ucp.svn.branch() {
    local old_SVN_BRANCH="$SVN_BRANCH"
    unset SVN_BRANCH
    while [ -n "$1" ]; do
      case "$1" in
        -q|--quiet )    local SH_QUIET=1; unset SH_VERBOSE  ;;
        -v|--verbose )  local SH_VERBOSE=1; unset SH_QUIET  ;;
        -* )            eecho "ERROR: Unexpected switch: '$1'" && return 1  ;;
        * )             export SVN_BRANCH="$1"  ;;
      esac
      shift
    done
    : "${SVN_BRANCH:=${old_SVN_BRANCH}}"
    : "${SVN_BRANCH:=trunk}"
    iecho_vars SVN_BRANCH

    local try_UCP_ALFLIFE_WC="$UCP_SVN/ucp-alfresco-liferay/$SVN_BRANCH"
    [ -d "$try_UCP_ALFLIFE_WC" ] && export UCP_ALFLIFE_WC="$try_UCP_ALFLIFE_WC" || eecho "WARNING: Invalid branch: $try_UCP_ALFLIFE_WC"
    iecho_vars --home UCP_ALFLIFE_WC
    export UCP_ALF="$UCP_ALFLIFE_WC/alfresco"
    export UCP_ALF_WEBSCRIPTS="$UCP_ALF/alfresco-extension/templates/webscripts/com/tsgrp"
    export UCP_LIFE="$UCP_ALFLIFE_WC/liferay"
    vecho_vars --home UCP_ALF UCP_ALF_WEBSCRIPTS UCP_LIFE

    local try_UCP_MYINFINITEC_WC="$UCP_SVN/ucp-myinfinitec/$SVN_BRANCH"
    [ -d "$try_UCP_MYINFINITEC_WC" ] && export UCP_MYINFINITEC_WC="$try_UCP_MYINFINITEC_WC" || eecho "WARNING: Invalid branch: $try_UCP_MYINFINITEC_WC"
    iecho_vars --home UCP_MYINFINITEC_WC
    export UCP_ENGAGE="$UCP_MYINFINITEC_WC/usermanagement"
    export UCP_MYINF_SSL_KEYS="$UCP_MYINFINITEC_WC/ssl-keys"
    export UCP_PRODUCTION_PEM="$UCP_MYINF_SSL_KEYS/UCPProduction.pem"
    export UCP_STAGING_PEM="$UCP_MYINF_SSL_KEYS/UCPStaging.pem"
    vecho_vars --home UCP_MYINF_SSL_KEYS UCP_PRODUCTION_PEM UCP_STAGING_PEM

    export UCP_INFINITEXT_WC="$UCP_SVN/ucp-infinitext"
    iecho_vars --home UCP_INFINITEXT_WC
    export UCP_INFINITEXT_SSL_KEYS="$UCP_INFINITEXT_WC/ssl-keys"
    export UCP_INFINITEXT_PEM="$UCP_INFINITEXT_SSL_KEYS/ucp_infinitext_prod_2017.pem"
    vecho_vars --home UCP_ENGAGE UCP_INFINITEXT_SSL_KEYS UCP_INFINITEXT_PEM

    function ucp.cd.alflife.wc()       { ucp.svn.branch --quiet; cd "$UCP_ALFLIFE_WC"; }
    function ucp.cd.alf()              { ucp.svn.branch --quiet; cd "$UCP_ALF"; }
    function ucp.cd.alf.webscripts()   { ucp.svn.branch --quiet; cd "$UCP_ALF_WEBSCRIPTS"; }
    function ucp.cd.webscripts()       { ucp.cd.alf.webscripts; }
    function ucp.cd.life()             { ucp.svn.branch --quiet; cd "$UCP_LIFE"; }
    function ucp.cd.life.portlets()    { ucp.svn.branch --quiet; cd "$UCP_LIFE/portlets"; }
    function ucp.cd.portlets()         { ucp.cd.life.portlets; }
    function ucp.cd.life.hook()        { ucp.svn.branch --quiet; cd "$UCP_LIFE/hooks/ucp-hook"; }
    function ucp.cd.hook()             { ucp.cd.life.hook; }
    function ucp.cd.life.theme()       { ucp.svn.branch --quiet; cd "$UCP_LIFE/thems/ucp-theme"; }
    function ucp.cd.theme()            { ucp.cd.life.theme; }
    function ucp.cd.myinfinitec.wc()   { ucp.svn.branch --quiet; cd "$UCP_MYINFINITEC_WC"; }
    function ucp.cd.engage()           { ucp.svn.branch --quiet; cd "$UCP_ENGAGE"; }
    function ucp.cd.infinitext.wc()    { ucp.svn.branch --quiet; cd "$UCP_INFINITEXT_WC"; }
    [ -n "$SH_VERBOSE" ] && declare -F | grep -E -o 'ucp\.cd\..*'

    function ucp.tunnel.dev()          { ssh -v -NC -i "$UCP_STAGING_PEM" ubuntu@dev.myinfinitec.org -L "${1:-3306}:localhost:${2:-${1:-3306}}"; }
    function ucp.tunnel.staging()      { ssh -v -NC -i "$UCP_STAGING_PEM" ubuntu@staging.myinfinitec.org -L "${1:-3306}:localhost:${2:-${1:-3306}}"; }
    function ucp.tunnel.prod()         { ssh -v -NC -i "$UCP_PRODUCTION_PEM" ubuntu@www.myinfinitec.org -L "${1:-3306}:localhost:${2:-${1:-3306}}"; }
    alias ucp.tunnel.db.dev='ucp.tunnel.dev 3306'
    alias ucp.tunnel.db.staging='ucp.tunnel.staging 3306'
    alias ucp.tunnel.db.prod='ucp.tunnel.prod 3306'
    alias ucp.tunnel.jmx.prod='ucp.tunnel.prod 50500'
    [ -n "$SH_VERBOSE" ] && declare -F | grep -E -o 'ucp\.tunnel\..+'

    alias ucp.i='bash $HOME/infinitec.sh'
    alias ucp.refresh='~/svn/tsg-alfresco-scripts/webscripts/ucp/ucp-refresh.sh'
    alias ucp.find='~/svn/tsg-alfresco-scripts/webscripts/ucp/ucp-find.sh'
    alias ucp.test='~/svn/tsg-alfresco-scripts/webscripts/ucp/ucp-test-myinfinitec.sh'
    alias ucp.up='~/svn/tsg-alfresco-scripts/bash/up.sh'
    [ -n "$SH_VERBOSE" ] && alias ucp.i ucp.refresh ucp.test | grep -E -o 'ucp\..+'

      # Change current directory if we started inside the old branch
    #vecho_vars old_SVN_BRANCH SVN_BRANCH PWD
    if [ -n "$old_SVN_BRANCH" ] && [ "$old_SVN_BRANCH" != "$SVN_BRANCH" ] && [[ "$PWD" =~ .+/$old_SVN_BRANCH.* ]]; then
      local new_dir="${PWD/\/$old_SVN_BRANCH/\/$SVN_BRANCH}"
      #vecho_vars new_dir
      [ -d "$new_dir" ] && vecho_and_eval "cd \"$new_dir\""
    fi
  }
  alias ucp.branch='ucp.svn.branch'
  ucp.svn.branch --quiet ucp-olc-2017

fi
