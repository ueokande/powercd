#!/bin/bash

POWERCD_AT_CACHE="$HOME/.powercd_at_profile"

powercd_at_update() {
  local dir

  while test $# != 0; do
    if ! [ -d "$1" ]; then
      echo 2>&1 "powercd: '$1': No such file or directory"
      shift
      continue
    fi

    for dir in $1/*; do
      echo "$(basename "$dir")=$dir" >>"$POWERCD_AT_CACHE"
    done
    shift
  done
}

_powercd_expand_at() {
  local target rem dir

  if [ ! -f "$POWERCD_AT_CACHE" ]; then
    return 1
  fi

  target=$(echo "$1" | sed 's/@\([^/]\+\)\(.*\)/\1/g')
  rem=$(echo "$1" | sed 's/@\([^/]\+\)\(.*\)/\2/g')
  dir=$(awk -F= '$1=="'"$target"'" { print $2 }' "$POWERCD_AT_CACHE" | tail -1)
  if [ -z "$dir" ]; then
    return 1
  fi

  echo "$dir$rem"
}

_powercd_at() {
  local expanded

  if ! expanded=$(_powercd_expand_at "$1"); then
    echo 2>&1 "powercd: $1: No such file or directory"
    return 1
  fi
  cd "$expanded" || return
}

_powercd_dotdot() {
  if [ "${1/../}" -gt 0 ] &>/dev/null; then
    cd "$(printf "%0.s../" $(seq "${1/../}"))" || return
  else
    cd "$@" || return
  fi
}

powercd() {
  case "$1" in
  @*) _powercd_at "$1" ;;
  ..*) _powercd_dotdot "$1" ;;
  *) cd "$@" || return ;;
  esac
}

_powercd() {
  local cur entries

  if [ ! -f "$POWERCD_AT_CACHE" ]; then
    return 1
  fi

  cur="${COMP_WORDS[COMP_CWORD]}"
  entries=$(awk -F=  '{print "@" $1}' "$POWERCD_AT_CACHE")
  if [[ "$COMP_CWORD" = 1 && "$cur" =~ ^@ ]]; then
    COMPREPLY=( $(compgen -W "$entries" -- "${cur}") )
    return 0
  elif [[ "$COMP_CWORD" = 1 && "$cur" =~ ^\.\. ]]; then
    COMPREPLY=( $(compgen -W "$entries" -- "${cur}") )
    return 0
  fi
  return 1
}

complete -F _powercd -o dirnames powercd
