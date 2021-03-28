#!/usr/bin/env bash
# shellcheck disable=SC2009,SC2155
# shellcheck source=/dev/null
#set -x

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
#
# Functions
#
# Is command a docker app
command_not_found_handle () {
  if [[ -d /media/filer/os/dockerfiles/"${1}" ]]; then
    "${HOME}"/bin/dapp run "$@"
  else
    if [ -x /usr/lib/command-not-found ]; then
      /usr/lib/command-not-found -- "$1"
      return $?;
    else
      if [ -x /usr/share/command-not-found/command-not-found ]; then
        /usr/share/command-not-found/command-not-found -- "$1"
        return $?
      else
        printf "%s: command not found\\n" "$1" 1>&2
        return 127
      fi;
    fi
  fi
}
# Start ssh agent function
start_agent () {
  /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
  chmod 600 "${SSH_ENV}"
  . "${SSH_ENV}" > /dev/null
  get_ssh_key
}
#
get_ssh_key () {
  # Add existing private keys to ssh agent
  SSH_ADD_OPT="-K"
  if ls "${HOME}"/.ssh/LP* 1> /dev/null 2>&1; then
    # shellcheck disable=SC2038,SC2061
    for LP_ID in $( find "${HOME}"/.ssh -type f -name LP* | xargs -IZ basename Z | cut -d"." -f1 | uniq ); do
      LP_ID=${LP_ID#$HOME/.ssh/}
      LP_KEY_NAME="${HOME}/.ssh/${LP_ID}"
      LP_KEY_PASS=$(lpass show "${LP_ID}" --password)
      add_key_to_ssh_agent
    done
  else
    # Populate private keys from LastPass and add to ssh agent
    echo "AddKeysToAgent yes" > "${HOME}"/.ssh/config
    echo "#ForwardX11 yes" >> "${HOME}"/.ssh/config
    # for LP_ID in $(lpass ls --format %an LP_login | sed '1d'); do
    for LP_ID in $(lpass ls -m LP_login | awk -F'[/ ]' '{print $2}' | sed '1d'); do
      lpass show "${LP_ID}" --field=pri > "${HOME}/.ssh/${LP_ID}"
      chmod 600 "${HOME}/.ssh/${LP_ID}"
      echo "IdentityFile ${HOME}/.ssh/${LP_ID}" >> "${HOME}"/.ssh/config
      LP_KEY_NAME="${HOME}/.ssh/${LP_ID}"
      LP_KEY_PASS=$(lpass show "${LP_ID}" --password)
      add_key_to_ssh_agent
    done
  fi
}
add_key_to_ssh_agent () {
  expect 2>/dev/null <<-EOF >/dev/null
    spawn ssh-add ${SSH_ADD_OPT} ${LP_KEY_NAME}
    expect "Enter passphrase"
    send "${LP_KEY_PASS}\\n"
    expect eof
EOF
}
#
git_delete_history () {
  git checkout --orphan TEMP_BRANCH
  git add -A
  git commit -am "Initial commit"
  git branch -D master
  git branch -m master
  git push -f origin master
}
# readlink -f for osx - works for linux
readlinkf() {
  # from https://github.com/ko1nksm/readlinkf
  [ "${1:-}" ] || return 1
  max_symlinks=40
  CDPATH='' # to avoid changing to an unexpected directory

  target=$1
  [ -e "${target%/}" ] || target=${1%"${1##*[!/]}"} # trim trailing slashes
  [ -d "${target:-/}" ] && target="$target/"

  cd -P . 2>/dev/null || return 1
  while [ "$max_symlinks" -ge 0 ] && max_symlinks=$((max_symlinks - 1)); do
    if [ ! "$target" = "${target%/*}" ]; then
      case $target in
        /*) cd -P "${target%/*}/" 2>/dev/null || break ;;
        *) cd -P "./${target%/*}" 2>/dev/null || break ;;
      esac
      target=${target##*/}
    fi

    if [ ! -L "$target" ]; then
      target="${PWD%/}${target:+/}${target}"
      printf '%s\n' "${target:-/}"
      return 0
    fi

    # `ls -dl` format: "%s %u %s %s %u %s %s -> %s\n",
    #   <file mode>, <number of links>, <owner name>, <group name>,
    #   <size>, <date and time>, <pathname of link>, <contents of link>
    # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html
    link=$(ls -dl -- "$target" 2>/dev/null) || break
    target=${link#*" $target -> "}
  done
  return 1
}
#
# ShellCheck 
shellcheck () {
  _fullname=$(readlinkf "$1")
  _dirname=$(dirname "$_fullname")
  _filename=$(basename "$1")
  docker run --rm -v "$_dirname":/mnt forwardcomputers/shellcheck -a "$_filename"
}
#
# `v` with no arguments opens the current directory in Vim, otherwise opens the given location
v () {
	if [ $# -eq 0 ]; then
		vi .
	else
		vi "$@"
	fi
}
#
extract () {
  if [ -f "$1" ] ; then
    case $1 in
      *.tar.bz2)   tar xvjf "$1"       ;;
      *.tar.gz)    tar xvzf "$1"       ;;
      *.tar.xz)    tar xvf "$1"        ;;
      *.bz2)       bunzip2 -kv "$1"    ;;
      *.rar)       unrar x "$1"        ;;
      *.gz)        gunzip -vk "$1"     ;;
      *.tar)       tar xvf "$1"        ;;
      *.tbz2)      tar xvjf "$1"       ;;
      *.tgz)       tar xvzf "$1"       ;;
      *.zip)       unzip "$1"          ;;
      *.xz)        xz -dkv "$1"        ;;
      *.Z)         uncompress -v "$1"  ;;
      *.7z)        7z x "$1"           ;;
      *)           echo "don't know how to extract '$1'..." ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}
_update_ps1() {
    PS1="$( powerline-go )"
}
#
# macos
# Enable subpixel font rendering on non-Apple LCDs
# Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
defaults write NSGlobalDomain AppleFontSmoothing -bool true
# Stop creating .DS_Store files on shared network shares
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true
# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true
# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
# Automatically download apps purchased on other Macs
defaults write com.apple.SoftwareUpdate ConfigDataInstall -bool true
# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true
# Allow the App Store to reboot machine on macOS updates
defaults write com.apple.commerce AutoUpdateRestartRequired -bool false
#
# base definitions
export FULLNAME=$(id -F)
[[ "${FULLNAME}" != *"@"* ]] && FULLNAME=$( curl --silent --url http://filer/os/lpass )
# Prefer US English and use UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
# Make new shells get the history lines from all previous
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
# directories
export XDG_RUNTIME_DIR="${TMPDIR}"
export XDG_CACHE_HOME="${HOME}/Library/Caches"
export XDG_CONFIG_HOME="${HOME}/Library/Preferences"
export XDG_DATA_HOME="${HOME}/Library"
#
mkdir -p "${XDG_CACHE_HOME}"/less
mkdir -p "${XDG_CONFIG_HOME}"/less
mkdir -p "${XDG_DATA_HOME}"/bash
export BASH_COMPLETION_USER_FILE="$XDG_CONFIG_HOME"/bash-completion/bash_completion
export HISTFILE="$XDG_DATA_HOME/bash/history"
export LESSKEY="$XDG_CONFIG_HOME/less/lesskey"
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
export VIMINIT=":source $XDG_CONFIG_HOME/vim/vimrc"
export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc"
export XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc"
export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export DOCKERCOMPOSE='/opt/filer/os/docker-compose'
export DOCKERFILES='/opt/filer/os/dockerfiles'
export PXE='/opt/filer/os/pxe'
export SHARE='/opt/filer/os/lnx/data'
# add to path
export PATH="${HOME}/bin:/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"
# vim
export EDITOR='vim'
[[ ! -e "${XDG_CACHE_HOME}"/vim ]] && mkdir -p "${XDG_CACHE_HOME}"/vim
export undodir="${XDG_CACHE_HOME}"/vim/undo
export directory="${XDG_CACHE_HOME}"/vim/swap
export backupdir="${XDG_CACHE_HOME}"/vim/backup
# shellcheck disable=SC2016
export viminfo+='1000,n$XDG_CACHE_HOME/vim/viminfo'
export runtimepath="${XDG_CONFIG_HOME}"/vim,"${VIMRUNTIME}","${XDG_CONFIG_HOME}"/vim/after
# lastpass
export LPASS_AGENT_TIMEOUT=0
export LPASS_HOME="$XDG_CONFIG_HOME/lpass"
# hombrew
export HOMEBREW_NO_ANALYTICS=1
#
# colors
i=0;
for color in BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE '' DEFAULT; do
	if [[ -n "$color" ]]; then
		printf -v "FG_$color" $'\e[%dm' $((90 + i))
		printf -v "BG_$color" $'\e[%dm' $((40 + i))
	fi
	((++i))
done
export CO_RESET=$'\e[0m'
export CO_BOLD=$'\e[1m'
export CO_DIM=$'\e[2m'
export CO_UNDERLINE=$'\e[4m'
export CO_BLINK=$'\e[5m'
export CO_REVERSE=$'\e[7m'
export CO_HIDDEN=$'\e[8m'
export UL_WHITE=$'\e[04;97m'        # Underline Bright White
# Less options & color
export LESS='--quit-if-one-screen --ignore-case --status-column --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --tabs=4 --no-init --window=-4'
export LESS_TERMCAP_mb=${FG_RED}        # begin bold
export LESS_TERMCAP_md=${FG_CYAN}       # begin blink
export LESS_TERMCAP_me=${CO_RESET}      # reset bold/blink
export LESS_TERMCAP_se=${CO_RESET}      # reset reverse video
export LESS_TERMCAP_so=$'\e[01;44;37m'  # begin reverse video - Blue background White text
export LESS_TERMCAP_ue=${CO_RESET}      # reset underline
export LESS_TERMCAP_us=${UL_WHITE}      # begin underline
export LESS_TERMCAP_mr=${CO_REVERSE}    # begin reverse
export LESS_TERMCAP_mh=${CO_DIM}        # begin dim
#
# Don't clear the screen after quitting a `man` page
export MANPAGER='less -isX'
export CLICOLOR=1
export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
export LESS_TERMCAP_ZN=$(tput ssubm)  # begin subscript mode
export LESS_TERMCAP_ZV=$(tput rsubm)  # reset subscript mode
export LESS_TERMCAP_ZO=$(tput ssupm)  # begin superscript mode
export LESS_TERMCAP_ZW=$(tput rsupm)  # reset superscript mode
# Causes "raw" control characters to be displayed in less
export LESS='--RAW-CONTROL-CHARS'
# Disable "sgr escape sequences" for man
export GROFF_NO_SGR=1
#
# history
# Increase the maximum number of commands in memory in a history list (default value is 500).
export HISTSIZE=4096
# Increase the maximum number of lines contained in the history file (default value is 500).
export HISTFILESIZE=50000000
export HISTIGNORE="&:[bf]g:c:clear:history:exit:q:pwd:* --help"
export HISTCONTROL=ignoredups:erasedups
# Make new shells get the history lines from all previous
# shells instead of the default "last window closed" history.
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
shopt -s histappend
# Checks the window size after each command
shopt -s checkwinsize
# disable ctrl-s from pausing the terminal
stty -ixon
#
# aliases
#
# cd
alias -- -="cd -"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ${HOME}'
alias dockercompose='cd ${DOCKERCOMPOSE}'
alias dockerfiles='cd ${DOCKERFILES}'
alias pxe='cd ${PXE}'
alias share='cd ${SHARE}'
# ls
alias ls='command ls -G'
alias l='ls -AF'
alias la='ls -laF'
alias ll='ls -laF'
alias lar='ls -laFR'
alias lsd='ls -lF | grep --color=never '^d''
# ls - show long format most recently modified last
alias lt='ls -latr'
alias lsalias='compgen -A alias | column'
# shellcheck disable=SC2142
alias lsfunc='compgen -A function | awk "\$1 !~  /^_/ {print \$1}" | column'
#
alias h='history'
# Reload bash
alias rebash='exec ${SHELL} -l'
# Reset garbled screen
alias garbled='echo -e "\033c"'
# Kill last stopped process
alias ks='kill -s SIGINT %1'
# Docker
alias dk='docker'
alias dkc='dk container ls -a'  # List all Docker containers
alias dki='dk image ls'  # List Docker images
alias dkrmca='dk container rm -f $(dk container ls -a -q)'  # Delete all Docker containers
alias dkrmc='docker container rm'  # Delete a Docker container
alias dkrmia='dk image rm -f $(dk images --filter dangling=true -q)'  # Delete dangling Docker images
alias dkrmi='docker image rm'  # Delete a Docker image
# shellcheck disable=SC2142
alias refresh="dki | awk '(NR>1) && (\$2!~/none/) {print \$1\":\"\$2}' | xargs -L1 docker pull" # Refresh Docker images
# HASS
alias hassc='cat /opt/filer/os/lnx/data/homeassistant/home-assistant.log'
alias hasst='tail /opt/filer/os/lnx/data/homeassistant/home-assistant.log'
alias hasstf='tail -f /opt/filer/os/lnx/data/homeassistant/home-assistant.log'
# git
alias g='git'
# Create new GitHub repo
export LP_GITHUB_API_TOKEN=$(lpass show LP_GITHUB_API_TOKEN --password)
alias gnewr='curl https://api.github.com/user/repos -u forwardcomputers:$LP_GITHUB_API_TOKEN -d {\"name\":\""${PWD##*/}"\"}'
# Create new GitHub repo, add, commit and push files
alias gnew='gnewr && g init && g add . && g commit -m "Initial commit" && g remote add origin ssh://git@github.com/forwardcomputers/${PWD##*/}.git && g push --set-upstream origin master'
# Add, commit and push files
alias gpush='g add . && g commit --short ; g commit -a -m "updates" && g push origin'
# Add, commit and push files no circleci
alias gci='g add . && g commit --short ; g commit -a -m "updates [skip ci]" && g push origin'
# Pull files
alias gpull='g pull origin master && g submodule sync && g submodule update --remote --recursive'
# List ignored files
alias gignored='g status --ignored'
# Submodule update 
alias gsubup='g submodule sync && g submodule update --remote --recursive'
# Repo status 
alias gstatus='g status && git submodule foreach "git status"'
# Status for all repos
# shellcheck disable=SC2154
alias gallstatus='for d in $(find /media/filer/os -maxdepth 5 -name .git); do d="${d%/*}"; output="$( (cd $d; eval "git status") 2>&1 )"; echo -e "\033[0;36m${d}\033[0m\n"$output; done'
alias gdelhis='git_delete_history'
#
# web application alias
alias wapp='qml -f "${HOME}"/bin/wapp.qml --'
# wget history directory
alias wget='wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"'
#
dcon () { ssh -t ali@docker docker exec -it "$1" sh; }
# shellcheck disable=SC2029
dlog () { ssh ali@docker docker container logs "$1"; }
dlogf () { ssh ali@docker docker container logs -f "$1"; }
dupdate () { ssh ali@docker "docker-compose -f /opt/filer/os/docker-compose/watchtower/docker-compose.yml up"; }
# grep alias
alias grep='grep --color=auto '
alias egrep='egrep --color=auto'
#
# Get macOS Software Updates, and update installed Homebrew, and their installed packages
alias dupdate='brew update && brew upgrade && brew cleanup ; brew doctor'
# Flush Directory Service cache
alias flush="sudo bash -c 'dscacheutil -flushcache && killall -HUP mDNSResponder'"
# Airport CLI alias
alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
# Stuff I never really use but cannot delete either because of http://xkcd.com/530/
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume output volume 100'"
# Lock the screen (when going AFK)
alias afk="pmset displaysleepnow"
# Show top 5 CPU hogs
alias hogs='ps -Ao pid,%cpu,user,tty,command -r | head -n 6'
# top alias
alias top='"${HOME}"/bin/ytop_darwin -c vice'
alias oldtop="/usr/bin/top"
#
# 
ln -s -f "${HOME}"/.config/git "${XDG_CONFIG_HOME}"
ln -s -f "${HOME}"/.config/vim "${XDG_CONFIG_HOME}"
ln -s -f "${HOME}"/.config/X11 "${XDG_CONFIG_HOME}"
ln -s -f "${HOME}"/.config/Code/User/settings.json "${HOME}"/Library/Application\ Support/Code/User/
# Bash completions
for f in "${HOME}"/bin/*-completion.bash; do
  . "${f}"
done
# powerline
# shellcheck disable=SC2230
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
# lastpass
lpass status --quiet || until lpass login --trust --force "${FULLNAME}" ; do sleep 0.1 ; done
# ssh
# Source SSH settings, if applicable
export SSH_ENV="${HOME}/.ssh/environment"
# Populate authorized_keys with public key
if [[ ! -f "${HOME}/.ssh/authorized_keys" ]]; then
  lpass show LP_ALIM_RSA --field=pub > "${HOME}/.ssh/authorized_keys"
  chmod 600 "${HOME}/.ssh/authorized_keys"
fi
if [[ -f "${SSH_ENV}" ]]; then
  . "${SSH_ENV}" > /dev/null
  # check if ssh-agent is running
  ps "${SSH_AGENT_PID}" | grep ssh-agent$ > /dev/null || {
    start_agent
  }
else
  start_agent
fi
grep -q "^UseKeychain" "${HOME}/.ssh/config" || printf '%s\n' 0a 'UseKeychain yes' . x | ex "${HOME}/.ssh/config"
cp -a "${HOME}/.ssh/authorized_keys" "${HOME}/.ssh/LP_ALIM_RSA.pub"
# Home Assistant alias
export LP_HASS_API_TOKEN=$(lpass show LP_HASS_INFO --password)
export LP_HASS_HOST=$(lpass show LP_HASS_INFO --username)
alias doff='curl -s -o /dev/null -X POST -H "Authorization: Bearer ${LP_HASS_API_TOKEN}" -H "Content-Type: application/json" -d '\''{"entity_id": "switch.office_desk"}'\'' "${LP_HASS_HOST}":8123/api/services/switch/turn_off'
alias don='curl -s -o /dev/null -X POST -H "Authorization: Bearer ${LP_HASS_API_TOKEN}" -H "Content-Type: application/json" -d '\''{"entity_id": "switch.office_desk"}'\'' "${LP_HASS_HOST}":8123/api/services/switch/turn_on'
# Twitter keys
export LP_T_CONSUMER_KEY=$(lpass show LP_T_CONSUMER_KEY --password)
export LP_T_CONSUMER_SECRET=$(lpass show LP_T_CONSUMER_SECRET --password)
export LP_T_OAUTH_TOKEN=$(lpass show LP_T_OAUTH_TOKEN --password)
export LP_T_OAUTH_SECRET=$(lpass show LP_T_OAUTH_SECRET --password)
