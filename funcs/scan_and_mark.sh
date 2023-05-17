#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_scan_and_mark () {
  local $(nrbm_calculate_ranges) || return $?
  # local -p
  local PROGRESS_PERCENT='??'
  while [ "$N_PRI_SPT_DONE" -lt "$N_PRI_SPT_TOTAL" ]; do
    nrbm_print_progress_indicator || return $?
    nrbm_mark_here || return $?
    nrbm_calculate_next_block || return $?
  done
  echo '=100%   No next block in range.'
}


function nrbm_mark_here () {
  local TPF_{X,Y,Z}=
  let TPF_X="$POS_X + ( ${CFG[teleport_f_x]} )"
  let TPF_Y="$POS_Y + ( ${CFG[teleport_f_y]} )"
  let TPF_Z="$POS_Z + ( ${CFG[teleport_f_z]} )"
  nrbm_send_chat_cmd teleport || return $?

  local PIXELS=( $(nrbm_sshot_to_stdout | nrbm_stdin_pixels_to_hex) )
  local COLOR= BIOME=
  for COLOR in "${PIXELS[@]}"; do
    BIOME="${CFG[color:$COLOR]}"
    [ -z "$BIOME" ] || break
  done
  echo -n "color: $COLOR -> biome: ${BIOME:-unknown} -> "
  [ "$BIOME" == FAIL ] && return 4$(echo 'E: Found FAIL biome! Flinching.' >&2)

  [ -z "${CFG[look_before_setblock_wait]}" ] \
    || nrbm_send_chat_cmd look_before_setblock || return $?

  local LOOKUP=
  if [ -n "$BIOME" ]; then
    for LOOKUP in {1..8}; do
      LOOKUP="${CFG[color:$COLOR]}"
      [ -n "$LOOKUP" ] || break
      COLOR="$LOOKUP"
    done
    echo "item color: $COLOR"
    nrbm_send_chat_cmd setblock || return $?
  else
    nrbm_send_chat_cmd badbiome || return $?
  fi

  (( N_PRI_SPT_DONE += 1 ))
}













return 0
