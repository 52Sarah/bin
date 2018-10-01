#!/usr/bin/env bash

# Bash reads .bash_profile || .bash_login || .profile, whichever it finds first,
# for interactive shells. Since there's nothing bash-specific in .profile (as far as I know),
# I will put all non-interactive-ish commands into .bashrc (called by non-interactive shells) and
# have it source .bashrc.
#
# https://apple.stackexchange.com/a/13019/39935


. "$HOME/.__login.debug.sh" ".bashrc" || __echo() { :; }
__echo "[.bashrc] starting, PATH=$PATH"


# Share login files among my different machines, since they're mostly alike.
if [[ "$(hostname -s)" = "TPI-080-MBPRO" ]]; then

  # MySQL
  export PATH="/usr/local/Cellar/mysql@5.7/5.7.23/bin:$PATH"

  # Java JDK 1.8
  if [[ -n "$(jenv version 2> /dev/null)" ]]; then
    eval "$(jenv init -)"
    export JAVA_HOME="$(jenv javahome)"
    __echo "[.bashrc] used jenv to set JAVA_HOME"
  else
    export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
    export PATH=$JAVA_HOME/bin:$PATH
    __echo "[.bashrc] used /usr/libexec to set JAVA_HOME"
  fi
  __echo "[.bashrc] JAVA_HOME=$JAVA_HOME"

  # Node.js
  export NVM_DIR="$HOME/.nvm"
  . "$NVM_DIR/nvm.sh"
  . "$NVM_DIR/bash_completion"
  export NODE_LIB="$HOME/.nvm/versions/node/v6.11.0/lib/node_modules/"
  export PATH="$PATH:$NODE_LIB"
  __echo "[.bashrc] Node version: $(nvm current)"

  # phantomjs and mochajs
  export PHANTOMJS_HOME="$NODE_LIB/phantomjs" 
  export PATH="$PATH:$PHANTOMJS_HOME/bin"
  export MOCHAPHANTOMJS_HOME="$NODE_LIB/mocha-phantomjs"
  export PATH="$PATH:$MOCHAPHANTOMJS_HOME/bin"

  # Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
  # Load RVM into a shell session *as a function*
  export PATH="$PATH:$HOME/.rvm/bin"
  [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

  # Inkscape
  export PATH="$PATH:/Applications/Inkscape.app/Contents/Resources/bin"
  
fi


# Put my homemade scripts and other miscellany here at the end of the classpath.
[[ -d "/opt/bin" ]] && export PATH="$PATH:/opt/bin"


for dotfile in .bash_functions .bash_aliases; do
	__echo "[.bashrc] sourcing $dotfile"
	. "$HOME/$dotfile"
done


__echo "[.bashrc] finished"
