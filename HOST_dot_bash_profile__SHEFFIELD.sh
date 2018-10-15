#!/usr/bin/env bash

# This file contains only shortcuts that will be useful at a typical command prompt and
# generally not used by more complex functions. Most are truly aliases but a few are shorter
# functions.
. ~/.__login.debug ".bash_profile_host_SHEFFIELD" || __echo() { :; }
__echo "[.bash_profile_host_SHEFFIELD] starting"


# Share login files among my different machines, since they're mostly alike.

alias jmxterm='java -jar $HOME/lib/jmxterm-1.0.0-uber.jar'

# Start the GUI for groovyConsole. Requires Java 1.7+.
function gconsole() {
    export JAVA_HOME="$(cd "$GROOVY_HOME/bin" || return 1; jenv javahome)"
    # nohup groovyConsole \
    #     --classpath "$( \
    #         find "$HOME/.groovy/lib" -name '*.jar'; \
    #         find "$HOME/.grails/ivy-cache" -name '*.jar' | grep -E -v '/ant|/grails|groovy|hibernate|spring|tomcat' \
    #     )" > /dev/null &
    nohup groovyConsole > /dev/null &
}

if [[ -f "$HOME/tom.sh" ]]; then
    alias t="\$HOME/tom.sh"
elif [[ -L "\$HOME/tom.sh" ]]; then
    alias t="\$(readlink "$HOME/tom.sh")"
fi


__echo "[.bash_profile_host_SHEFFIELD] finished"
