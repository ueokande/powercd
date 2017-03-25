#!/bin/bash

POWERCD_AT_CACHE="$HOME/.powercd_at_profile"

powercd_at_update() {
  touch "$HOME"/.hoprc

  while test $# != 0; do
    if ! [ -d "$1" ]; then
      echo 2>&1 "$0: '$1': No such file or directory"
      shift
      continue
    fi

    for dir in $1/*; do
      echo "$(basename "$dir")=$dir" >>"$POWERCD_AT_CACHE"
    done
    shift
  done
}

_powercd_at() {
  local dir target
  target="${1/@/}"
  if [ -z "$target" ]; then
    cat "$POWERCD_AT_CACHE"
    return 0
  fi

  dir=$(awk -F= '$1=="'"$target"'" { print $2 }' "$POWERCD_AT_CACHE" | tail -1)
  if [ -z "$dir" ]; then
    echo 2>&1 "$0: $1: No such file or directory"
    return 1
  else
    cd "$dir" || return
  fi
}

_powercd_dotdot() {
  if ! [ "${1/../}" -gt 0 ] &>/dev/null; then
    echo >&2 "positive number required"
    return 1
  fi
  cd "$(printf "%0.s../" $(seq "${1/../}"))" || return
}

powercd() {
  case "$1" in
  @*) _powercd_at "$1" ;;
  ..*) _powercd_dotdot "$1" ;;
  esac
}

_powercd() {
  local cur entries

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

complete -F _powercd -o dirname powercd
