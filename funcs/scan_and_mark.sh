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
  echo 'Done: no next block in range = 100%'
}


function nrbm_mark_here () {
  local PIXELS=( $(nrbm_sshot_to_stdout | nrbm_stdin_pixels_to_hex) )
  local COLOR_HEX= BIOME=
  for COLOR_HEX in "${PIXELS[@]}"; do
    BIOME="${CFG[color:$COLOR_HEX]}"
    [ -z "$BIOME" ] || break
  done
  echo -n "color: $COLOR_HEX   "
  [ "$BIOME" == FAIL ] && return 4$(echo 'E: Found FAIL biome! Flinching.' >&2)
  (( N_PRI_SPT_DONE += 1 ))
}













return 0
