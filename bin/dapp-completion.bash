#!/bin/bash
#
_dapp()
{
  if [ "${#COMP_WORDS[@]}" != "2" ]; then
    return
  fi

  COMPREPLY=( $( compgen -W "$( grep -E '^[a-zA-Z_-]+.*{.*?## .*$' bin/dapp | awk 'BEGIN { FS = "\\(.*?## " }; { printf $1 }' )"  -- "${COMP_WORDS[1]}" ) )
}

complete -F _dapp dapp
