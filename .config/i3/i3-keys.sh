#!/bin/bash
#
convert -size 1000x1000 xc:black -fill white -font "${HOME}/.local/share/fonts/DejaVu Sans Mono for Powerline.ttf" -pointsize 14 -draw "text 10,10 '$( \
   awk '/^set \$mod/ {modi=$3}; /^bindsym/ {sub(/;.*/,""); sub(/\$mod/,modi); sub(/\$alt/,"Alt"); printf "%-30s", $2; for (i=3; i<=NF; i++) {printf " %s", $i}; printf "\n"}' < ${HOME}/.config/i3/config )'" \
  -trim -bordercolor black -border 20 +repage png:- |
  feh -x --no-menus --title "keys" -
