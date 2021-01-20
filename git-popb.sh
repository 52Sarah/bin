#!/usr/bin/env bash

# Enhance git checkout with post-update hook, which pushes branch names into $git_dir/HEADS
# for this function to pop.
g.popb() {
  local git_dir="$(git rev-parse --git-dir)"
  
  if [[ ! -e "$git_dir/hooks/post-checkout" ]]; then
    echo 1>&2 "g.popb: git post-checkout hook not installed; adding now"
    ln -sv "$DOTFILES/dot_git_hooks/post-checkout" "$git-dir/" || return 1
  fi
  
  local heads="$git_dir/HEADS"
  [[ ! -s "$heads" ]] && echo 1>&2 "g.popb: no branches to pop" && return 1
  sed -i -e '$ d' "$heads"  # remove last line, which is current branch
  [[ ! -s "$heads" ]] && echo 1>&2 "g.popb: no branches to pop" && return 1

  export GITBR="$(tail -n 1 "$heads")"
  git checkout --quiet "$GITBR"
  git st
}
g.popb "$@"
