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

[[ -n "$SH_VERBOSE" ]] && echo "[.profile]"

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


if [[ "$(hostname -s)" = "TP_I-080-MBPRO" ]]; then

  PROMPT_COMMAND='[[ $? = 0 ]] && _prompt_symbol="\$" || _prompt_symbol="!\$"; history -a'
  # SHEFFIELD: ~ $ ls
  #export PS1='\h: \w $_prompt_symbol '
  # ~ $ ls
  export PS1='\w $_prompt_symbol '

  export PATH="/usr/local/mysql/bin:$PATH"

  # Homemade scripts, etc.
  export PATH="/opt/bin:$PATH"

  # Exclude from tab completion
  export FIGNORE='DS_Store:'

  if [[ -n "$(jenv version 2> /dev/null)" ]]; then
    [ -n "$SH_VERBOSE" ] && echo "Using jenv to set JAVA_HOME"
    eval "$(jenv init -)"
    export JAVA_HOME="$(jenv javahome)"
  else
    [ -n "$SH_VERBOSE" ] && echo "Using libexec to set JAVA_HOME"
    export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
    export PATH=$JAVA_HOME/bin:$PATH
  fi
  [ -n "$SH_VERBOSE" ] && echo "JAVA_HOME=$JAVA_HOME"


  export GROOVY_HOME="/opt/groovy"
  export PATH="$PATH:$GROOVY_HOME/bin"

  export GRAILS_HOME="/opt/grails"
  export PATH="$PATH:$GRAILS_HOME/bin"

  # export GRADLE_HOME=/opt/gradle-1.9
  # export PATH="$PATH:$GRADLE_HOME/bin"


  # # imagemagick 6.9.7.4 installed 1/18/2017; not symlinked into /usr/local by homebrew
  # export LDFLAGS="$LDFLAGS:-L/usr/local/opt/imagemagick@6/lib"
  # export CPPFLAGS="$CPPFLAGS:-I/usr/local/opt/imagemagick@6/include"
  # export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/opt/imagemagick@6/lib/pkgconfig"

fi


[[ -e "$HOME/.alias" ]] && . "$HOME/.alias"
