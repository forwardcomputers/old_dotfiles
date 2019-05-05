#!/bin/bash
#
#DAPP_COMMANDS=$( grep -E '^[a-zA-Z_-]+.*{.*?## .*$' bin/dapp | sort | awk 'BEGIN {FS = "\\(.*?## "}; { printf $1 }' )
_dapp()
{
  COMPREPLY=( $( compgen -W "$( grep -E '^[a-zA-Z_-]+.*{.*?## .*$' bin/dapp | awk 'BEGIN { FS = "\\(.*?## " }; { printf $1 }' )"  "${COMP_WORDS[1]}" ) )
}

complete -F _dapp dapp
