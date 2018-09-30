# dotfiles README


### bin <- /usr/local/bin

This folder contains utility scripts intended to be invoked from the command line. It should be in the PATH, so it makes sense to swap it in for /usr/local/bin in many cases.

```bash
cd /usr/local
sudo mv -nv bin binx
sudo ln -sv /Users/toddpierzina/Drive/bin ./

## for f in binx/*; do sudo mv -v $f bin/; done
MozyProBackup@ -> /Library/PreferencePanes/MozyPro.prefPane/Contents/Resources/MozyProBackup
brew@ -> /usr/local/Homebrew/bin/brew
gradle@ -> ../Cellar/gradle/4.10.2/bin/gradle

sudo rm -r binx
```

### iterm2
iTerm's preferences (General tab) has a custom preferences folder in the lower right.
Set it to: $HOME/Drive/dotfiles/iterm2


### keyboardmaestro
The app has a "sync" setting which should point to this file: Keyboard Maestro Macros.kmsync


### sublime
Link /Library/Application Support/Sublime Text 3/Packages/User to PACKAGES_USER.
```bash
ln -s -F -v "$HOME/Drive/dotfiles/sublime/PACKAGES_USER" "$HOME/Library/Application Support/Sublime Text 3/Packages/User"
```

### Preferences/

```bash
mv_and_ln $HOME/Drive/dotfiles/iterm2/com.googlecode.iterm2.plist $HOME/Library/Preferences/com.googlecode.iterm2.plist 
```





To do so: