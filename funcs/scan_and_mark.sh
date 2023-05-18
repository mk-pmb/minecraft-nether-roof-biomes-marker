#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_scan_and_mark () {
  local $(nrbm_calculate_ranges) || return $?

  local STOP_AT="${CFG[stop_at]:-0}"
  [ "${STOP_AT:0:1}" == + ] && let STOP_AT="$N_PRI_SPT_DONE$STOP_AT"

  local PROGRESS_PERCENT='??'
  nrbm_scan_and_mark_main_loop && return 0
  local SAM_RV="$?"
  local MSG="E: $FUNCNAME failed (rv=$SAM_RV) at" AXIS=
  for AXIS in x y z; do
    eval 'MSG+=" resume_"$AXIS=$POS_'${AXIS^^}
  done
  echo "$MSG" >&2
  return "$SAM_RV"
}


function nrbm_scan_and_mark_main_loop () {
  while [ "$N_PRI_SPT_DONE" -lt "$N_PRI_SPT_TOTAL" ]; do
    PROGRESS_PERCENT=$(( ( 100 * N_PRI_SPT_DONE ) / N_PRI_SPT_TOTAL ))
    printf '≈% 3d%%   ' "$PROGRESS_PERCENT"
    nrbm_mark_here || return $?
    (( N_PRI_SPT_DONE += 1 ))
    [ "$STOP_AT" == 0 ] || [ "$N_PRI_SPT_DONE" -lt "$STOP_AT" ] || return 4$(
      echo 'E: Reached the stop_at option condition. Quit.' >&2)
    nrbm_mark_additional_probing_points || return $?
    nrbm_calculate_next_block || return $?
  done
  echo '=100%   No next block in range.'
}


function nrbm_mark_here () {
  printf 'y=% 4d   ' "$POS_Y"
  printf 'x=% 5d   ' "$POS_X"
  printf 'z=% 5d   ' "$POS_Z"

  local AXIS= VAL= TPF=
  for AXIS in x y z; do
    eval VAL='$POS_'"${AXIS^^}"
    CFG[chat:$AXIS]="$VAL"
    let CFG[chat:${AXIS^^}]="$VAL + (${CFG[teleport_d_$AXIS]:-0})"
    let VAL="$VAL + (${CFG[teleport_f_$AXIS]:-0})"
    TPF+="$VAL "
  done
  TPF="${TPF% }"
  CFG[chat:f]="$TPF"
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

  if [ -n "$BIOME" ]; then
    for VAL in {1..8}; do
      VAL="${CFG[color:$COLOR]}"
      [ -n "$VAL" ] || break
      COLOR="$VAL"
    done
    echo "item color: $COLOR"
    CFG[chat:c]="$COLOR"
    for AXIS in x y z; do
      eval VAL='$POS_'"${AXIS^^}"
      let "CFG[chat:${AXIS^^}]=$VAL + (${CFG[setblock_d_$AXIS]:-0})"
    done
    nrbm_send_chat_cmd setblock || return $?
  else
    echo 'place reminder'
    for AXIS in x y z; do
      eval VAL='$POS_'"${AXIS^^}"
      let "CFG[chat:${AXIS^^}]=$VAL + (${CFG[badbiome_d_$AXIS]:-0})"
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
