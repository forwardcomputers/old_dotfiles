#!/bin/bash
#
_dapp()
{
  local _commands cur prev
  COMREPLY=()
  _commands="$( grep -E '^[a-zA-Z_-]+.*{.*?## .*$' bin/dapp | awk 'BEGIN { FS = "\\(.*?## " }; { printf $1 }' )"
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "${prev}" in
    build|desktop|info|rebuild|push|remove|run|root|shell|update|upgrade)
#    'build' | 'desktop' | 'rebuild' | 'push' | 'remove' | 'run' | 'root' | 'shell' | 'update' | 'upgrade')
      local dockerfiles=$( find /media/filer/os/dockerfiles/ -name Dockerfile | awk -F'/' '{print $(NF-1)}' )
      COMPREPLY=( $( compgen -W "${dockerfiles}" -- "${cur}" ) )
      return 0
      ;;
    *)
      ;;
  esac
  
  COMPREPLY=( $( compgen -W "${_commands}"  -- "${cur}" ) )
} 

complete -F _dapp dapp
