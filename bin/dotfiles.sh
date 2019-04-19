#!/bin.bash
#
git clone --recursive https://github.com/forwardcomputers/dotfiles.git tmpgit
mv tmpgit/.git .
rm -rf tmpgit
git reset --hard
git remote set-url origin ssh://git@github.com/forwardcomputers/dotfiles.git
#
if [[ $(uname -s) == "Darwin" ]]; then
    ln -sf ~/.config/vim ~/Library/Preferences
    ln -sf ~/.config/git ~/Library/Preferences
    ln -sf ~/.config/tmux ~/Library/Preferences
    #
    [[ -d ~/Library/bash ]] || mkdir ~/Library/bash
    [[ -d ~/Library/Fonts ]] && (chmod -N ~/Library/Fonts && rm -rf ~/Library/Fonts && ln -sf ~/.local/share/fonts ~/Library/Fonts)
fi
#