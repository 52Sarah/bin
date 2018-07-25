#!/usr/bin/env bash

. "$HOME/.functions"

# $1 is the desired location of the link; $2 is the desired location of the physical file
# Optional switch before $1: --force will overwrite target file if it exists
mv_and_link_one() {
    local do_force=
    [[ "$1" =~ --?f(orce)? ]] && do_force=1 && shift && vecho "Force mode enabled."
    local link="$1"
    local file="$2"

    [[ ! -e "$link" ]] && eecho "File not found: $link" && return 1
    [[ "$(readlink "$link")" = "$file" ]] && iecho "Skipping $link" && return 1
    [[ -L "$link" ]] && vecho "$link is a link pointing to $(readlink "$link"); target link cannot start as a link" && return 1

    vecho_vars link file do_force
    [[ -n "$do_force" ]] && mv -vf "$link" "$file" || mv -vn "$link" "$file"
    [[ -n "$do_force" ]] && ln -svf "$file" "$link" || ln -sv "$file" "$link"
}

# DIR="$HOME/Dropbox/dotfiles"

# [[ "$(readlink $HOME/.alias)" != "$DIR/dot_alias.sh" ]] && ln -sfv $DIR/dot_alias.sh $HOME/.alias
# [[ "$(readlink $HOME/.alias_ucp)" != "$DIR/dot_alias_ucp.sh" ]] && ln -sfv $DIR/dot_alias_ucp.sh ~/.alias_ucp
# [[ "$(readlink $HOME/.bash_profile)" != "$DIR/dot_bash_profile.sh" ]] && ln -sfv $DIR/dot_bash_profile.sh ~/.bash_profile
# [[ "$(readlink $HOME/.bashrc)" != "$DIR/dot_bashrc.sh" ]] && ln -sfv $DIR/dot_bashrc.sh ~/.bashrc
# [[ "$(readlink ~/.functions)" != "$DIR/dot_functions.sh" ]] && ln -sfv $DIR/dot_functions.sh $HOME/.functions
# [[ "$(readlink $HOME/.profile)" != "$DIR/dot_profile.sh" ]] && ln -sfv $DIR/dot_profile.sh ~/.profile


DIR="$HOME/Dropbox/dotfiles/sublime"
APPDIR="$HOME/Library/Application Support/Sublime Text 3/Packages/User"

for filename in 'FileDiffs' 'MarkdownPreview' 'MultiMarkdown' 'Preferences' 'Side Bar' 'SublimeLinter' 'SyncedSideBar'; do
    mv_and_link_one --force "$APPDIR/$filename.sublime-settings" "$DIR/$filename.sublime-settings"
done


filename="Monokai Pro (Filter Spectrum) (SL).tmTheme"
mv_and_link_one --force "$APPDIR/SublimeLinter/$filename" "$DIR/$filename"


APPDIR="$HOME/Library/Application Support/Sublime Text 3/Packages/Predawn"

filename="predawn.tmTheme"
mv_and_link_one --force "$APPDIR/$filename" "$DIR/$filename"
