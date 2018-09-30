#!/usr/bin/env bash
#
# shellcheck disable=1090,2009,2155
#
# SublimeLinter/ShellCheck excluded issues; see https://github.com/koalaman/shellcheck/wiki/Ignore
# - 1090 (https://github.com/koalaman/shellcheck/wiki/SC1090): Can't follow non-constant source.
#        Use a 'source' directive to specify location.
# - 2009 (https://github.com/koalaman/shellcheck/wiki/SC2009): Consider using pgrep instead of
#        grepping ps output.
# - 2015 (https://github.com/koalaman/shellcheck/wiki/SC2015): Note that A && B || C is not
#        if-then-else. C may run when A is true.
# - 2154 (https://github.com/koalaman/shellcheck/wiki/SC2154): var is referenced but not assigned.
# - 2155 (https://github.com/koalaman/shellcheck/wiki/SC2155): Declare and assign separately to
#        avoid masking return values.

# For debugging via . ~/.profile --debug, incoming SH_DEBUG=1, or existence of ~/.login_debug
[[ "$1" == "--debug" || -e "$HOME/.profile.debug" ]] && __PROFILE_DEBUG=1
__echo() { [[ -n "$__PROFILE_DEBUG" ]] && echo "$@"; return 0; }

__echo "[.profile] starting"


[[ -e "${HOME}/.iterm2_shell_integration.bash" ]] && source "${HOME}/.iterm2_shell_integration.bash"

set -o vi
export EDITOR=vim
export CLICOLOR=true


# WHen closing a session, add to history instead of overwriting
shopt -s histappend

shopt -s cdspell

# Store multi-line commands as one line in history
shopt -s cmdhist


# Ignore repeated lines and lines starting with ' '
export HISTCONTROL='ignoreboth'

# Number of entries to keep in history
export HISTSIZE=100000
export HISTFILESIZE=${HISTSIZE}

# Show full date, time at beginning of each line
export HISTTIMEFORMAT=' %F %T  '


# If last command was in error, display !$ instead of $.
# history -a flushes the session history to the history file
export PROMPT_COMMAND='(($?)) && _prompt_symbol="!\$" || _prompt_symbol="\$"; history -a'
# \u = user
# \h = hostname
# \w = working dir
# myinf-prod: ubuntu: ~ $
export PS1='\h:\u \w $_prompt_symbol '


if [[ "$(hostname -s)" = "TPI-080-MBPRO" ]]; then

  PROMPT_COMMAND='[[ $? = 0 ]] && _prompt_symbol="\$" || _prompt_symbol="!\$"; history -a'
  # SHEFFIELD: ~ $ ls
  #export PS1='\h: \w $_prompt_symbol '
  # ~ $ ls
  export PS1='\w $_prompt_symbol '


  # MySQL
  export PATH="/usr/local/Cellar/mysql@5.7/5.7.23/bin:$PATH"

  # Java JDK 1.8
  if [[ -n "$(jenv version 2> /dev/null)" ]]; then
    eval "$(jenv init -)"
    export JAVA_HOME="$(jenv javahome)"
    __echo "[.profile] used jenv to set JAVA_HOME"
  else
    export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
    export PATH=$JAVA_HOME/bin:$PATH
    __echo "[.profile] used /usr/libexec to set JAVA_HOME"
  fi
  __echo "[.profile] JAVA_HOME=$JAVA_HOME"

  # Node
  export NVM_DIR="$HOME/.nvm"
  . "$NVM_DIR/nvm.sh"
  . "$NVM_DIR/bash_completion"
  export NODE_LIB="$HOME/.nvm/versions/node/v6.11.0/lib/node_modules/"
  export PATH="$PATH:$NODE_LIB"
  __echo "[.profile] Node version: $(nvm current)"

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
  

  # export GROOVY_HOME="/opt/groovy"
  # export PATH="$PATH:$GROOVY_HOME/bin"

  # export GRAILS_HOME="/opt/grails"
  # export PATH="$PATH:$GRAILS_HOME/bin"

  # export GRADLE_HOME=/opt/gradle-1.9
  # export PATH="$PATH:$GRADLE_HOME/bin"

  # Exclude from tab completion
  export FIGNORE='DS_Store:'

fi


[[ -e "$HOME/.alias" ]] && __echo "[.profile] sourcing .alias" && . "$HOME/.alias"


__echo "[.profile] finished"
