#!/usr/bin/env bash
# shellcheck disable=SC2009,SC2155
# shellcheck source=/dev/null
# set -x

# If not running interactively, don't do anything
#[[ $- != *i* || $(id -un) = "duser" ]] && return
[[ $- != *i* ]] && return
#
# Is command a docker app
command_not_found_handle () {
  if [[ -d /media/filer/os/dockerfiles/"${1}" ]]; then
    /media/filer/os/dockerfiles/dapp.sh run "$@"
  else
    if [ -x /usr/lib/command-not-found ]; then
        /usr/lib/command-not-found -- "$1";
        return $?;
    else
        if [ -x /usr/share/command-not-found/command-not-found ]; then
            /usr/share/command-not-found/command-not-found -- "$1";
            return $?;
        else
            printf "%s: command not found\n" "$1" 1>&2;
            return 127;
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
get_ssh_key () {
  # Add existing private keys to ssh agent
  SSH_ADD_OPT=""
  if [[ "${OSTYPE}" == "Darwin" ]]; then SSH_ADD_OPT="-K"; fi
  if ls "${HOME}"/.ssh/LP* 1> /dev/null 2>&1; then
    for LP_ID in "${HOME}"/.ssh/LP*; do
      LP_ID=${LP_ID#$HOME/.ssh/}
      LP_KEY_NAME="${HOME}/.ssh/${LP_ID}"
      LP_KEY_PASS=$(lpass show "${LP_ID}" --password)
      add_key_to_ssh_agent
    done
  else
    # Populate private keys from LastPass and add to ssh agent
    echo "AddKeysToAgent yes" > "${HOME}"/.ssh/config
    echo "ForwardX11 yes" >> "${HOME}"/.ssh/config
    for LP_ID in $(lpass ls --format %an LP_login | sed '1d'); do
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
  expect 2>/dev/null <<EOF >/dev/null
  spawn ssh-add ${SSH_ADD_OPT} ${LP_KEY_NAME}
  expect "Enter passphrase"
  send "${LP_KEY_PASS}\n"
  expect eof
EOF
}
#
OSTYPE=$( uname -s )
#
# Prefer US English and use UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
# hidpi for gtk apps
export GDK_SCALE=2
export GDK_DPI_SCALE=0.5
export QT_DEVICE_PIXEL_RATIO=2
# Make new shells get the history lines from all previous
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
# Don't clear the screen after quitting a `man` page
export MANPAGER='less -X'
# Shared data directory
export SHARE='/media/filer/os/lnx/data'
# ls color, order & XDG options
if [[ "${OSTYPE}" == "Darwin" ]]; then
  export colorflag="-G"
  export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
  export dirsfirst=''
  export FULLNAME=$(id -F)
  export XDG_RUNTIME_DIR="${TMPDIR}"
  export XDG_CACHE_HOME="${HOME}/Library/Caches"
  export XDG_CONFIG_HOME="${HOME}/Library/Preferences"
  export XDG_DATA_HOME="${HOME}/Library"
else
  export colorflag='--color'
  export LS_COLORS='no=00:fi=00:di=01;31:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
  export dirsfirst='--group-directories-first'
  export FULLNAME=$(grep "^$USER:" /etc/passwd | awk -F[:,] '{print $5}')
  export XDG_CACHE_HOME="${HOME}/.cache"
  export XDG_CONFIG_HOME="${HOME}/.config"
  export XDG_DATA_HOME="${HOME}/.local/share"
fi
# Make `vim` the default editor
export EDITOR='vim'
set undodir="${XDG_CACHE_HOME}"/vim/undo
set directory="${XDG_CACHE_HOME}"/vim/swap
set backupdir="${XDG_CACHE_HOME}"/vim/backup
set viminfo+='1000,n$XDG_CACHE_HOME/vim/viminfo'
set runtimepath="${XDG_CONFIG_HOME}"/vim,"${VIMRUNTIME}","${XDG_CONFIG_HOME}"/vim/after
if [[ "${FULLNAME}" != *"@"* ]]; then FULLNAME=$(curl --silent --url http://192.168.1.40/os/lpass); fi
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
alias cd.='cd $(readlink -f .)'
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
#
alias h='history'
# Reload bash
alias rebash='exec ${SHELL} -l'
# Reset garbled screen
alias garbled='echo -e "\033c"'
# Docker alias
alias dapp="/media/filer/os/dockerfiles/dapp.sh"
alias dk='docker'
alias dkc='dk container ls'  # List running Docker containers
alias dkca='dk container ls -a'  # List all Docker containers
alias dki='dk image ls'  # List Docker images
alias dkrmca='dk container rm $(dk container ls -a -q)'  # Delete all Docker containers
alias dkrmc='docker container rm'  # Delete a Docker container
alias dkrmia='dk image rm $(dk images --filter dangling=true -q)'  # Delete dangling Docker images
alias dkrmi='docker image rm'  # Delete a Docker image
# shellcheck disable=SC2142
alias refresh="dki | awk '(NR>1) && (\$2!~/none/) {print \$1\":\"\$2}' | xargs -L1 docker pull" # Refresh Docker images
#
# Highlight the user name when logged in as root.
if [[ "${USER}" == "root" ]]; then
	userStyle="${FG_RED}"
else
	userStyle="${FG_GREEN}"
fi
# Highlight the hostname when connected via SSH.
if [[ -n "${SSH_TTY}" ]]; then
	hostStyle="${CO_BOLD}${FG_RED}"
else
	hostStyle="${FG_GREEN}"
fi
# Set prompt
# shellcheck disable=SC2154
. "$XDG_CONFIG_HOME/git/gitprompt.sh"
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWUPSTREAM="auto"
if [[ -z "${debian_chroot:-}" && -r /etc/debian_chroot ]]; then
     debian_chroot=$(cat /etc/debian_chroot)
 fi
#export PROMPT_COMMAND='echo -ne "\033]0;${USER}@$(hostname -s): ${PWD}\007"'
export PROMPT_COMMAND='__git_ps1 "${debian_chroot:+($debian_chroot)}\[${userStyle}\]\u\[${CO_RESET}\]@\[${hostStyle}\]\h\[${CO_RESET}\]:\[${FG_BLUE}\]\w\[${CO_RESET}\]" "\$ "'
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
if [[ -f /etc/lsb-release || "${OSTYPE}" = "Darwin" ]]; then
  # Set up lastpass
  export GNUPGHOME="$XDG_DATA_HOME/gnupg"
  export LPASS_HOME="$XDG_CONFIG_HOME/lpass"
  if [[ -z "$TMUX" ]]; then
    lpass status --quiet || lpass login --trust --force "${FULLNAME}"
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
  export LESSKEY="$XDG_CONFIG_HOME/less/lesskey"
  export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
  export VIMINIT=":source $XDG_CONFIG_HOME/vim/vimrc"
  export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc"
  export XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc"
  export WGETRC="$XDG_CONFIG_HOME/wgetrc"
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
  alias gpush='g add . && g commit -a -m "updates" && g push origin'
  # Add, commit and push files no circleci
  alias gci='g add . && g commit -a -m "updates [skip ci]" && g push origin'
  # Pull files
  alias gpull='g pull origin master && g submodule update --recursive'
  # List ignored files
  alias gignored='g status --ignored'
  # Submodule update 
  alias gsubup='g submodule update --remote'
  # Repo status 
  alias gstatus='g status'
  # Status for all repos
  alias gallstatus='for d in $(find /media/filer/os -maxdepth 5 -name .git); do d="${d%/*}"; output="$( (cd $d; eval "git status") 2>&1 )"; echo -e "\033[0;36m${d}\033[0m\n"$output; done'
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
  #
  if [[ "${OSTYPE}" == "Darwin" ]]; then
    # Use keychain for ssh logins
    # shellcheck disable=SC1003
    grep -q "^UseKeychain" "${HOME}/.ssh/config" || sed -i '1iUseKeychain yes\' "${HOME}/.ssh/config"
    # Kodi directory
    ln -sfn /media/filer/os/data/Kodi "${HOME}"/Library/Application\ Support/Kodi
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
    alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
    # Show top 5 CPU hogs
    alias hogs='ps -Ao pid,%cpu,user,tty,command -r | head -n 6'
    # ls - show long format most recently modified last
    alias lt='ls -latr'
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
    [[ -x "$(command -v journalctl)" ]] && alias logf='journalctl -f'
  fi
#
  # Bash completions
  if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    . /usr/share/bash-completion/bash_completion
  elif [[ -f /usr/local/etc/bash_completion ]]; then
    . /usr/local/etc/bash_completion
  elif [[ -f /etc/bash_completion ]]; then
    . /etc/bash_completion
  fi
  # git completions
  if [[ -f /usr/share/bash-completion/completions/git ]]; then
    . /usr/share/bash-completion/completions/git
  fi
  #
  # Source SSH settings, if applicable
  if [[ -f /usr/bin/ssh-add ]]; then
    # Populate authorized_keys with public key
    if [[ ! -f "${HOME}/.ssh/authorized_keys" ]]; then
      lpass show LP_ROOT_RSA --field=pub > "${HOME}/.ssh/authorized_keys"
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
  fi
#
fi
#
