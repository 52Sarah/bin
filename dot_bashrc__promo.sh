#!/usr/bin/env bash

# This file contains Eversight (promolytics) specific items.
. ~/.__login.debug ".bashrc__promo" || __echo() { :; }
__echo "[.bashrc__promo] starting; pid: $$, shell type: $(__shell_type), PS1='$PS1'"


# MySQL
export MYSQL_HOME="/usr/local/Cellar/mysql@5.7/5.7.23"
export PATH="$MYSQL_HOME/bin:$PATH"


# Java JDK 1.8
if [[ -n "$(jenv version 2> /dev/null)" ]]; then
    eval "$(jenv init -)"
    export JAVA_HOME="$(jenv javahome)"
    __echo "[.bashrc__promo] used jenv to set JAVA_HOME"
else
    export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
    export PATH="$JAVA_HOME/bin:$PATH"
    __echo "[.bashrc__promo] used /usr/libexec to set JAVA_HOME"
fi
__echo "[.bashrc__promo] JAVA_HOME=$JAVA_HOME"


# Node.js
export NVM_DIR="$HOME/.nvm"
export NODE_LIB="$NVM_DIR/versions/node/v6.11.0/lib/node_modules/"
export NODE_PATH="$NODE_LIB:$NODE_PATH"
#echo "!!! SKIPPING . nvm.sh"
. "/usr/local/opt/nvm/nvm.sh"
## __echo "[.bashrc__promo] Node version: $(nvm current)"


# phantomjs and mochajs
export PHANTOMJS_HOME="$NODE_LIB/mocha-phantomjs" 
export PATH="$PATH:$PHANTOMJS_HOME/bin"
export MOCHAPHANTOMJS_HOME="$NODE_LIB/mocha-phantomjs"
export PATH="$PATH:$MOCHAPHANTOMJS_HOME/bin"


# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# Load RVM into a shell session *as a function*
export RVM_HOME="$HOME/.rvm"
export PATH="$PATH:$RVM_HOME/bin"
[[ -s "$RVM_HOME/scripts/rvm" ]] && source "$RVM_HOME/scripts/rvm"


# Inkscape
export PATH="$PATH:/Applications/Inkscape.app/Contents/Resources/bin"


# Google Cloud SDK including command completion
[[ -e "$HOME/google-cloud-sdk/path.bash.inc" ]] && . "$HOME/google-cloud-sdk/path.bash.inc"
[[ -e "$HOME/google-cloud-sdk/completion.bash.inc" ]] && . "$HOME/google-cloud-sdk/completion.bash.inc"


# My convenience variables and aliases.

export PROMO_HOME="$HOME/git/promolytics"
export CAMPAIGN_JAVA="$PROMO_HOME/server/campaign/src/main/java"

export PROMO_DB_PROPERTIES="$PROMO_HOME/deploy/promolytics/src/main/webapp/WEB-INF/classes/database.properties"
export PROMO_LOG="$PROMO_HOME/_stage/apache-tomcat-7.0.35/logs/promolytics.log"

export MYSQL_DATA="/usr/local/var/mysql"
export MYSQL_LOG="$MYSQL_DATA/TPI-080-MBPRO.local.err"

alias promo.cd='cd "$PROMO_HOME"'
alias promo.cd.campaign='cd "$CAMPAIGN_JAVA"'
alias promo.log.tail='iecho_and_eval "tail -n 100 -f "$PROMO_LOG""'


__echo "[.bashrc__promo] finished"
