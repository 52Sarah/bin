#!/usr/bin/env bash

_wrapper() {

  img-hw() {
    [[ -z "$1" ]] && eecho "usage: img-hw file [...]" && return 0
    [[ "$1" =~ -d|--debug ]] && _DEBUG=1 && shift
    for f in $*; do
      [[ :$FIGNORE: =~ :${f/./}: ]] && continue
      printf '%-40s ' "$f:"
      file "$f" |\
        sed -E 's/, density [0-9]+x[0-9]+//;' |\
        sed -E 's/^([^:]*): .*[^0-9]([0-9]{2,}) ?x ?([0-9]{2,}).*$/\2x\3/;'
    done
  }

}
_wrapper
unset -f _wrapper