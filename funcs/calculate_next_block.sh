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










return 0
