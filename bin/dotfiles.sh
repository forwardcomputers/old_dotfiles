#!/bin.bash
#
git clone --recursive https://github.com/forwardcomputers/dotfiles.git tmpgit
mv tmpgit/.git .
rm -rf tmpgit
git reset --hard
git remote set-url origin ssh://git@github.com/forwardcomputers/dotfiles.git
#
