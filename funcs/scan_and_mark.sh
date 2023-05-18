#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_scan_and_mark () {
  local $(nrbm_calculate_ranges) || return $?

  local STOP_AT="${CFG[stop_at]:-0}"
  [ "${STOP_AT:0:1}" == + ] && let STOP_AT="$N_PRI_SPT_DONE$STOP_AT"

  local PROGRESS_PERCENT='??'
  local SSHOT=
  local N_BAD_BIOMES=0
  nrbm_scan_and_mark_main_loop && return 0
  local SAM_RV="$?"
  local MSG="E: $FUNCNAME failed (rv=$SAM_RV) at" AXIS=
  for AXIS in x y z; do
    eval 'MSG+=" resume_"$AXIS=$POS_'${AXIS^^}
  done
  echo "$MSG" >&2
  nrbm_maybe_save_error_screenshot || return $?
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

  SSHOT=
  [ "${CFG[sshot_w]}" == 0 ] || SSHOT="$(nrbm_sshot_to_stdout)"
  local COLOR=
  [ -z "$SSHOT" ] || COLOR="$(
    <<<"$SSHOT" nrbm_stdin_pixels_to_hex | sort --version-sort --unique)"
  local BIOME_NAME=
  local BIOME_COLORS=
  local UNKNOWN_COLORS=
  for COLOR in $COLOR; do
    VAL="${CFG[color:$COLOR]}"
    if [ -n "$VAL" ]; then
      BIOME_NAME+="$VAL+"
      BIOME_COLORS+=" $COLOR"
    else
      UNKNOWN_COLORS+=" $COLOR"
    fi
  done

  echo -n "color: ${COLOR:-(skipped)} "
  BIOME_NAME="${BIOME_NAME%+}"
  echo -n "-> biome: ${BIOME_NAME:-unknown} "
  case "$BIOME_NAME" in
    FAIL )
      echo 'E: Found FAIL biome! Flinching.' >&2
      return 4;;
    *+* )
      echo "E: Found pixels from multiple biomes! Colors:$BIOME_COLORS" >&2
      return 4;;
  esac

  if [ -z "$BIOME_NAME" -a -n "${CFG[ocr_cmd]}" ]; then
    echo -n '-> trying OCR: '
    BIOME_NAME="$( eval "${CFG[ocr_cmd]}" )"
    echo -n "-> '$BIOME_NAME' "
  fi

  [ -z "${CFG[look_before_setblock_wait]}" ] \
    || nrbm_send_chat_cmd look_before_setblock || return $?

  if [ -n "$BIOME_NAME" ]; then
    nrbm_mark_known_biome || return $?
  else
    nrbm_mark_unknown_biome || return $?
  fi
}


function nrbm_mark_known_biome () {
  COLOR="${CFG[color:$BIOME_NAME]}"
  # ^-- In earlier versions with just sky color detection, this was done
  #     implicitly by the first two rounds of the alias lookup loop.
  #     Now with OCR, we have to explicitly lookup the name.
  for VAL in {1..8}; do
    VAL="${CFG[color:$COLOR]}"
    [ -n "$VAL" ] || break
    COLOR="$VAL"
  done
  echo "-> item color: $COLOR"
  CFG[chat:c]="$COLOR"
  for AXIS in x y z; do
    eval VAL='$POS_'"${AXIS^^}"
    let "CFG[chat:${AXIS^^}]=$VAL + (${CFG[setblock_d_$AXIS]:-0})"
  done
  nrbm_send_chat_cmd setblock || return $?
}


function nrbm_mark_unknown_biome () {
  (( N_BAD_BIOMES += 1 ))
  echo "#$N_BAD_BIOMES, unknown colors:$UNKNOWN_COLORS"

  for AXIS in x y z; do
    eval VAL='$POS_'"${AXIS^^}"
    let "CFG[chat:${AXIS^^}]=$VAL + (${CFG[badbiome_d_$AXIS]:-0})"
  done
  nrbm_send_chat_cmd badbiome || return $?

  VAL="${CFG[max_bad_biomes]:-0}"
  [ "$VAL" == 0 ] || [ "$VAL" -gt "$N_BAD_BIOMES" ] || return 4$(
    echo 'E: Reached the max_bad_biomes limit. Quit.' >&2)
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


function nrbm_maybe_save_error_screenshot () {
  local SAVE="${CFG[sshot_save_on_error]}"
  [ -n "$SAVE" ] || return 0

  SAVE="${SAVE//%x/$POS_X}"
  SAVE="${SAVE//%y/$POS_Y}"
  SAVE="${SAVE//%z/$POS_Z}"
  local NOW=
  printf -v NOW '%(%y%m%d %H%M%S)T' -1
  SAVE="${SAVE//%d/${NOW% *}}"
  SAVE="${SAVE//%t/${NOW#* }}"

  echo -n "Saving error screenshot to $SAVE: "
  echo "$SSHOT" >"$SAVE" || return 4$(echo 'E: Failed to save file!' >&2)
  echo 'done.'
}













return 0
