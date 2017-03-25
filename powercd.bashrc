#!/bin/bash

_powercd_dotdot() {
  if ! [ "${1/../}" -gt 0 ] &>/dev/null; then
    echo >&2 "positive number required"
    return 1
  fi
  cd "$(printf "%0.s../" $(seq "${1/../}"))" || return
}

powercd() {
  case "$1" in
  ..*) _powercd_dotdot $1 ;;
  esac
}
