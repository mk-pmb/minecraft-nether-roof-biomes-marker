#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_read_config () {
  nrbm_source_one_in_func "$SELFPATH"/defaults.rc || return $?
  local K= V=
  while [ "$#" -ge 1 ]; do
    V="$1"; shift
    if [ "$V" == -- ]; then TASK_ARGS=( "$@" ); break; fi
    K="${V%%=*}"
    [ "$K" == "$V" ] && K=
    V="${V#*=}"
    case "$K" in
      ',' ) TASK_ARGS+=( "$V" );;
      '!' )
        CFG[task]="$V"
        TASK_ARGS=( "$@" )
        break;;
      '' )
        nrbm_source_one_in_func "$V" || return 4$(
          echo "E: Failed to source file '$V'" >&2)
        ;;
      * ) CFG["$K"]="$V";;
    esac
  done
}



return 0
