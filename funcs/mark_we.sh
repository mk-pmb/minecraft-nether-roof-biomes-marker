#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_mark_we () {
  local RADIUS
  let RADIUS="${CFG[we]}"
  [ "${RADIUS:-0}" -ge 1 ] || return 4$(
    echo 'E: WorldEdit radius (option "we") must be positive!' >&2)
  local CHAT_CMDS=(
    //pos{1,2}
    "//expand $RADIUS n,s,w,e"
    '//gmask air,cave_air'
    )
  local BIOMES=()
  nrbm_parse_biomes_list BIOMES "${CFG[b]:-@nether}" || return $?
  local -p

  printf -- '>> %s <<\n' "${CHAT_CMDS[@]}" | nl -ba
}













return 0
