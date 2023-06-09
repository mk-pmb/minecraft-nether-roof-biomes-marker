#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_mark_we () { "$FUNCNAME"_preview | nrbm_stdin2chat; }


function nrbm_mark_we_preview () {
  local RADIUS=
  let RADIUS="${CFG[we]}"
  [ "${RADIUS:-0}" -ge 1 ] || return 4$(
    echo 'E: WorldEdit radius (option "we") must be positive!' >&2)

  echo //pos1
  echo //pos2
  echo //expand "$RADIUS" n,s,w,e
  echo //gmask air,cave_air

  local BIOMES=()
  nrbm_parse_biomes_list BIOMES "${CFG[b]:-@nether}" || return $?
  local SB_MAT=$'\n'"${CFG[setblock_cmd]}"
  while [[ "$SB_MAT" == *$'\n '* ]]; do
    SB_MAT="${SB_MAT//$'\n '/$'\n'}"
  done
  SB_MAT="${SB_MAT#*$'\n/setblock %x %y %z '}"
  SB_MAT="${SB_MAT%%$'\n'*}"

  local BIOME= MAT=
  for BIOME in "${BIOMES[@]}"; do
    MAT="${BIOME#*=}"
    BIOME="${BIOME%=*}"
    MAT="${CFG[color:$MAT]}"
    MAT="${SB_MAT//%c/$MAT}"
    echo '//replace $'"$BIOME $MAT"
  done

  echo //gmask
  echo '/;'
}













return 0
