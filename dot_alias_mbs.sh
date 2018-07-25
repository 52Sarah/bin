#!/usr/bin/env bash
[ -n "$SH_VERBOSE" ] && echo "[.alias_mbs]"

if [[ "$(hostname -s)" = "SHEFFIELD" ]]; then

  export MBS="$HOME/svn/mbs"
  export MBS_OM="$HOME/svn/mbs/openmigrate/code"
  export MBS_OM_PROJECT="$HOME/svn/mbs/openmigrate/code/projects/clients/mbs/mbs-dropfolder-to-alfresco"
  export MBS_HPI="$HOME/svn/mbs/hpi/project/mbs"
  export MBS_OC_MODULE="$HOME/svn/mbs/opencontent/modules/clients/5.mbs"
  export MBS_OC_PROJECT="$HOME/svn/mbs/opencontent/projects/clients/mbs"
  export MBS_PEM="$MBS_OC_PROJECT/supporting/mbsadmin.pem"

  alias cd.mbs="cd \$MBS"
  alias cd.mbs.om="cd \$MBS_OM"
  alias cd.mbs.om.project="cd \$MBS_OM_PROJECT"
  alias cd.mbs.hpi="cd \$MBS_HPI"
  alias cd.mbs.oc.module="cd \$MBS_OC_MODULE"
  alias cd.mbs.oc.project="cd \$MBS_OC_PROJECT"
  alias cd.mbs.home="cd \$MBS_OC_PROJECT/supporting/HOME"

  alias cd.mps='cd $HOME/Drive/clients/mps'
fi
