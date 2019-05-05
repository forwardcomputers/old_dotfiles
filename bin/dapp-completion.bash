#!/bin/bash
#
_dapp()
{
  COMPREPLY=( $( compgen -W "$( grep -E '^[a-zA-Z_-]+.*{.*?## .*$' bin/dapp | awk 'BEGIN { FS = "\\(.*?## " }; { printf $1 }' )"  "${COMP_WORDS[1]}" ) )
}

complete -F _dapp dapp
