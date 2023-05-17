#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_calculate_next_block () {
  (( POS_X += STEP_X ))
  [ "$POS_X" -le "$MAX_X" ] && return 0
  POS_X="$MIN_X"

  (( POS_Z += STEP_Z ))
  [ "$POS_Z" -le "$MAX_Z" ] && return 0
  POS_Z="$MIN_Z"

  (( POS_Y += STEP_Y ))
  return 0
}


function nrbm_print_progress_indicator () {
  local "$@" DUMMY=
  PROGRESS_PERCENT=$(( ( 100 * N_PRI_SPT_DONE ) / N_PRI_SPT_TOTAL ))
  local FMT='y=% 4s|x=% 5s|z=% 5s|≈% 3d%%|'
  FMT="${FMT//|/   }"
  printf "$FMT" "$POS_Y" "$POS_X" "$POS_Z" "$PROGRESS_PERCENT"
}










return 0
