#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_scan_and_mark () {
  local $(nrbm_calculate_ranges) || return $?
  # local -p
  local PROGRESS_PERCENT='??'
  while [ "$N_PRI_SPT_DONE" -lt "$N_PRI_SPT_TOTAL" ]; do
    PROGRESS_PERCENT=$(( ( 100 * N_PRI_SPT_DONE ) / N_PRI_SPT_TOTAL ))
    printf '≈% 3d%%   ' "$PROGRESS_PERCENT"
    nrbm_mark_here || return $?
    (( N_PRI_SPT_DONE += 1 ))
    nrbm_mark_additional_probing_points || return $?
    nrbm_calculate_next_block || return $?
  done
  echo '=100%   No next block in range.'
}


function nrbm_mark_here () {
  printf 'y=% 4d   ' "$POS_Y"
  printf 'x=% 5d   ' "$POS_X"
  printf 'z=% 5d   ' "$POS_Z"

  local -A CHAT_SLOTS=()
  local AXIS= VAL= TPF=
  for AXIS in x y z; do
    eval VAL='$POS_'"${AXIS^^}"
    CHAT_SLOTS[$AXIS]="$VAL"
    let CHAT_SLOTS[${AXIS^^}]="$VAL + (${CFG[teleport_d_$AXIS]:-0})"
    let VAL="$VAL + (${CFG[teleport_f_$AXIS]:-0})"
    TPF+="$VAL "
  done
  TPF="${TPF% }"
  CHAT_SLOTS[f]="$TPF"
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
    CHAT_SLOTS[c]="$COLOR"
    for AXIS in x y z; do
      eval VAL='$POS_'"${AXIS^^}"
      let "CHAT_SLOTS[${AXIS^^}]=$VAL + (${CFG[setblock_d_$AXIS]:-0})"
    done
    nrbm_send_chat_cmd setblock || return $?
  else
    echo 'place reminder'
    for AXIS in x y z; do
      eval VAL='$POS_'"${AXIS^^}"
      let "CHAT_SLOTS[${AXIS^^}]=$VAL + (${CFG[badbiome_d_$AXIS]:-0})"
    done
    nrbm_send_chat_cmd badbiome || return $?
  fi
}


function nrbm_mark_additional_probing_points () {
  local PRI_X="$POS_X"
  local PRI_Z="$POS_Z"
  local POS_{X,Z}=
  local ADD="${CFG[additional_spots]}"
  ADD="${ADD//,/ }"
  for ADD in $ADD; do
    let POS_X="$PRI_X + (${ADD%%:*})"
    let POS_Z="$PRI_Z + (${ADD##*:})"
    echo -n '   (+)  '
    nrbm_mark_here || return $?
  done
}













return 0
