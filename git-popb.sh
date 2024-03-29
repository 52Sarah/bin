#!/usr/bin/env bash

# Enhance git checkout with post-update hook, which pushes branch names into $git_dir/HEADS
# for this function to pop.
g.popb() {
  local git_dir="$(git rev-parse --git-dir)"
  vecho "git_dir: [$git_dir]"

  local hooks_dir="$(git config --get core.hooksPath)"
  # local hooks_dir="$(tilde_expand "$hooks_dir")"
  [[ -z "$hooks_dir" || ! -e "$hooks_dir/post-checkout" ]] && hooks_dir="$git_dir/hooks"

  [[ ! -e "$hooks_dir/post-checkout" ]] && echo 1>&2 "g.popb: git post-checkout hook not found in $hooks_dir" && return 1
  
  local heads="$git_dir/HEADS"
  [[ ! -s "$heads" ]] && echo 1>&2 "g.popb: no branches to pop" && return 1
  sed -i -e '$ d' "$heads"  # remove last line, which is current branch
  [[ ! -s "$heads" ]] && echo 1>&2 "g.popb: no branches to pop" && return 1

  export GIT_BRANCH="$(tail -n 1 "$heads")"
  git checkout --quiet "$GIT_BRANCH"
  git st
}

vecho() {
  ((_VERBOSE)) && echo "$*"
}

g.popb $@
