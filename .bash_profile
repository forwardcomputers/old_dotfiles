#!/usr/bin/env bash
# shellcheck disable=SC2009,SC2155
# shellcheck source=/dev/null
#set -x

# If not running interactively, don't do anything
#[[ $- != *i* || $(id -un) = "duser" ]] && return
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
  SSH_ADD_OPT=""
  if [[ "${OSTYPE}" == Darwin ]]; then SSH_ADD_OPT="-K"; fi
  if ls "${HOME}"/.ssh/LP* 1> /dev/null 2>&1; then
#    for LP_ID in "${HOME}"/.ssh/LP*; do
    for LP_ID in $( find "${HOME}"/.ssh -type f -name LP* | xargs -iZ basename Z | cut -d"." -f1 | uniq ); do
      LP_ID=${LP_ID#$HOME/.ssh/}
      LP_KEY_NAME="${HOME}/.ssh/${LP_ID}"
      LP_KEY_PASS=$(lpass show "${LP_ID}" --password)
      add_key_to_ssh_agent
    done
  else
    # Populate private keys from LastPass and add to ssh agent
    echo "AddKeysToAgent yes" > "${HOME}"/.ssh/config
    echo "ForwardX11 yes" >> "${HOME}"/.ssh/config
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

#
OSTYPE=$( uname -s )
#
# Prefer US English and use UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
# hidpi for gtk apps
# export GDK_SCALE=2
# export GDK_DPI_SCALE=0.5
# export QT_DEVICE_PIXEL_RATIO=2
# Make new shells get the history lines from all previous
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
# Don't clear the screen after quitting a `man` page
export MANPAGER='less -X'
# Shared data directory
export DOCKERCOMPOSE='/opt/filer/os/docker-compose'
export DOCKERFILES='/opt/filer/os/dockerfiles'
export PXE='/opt/filer/os/pxe'
export SHARE='/opt/filer/os/lnx/data'
# ls color, order & XDG options
if [[ "${OSTYPE}" == Darwin ]]; then
  export colorflag="-G"
  export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
  export dirsfirst=''
  export FULLNAME=$(id -F)
  export XDG_RUNTIME_DIR="${TMPDIR}"
  export XDG_CACHE_HOME="${HOME}/Library/Caches"
  export XDG_CONFIG_HOME="${HOME}/Library/Preferences"
  export XDG_DATA_HOME="${HOME}/Library"
  # add qml to path
  export PATH="${PATH}:/usr/local/Cellar/qt/5.14.2/libexec/qml.app/Contents/MacOS"
else
  export colorflag='--color'
  export LS_COLORS='no=00:fi=00:di=01;31:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
  export dirsfirst='--group-directories-first'
  export FULLNAME=$(grep "^$USER:" /etc/passwd | awk -F[:,] '{print $5}')
  export XDG_CACHE_HOME="${HOME}/.cache"
  export XDG_CONFIG_HOME="${HOME}/.config"
  export XDG_DATA_HOME="${HOME}/.local/share"
  # add qml to path
  #export PATH="${PATH}"
fi
# Check for lastpass username
if [[ "${FULLNAME}" != *"@"* ]]; then FULLNAME=$(curl --silent --url http://filer/os/lpass ); fi
# Define .gnupg
export GNUPGHOME="${XDG_DATA_HOME}"/gnupg
[[ ! -e "${XDG_DATA_HOME}"/gnupg ]] && mkdir -p "${XDG_DATA_HOME}"/gnupg
# Make `vim` the default editor
export EDITOR='vim'
[[ ! -e "${XDG_CACHE_HOME}"/vim ]] && mkdir -p "${XDG_CACHE_HOME}"/vim
export undodir="${XDG_CACHE_HOME}"/vim/undo
export directory="${XDG_CACHE_HOME}"/vim/swap
export backupdir="${XDG_CACHE_HOME}"/vim/backup
# shellcheck disable=SC2016
export viminfo+='1000,n$XDG_CACHE_HOME/vim/viminfo'
export runtimepath="${XDG_CONFIG_HOME}"/vim,"${VIMRUNTIME}","${XDG_CONFIG_HOME}"/vim/after
# Prompt colors
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
export PAGER='less'
#
# cd alias
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
# ls alias
alias ls='command ls ${colorflag} ${dirsfirst}'
alias dir='command dir ${colorflag} ${dirsfirst}'
alias vdir='command vdir ${colorflag} ${dirsfirst}'
alias l='ls -AF ${colorflag}'
alias la='ls -laF ${colorflag}'
alias ll='ls -laF ${colorflag}'
alias lar='ls -laFR ${colorflag}'
alias lsd='ls -lF ${colorflag} | grep --color=never '^d''
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
# Docker alias
alias dk='docker'
alias dkc='dk container ls -a'  # List all Docker containers
alias dki='dk image ls'  # List Docker images
alias dkrmca='dk container rm -f $(dk container ls -a -q)'  # Delete all Docker containers
alias dkrmc='docker container rm'  # Delete a Docker container
alias dkrmia='dk image rm -f $(dk images --filter dangling=true -q)'  # Delete dangling Docker images
alias dkrmi='docker image rm'  # Delete a Docker image
# shellcheck disable=SC2142
alias refresh="dki | awk '(NR>1) && (\$2!~/none/) {print \$1\":\"\$2}' | xargs -L1 docker pull" # Refresh Docker images
# HASS alias
alias hassc='cat /opt/filer/os/lnx/data/hassio/homeassistant/home-assistant.log'
alias hasst='tail /opt/filer/os/lnx/data/hassio/homeassistant/home-assistant.log'
alias hasstf='tail -f /opt/filer/os/lnx/data/hassio/homeassistant/home-assistant.log'
#
if [[ "${HOSTNAME}" = "docker" ]]; then
  dcon () { docker exec -it "$1" sh; }
  dlog () { docker container logs "$1"; }
  docui () {
    if ! [ "$(docker container ls -aq -f status=running -f name=docui)" ]; then
      if [ "$(docker container inspect -f '{{.State.Status}}' docui)" == "exited" ]; then
        docker start docui
      else
        docker run --name docui -d -itv /var/run/docker.sock:/var/run/docker.sock skanehira/docui
      fi
    fi
    docker attach docui
  }
  dupdate () { docker-compose -f /opt/filer/os/docker-compose/watchtower/docker-compose.yml up; } 
else
  dcon () { ssh ali@docker docker exec -it "$1" sh; }
# shellcheck disable=SC2029
  dlog () { ssh ali@docker docker container logs "$1"; }
  dupdate () { ssh ali@docker "docker-compose -f /opt/filer/os/docker-compose/watchtower/docker-compose.yml up"; }
fi
#
#
#
# For VMware
#
if [[ -d /sys/devices/virtual/dmi/id ]]; then
  if [[ $(< /sys/devices/virtual/dmi/id/sys_vendor) == "VMware, Inc." ]]; then
    # Disable OpenGL 3.3 support to have OpenGL 2.1 support. This may be useful to work around application bugs (such as incorrect use of the OpenGL 3.x core profile).
    export SVGA_VGPU10=0
  fi
fi
#
#
# For Synology
#
if [[ -f /etc/synoinfo.conf ]]; then
  export SHARE='/volume1/share/os/lnx/data'
  # cd alias
  alias -- -='cd -'
  # grep alias
  alias grep='grep --color=auto '
  # Login as root
  alias root='sudo su -'
  # Show top 5 CPU hogs
  alias hogs="ps -eo pid,%cpu,user,args --sort -%cpu | awk 'NR<=6'"
  # Update all packages
  alias update='synopkg upgradeall'
  # Follow the system logfile
  alias logf='tail -f /var/log/messages'
  # ls - show long format most recently modified last
  alias lt='ls -latr --time-style=long-iso'
  # Essential network location and files
  alias dhcp='cd /etc/dhcpd'
  alias vidhcp='vi /etc/dhcpd/dhcpd-eth0-static.conf'
  alias dhcprestart='/etc/rc.network nat-restart-dhcp'
  alias dns='cd /var/packages/DNSServer/target/named/etc/zone/master'
  alias vidnsfwd='vi /var/packages/DNSServer/target/named/etc/zone/master/alihome.com'
  alias vidnsrev='vi /var/packages/DNSServer/target/named/etc/zone/master/1.168.192.in-addr.arpa'
  alias dnsrestart='synoservice --restart pkgctl-DNSServer'
  alias vpn='cd /usr/syno/etc/packages/VPNCenter/openvpn'
  alias vivpn='vi /usr/syno/etc/packages/VPNCenter/openvpn/openvpn.conf'
  alias vpnrestart='synoservice --restart pkgctl-VPNCenter'
  alias pxe='cd /volume1/web/pxe'
  alias vipxe='vi /volume1/web/pxe/boot.ipxe'
  alias log='cd /var/packages/LogCenter/target/service/conf'
  # Copy network settings
  # shellcheck disable=SC1004
  alias cpsettings='cp -t /volume1/nas/synology \
    /etc/dhcpd/dhcpd-eth0-static.conf \
    /var/packages/DNSServer/target/named/etc/zone/master/alihome.com \
    /var/packages/DNSServer/target/named/etc/zone/master/1.168.192.in-addr.arpa \
    /usr/syno/etc/packages/VPNCenter/openvpn/openvpn.conf \
    /usr/syno/etc/packages/VPNCenter/openvpn/*.confo'
#
fi
#
# For OpenWrt
#
if [[ -f /etc/openwrt_release ]]; then
  # cd alias
  alias -='cd -'
  # Update the repos and do an upgrade
  alias upgrade='opkg update && opkg list-upgradable | cut -f 1 -d " " | xargs -r opkg upgrade'
  # Follow the system logfile
  alias logf='logread -f'
  # ls - show long format most recently modified last
  alias lt='ls -latr --full-time'
#
fi
#
# For Linux
#
if [[ -f /etc/lsb-release || -f /etc/os-release || "${OSTYPE}" = Darwin ]]; then
    # Add to path
    export PATH="${HOME}"/bin:"${PATH}"
    # golang setup
    export PATH="${PATH}:/usr/local/go/bin"
    export GOPATH="${HOME}/app"
    # Set up lastpass
    export LPASS_AGENT_TIMEOUT=0
    export LPASS_HOME="$XDG_CONFIG_HOME/lpass"
    if [[ -z "$TMUX" ]]; then
      lpass status --quiet || until lpass login --trust --force "${FULLNAME}" ; do sleep 0.1 ; done
    fi
    # Set up the console
    setupcon 2>/dev/null
    # Set ssh environment file
    export SSH_ENV="${HOME}/.ssh/environment"
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
    # ANSI colors are supported and should be used
    export CLICOLOR=1
    # Checks the window size after each command
    shopt -s checkwinsize
    # Less colored
    export LESS_TERMCAP_ZN=$(tput ssubm)  # begin subscript mode
    export LESS_TERMCAP_ZV=$(tput rsubm)  # reset subscript mode
    export LESS_TERMCAP_ZO=$(tput ssupm)  # begin superscript mode
    export LESS_TERMCAP_ZW=$(tput rsupm)  # reset superscript mode
    # Causes "raw" control characters to be displayed in less
    export LESS='--RAW-CONTROL-CHARS'
    # Disable "sgr escape sequences" for man
    export GROFF_NO_SGR=1
    # tmux options
    export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
    # i3 options
    export TERMINAL=urxvt
    export VISUAL=leafpad
    # XDG exports
    export BASH_COMPLETION_USER_FILE="$XDG_CONFIG_HOME"/bash-completion/bash_completion
    export HISTFILE="$XDG_DATA_HOME/bash/history"
    [[ ! -e "${XDG_CACHE_HOME}"/less ]] && mkdir -p "${XDG_CACHE_HOME}"/less
    export LESSKEY="$XDG_CONFIG_HOME/less/lesskey"
    export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
    export VIMINIT=":source $XDG_CONFIG_HOME/vim/vimrc"
    export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc"
    export XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc"
    export WGETRC="$XDG_CONFIG_HOME/wgetrc"
    export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
    # dbus accessibility errors
    export NO_AT_BRIDGE=1
    # web application alias
    alias wapp='qml -f "${HOME}"/bin/wapp.qml --'
    # wget history directory
    alias wget='wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"'
    # git alias
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
    # Twitter keys
    export LP_T_CONSUMER_KEY=$(lpass show LP_T_CONSUMER_KEY --password)
    export LP_T_CONSUMER_SECRET=$(lpass show LP_T_CONSUMER_SECRET --password)
    export LP_T_OAUTH_TOKEN=$(lpass show LP_T_OAUTH_TOKEN --password)
    export LP_T_OAUTH_SECRET=$(lpass show LP_T_OAUTH_SECRET --password)
    # grep alias
    alias grep='grep --color=auto '
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    # tmux alias
    # alias tm='tmux attach -t $USER ||\
    #     tmux -f "$XDG_CONFIG_HOME/tmux/tmux.conf" new-session -A -s $USER \;\
    #     split-window -v -p 25 \;\
    #     new-window \;\
    #     select-window -t $USER:2 \;\
    #     send-keys -t $USER:2.1 "ssh hass" C-m \;\
    #     select-window -t $USER:1 \;\
    #     select-pane -t 1 '
    alias tm='tmux -f "$XDG_CONFIG_HOME/tmux/tmux.conf" new-session -AD -s $USER'
    # VSCode directory
    if [[ ! -f "/.dockerenv" ]]; then ln -sfn "${XDG_CONFIG_HOME}"/code "${HOME}"/code; fi
    # Home Assistant alias
    export LP_HASS_API_TOKEN=$(lpass show LP_HASS_INFO --password)
    export LP_HASS_HOST=$(lpass show LP_HASS_INFO --username)
    alias doff='curl -s -o /dev/null -X POST -H "Authorization: Bearer ${LP_HASS_API_TOKEN}" -H "Content-Type: application/json" -d '\''{"entity_id": "switch.office_desk"}'\'' "${LP_HASS_HOST}":8123/api/services/switch/turn_off'
    alias don='curl -s -o /dev/null -X POST -H "Authorization: Bearer ${LP_HASS_API_TOKEN}" -H "Content-Type: application/json" -d '\''{"entity_id": "switch.office_desk"}'\'' "${LP_HASS_HOST}":8123/api/services/switch/turn_on'
    #
    if [[ "${OSTYPE}" == Darwin ]]; then
        # Use keychain for ssh logins
        # shellcheck disable=SC1003
        #grep -q "^UseKeychain" "${HOME}/.ssh/config" || sed -i '1iUseKeychain yes\' "${HOME}/.ssh/config"
        grep -q "^UseKeychain" "${HOME}/.ssh/config" || printf '%s\n' 0a 'UseKeychain yes' 'ConnectTimeout 5' . x | ex "${HOME}/.ssh/config"
        # powerline directory
        ln -sfn "${HOME}"/.config/powerline "${HOME}"/Library/Preferences/powerline
        # Enable subpixel font rendering on non-Apple LCDs
        # Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
        defaults write NSGlobalDomain AppleFontSmoothing -int 1
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
        defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
        # Install System data files & security updates
        defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
        # Automatically download apps purchased on other Macs
        defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 1
        # Turn on app auto-update
        defaults write com.apple.commerce AutoUpdate -bool true
        # Allow the App Store to reboot machine on macOS updates
        defaults write com.apple.commerce AutoUpdateRestartRequired -bool false
        #
        # Get macOS Software Updates, and update installed Homebrew, and their installed packages
        alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup'
        # Flush Directory Service cache
        alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"
        # Airport CLI alias
        alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
        # Stuff I never really use but cannot delete either because of http://xkcd.com/530/
        alias stfu="osascript -e 'set volume output muted true'"
        alias pumpitup="osascript -e 'set volume output volume 100'"
        # Lock the screen (when going AFK)
        alias afk="/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend"
        # Show top 5 CPU hogs
        alias hogs='ps -Ao pid,%cpu,user,tty,command -r | head -n 6'
        # ls - show long format most recently modified last
        alias lt='ls -latr'
        # top alias
        alias top='"${HOME}"/bin/ytop_darwin -c vice'
        alias oldtop="/usr/bin/top"
    else
        if [[ ! -f "/.dockerenv" ]]; then 
            # Kodi directory
            ln -sfn /media/filer/os/data/Kodi "${HOME}"/.kodi
            # startx config directory
            alias startx='startx "$XDG_CONFIG_HOME/X11/xinitrc"'
        fi
        # Update the repos and do an upgrade
        [[ -x "$(command -v apt)" ]] && alias update='apt update && apt -y upgrade'
        # Show top 5 CPU hogs
        alias hogs="ps -eo pid,%cpu,user,command --sort -%cpu | awk 'NR<=6'"
        # ls - show long format most recently modified last
        alias lt='ls -latr --time-style=long-iso'
        # Follow the system logfile
        if [[ -x "$(command -v journalctl)" ]]; then
          alias logboot='journalctl -b'
          alias logf='journalctl -f'
          alias logtoday='journalctl --since today'
        fi
        # Clear journal file 
        alias journal_clear='journalctl --merge --vacuum-time=1s'
        # top alias
        alias top='"${HOME}"/bin/ytop_linux -c vice'
        alias oldtop="/usr/bin/top"
    fi
    #
    # Bash completions
    for f in "${HOME}"/bin/*-completion.bash; do
        . "${f}"
    done
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /usr/local/etc/bash_completion ]]; then
        . /usr/local/etc/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
    #
    # Source SSH settings, if applicable
    if [[ -f /usr/bin/ssh-add ]]; then
        # Populate authorized_keys with public key
        if [[ ! -f "${HOME}/.ssh/authorized_keys" ]]; then
            lpass show LP_ALIM_RSA --field=pub > "${HOME}/.ssh/authorized_keys"
            chmod 600 "${HOME}/.ssh/authorized_keys"
            cp -a "${HOME}/.ssh/authorized_keys" "${HOME}/.ssh/LP_ALIM_RSA.pub"
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
        if [[ "${OSTYPE}" == Darwin ]]; then
            grep -q "^UseKeychain" "${HOME}/.ssh/config" || printf '%s\n' 0a 'UseKeychain yes' . x | ex "${HOME}/.ssh/config"
        fi
    fi
    # mount /media/filer in CROS
    if [[ -n "$SOMMELIER_VERSION" ]]; then
        if [[ ! -d /media/filer ]]; then
            sudo mkdir --parents /media/filer
        fi
        sshfs admin@filer:/share /media/filer
    fi
    # start powerline
    # shellcheck disable=SC2230
    if [[ -f "$(which powerline-daemon)" ]]; then
        if [[ "${OSTYPE}" != Darwin ]]; then
          powerline-daemon --quiet
        fi
        export POWERLINE_BASH_CONTINUATION=1
        export POWERLINE_BASH_SELECT=1
        for f in /usr/share/powerline/bash/powerline.sh /usr/share/powerline/bindings/bash/powerline.sh /usr/local/lib/python3.7/site-packages/powerline/bindings/bash/powerline.sh ; do
            . "${f}" 2>/dev/null
        done
    fi
#
fi
#
