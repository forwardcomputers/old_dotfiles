#!/usr/bin/env zsh
#
powerline_precmd() {
    PS1="$( powerline-go )"
}
install_powerline_precmd() {
  for s in "${precmd_functions[@]}"; do
    if [ "$s" = "powerline_precmd" ]; then
      return
    fi
  done
  precmd_functions+=(powerline_precmd)
}
#
SAVEHIST=5000
HISTSIZE=2000
#
# history
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt CORRECT
#
# completions
FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
autoload -Uz compinit
compinit
# powerline
install_powerline_precmd
