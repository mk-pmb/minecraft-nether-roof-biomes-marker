#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_read_config () {
  source -- "$SELFPATH"/defaults.rc || return $?
  local K= V=
  for V in "$@"; do
    K="${V%%=*}"
    [ "$K" == "$V" ] && K=
    V="${V#*=}"
    case "$K" in
      '' )
        source -- "$V" || return 4$(echo "E: Failed to source file '$V'" >&2)
        ;;
      * ) CFG["$K"]="$V";;
    esac
  done
}



return 0
