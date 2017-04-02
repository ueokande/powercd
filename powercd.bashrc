#!/bin/bash

_power_at_list() {
  (
    export IFS=':'
    for dir in $POWERPATH; do
      find "$dir" -mindepth 1 -maxdepth 1 -type d
    done
  )
}

_power_at_atnames() {
  (
    export IFS=':'
    for dir in $POWERPATH; do
      find "$dir" -mindepth 1 -maxdepth 1 -printf '@%f\n'
    done
  )
}

_power_at_get() {
  local basename
  _power_at_list | while read line; do
    basename=$(basename "$line")
    if [[ "$basename" = "$1" ]]; then
      echo $line
      exit
    fi
  done
}

_power_expand_at() {
  local target rem dir

  target=$(echo "$1" | sed 's/^@\([^/]\+\)\(.*\)/\1/g')
  rem=$(echo "$1" | sed 's/^@\([^/]\+\)\(.*\)/\2/g')
  dir=$(_power_at_get "$target")
  if [ -z "$dir" ]; then
    echo "$1"
  else
    echo "$dir$rem"
  fi
}

_powercd_at() {
  local expanded

  expanded=$(_power_expand_at "$1")
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

  cur="${COMP_WORDS[COMP_CWORD]}"
  entries=$(_power_at_atnames)
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
