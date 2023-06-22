#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_gen_2d_spiral_cw () {
  local MIN_X="$1"; shift
  local MIN_Y="$1"; shift
  local MAX_X="$1"; shift
  local MAX_Y="$1"; shift
  local STEP_SIZE="${1:-1}"; shift

  local MID_X=$(( ( MIN_X + MAX_X ) / 2 ))
  local MID_Y=$(( ( MIN_Z + MAX_Z ) / 2 ))
  # Calculate number of grid points, starting at MID, into each direction:
  local N_STEPS_L=$(( ( MID_X - MIN_X ) / STEP_SIZE ))
  local N_STEPS_R=$(( ( MAX_X - MID_X ) / STEP_SIZE ))
  local N_STEPS_X=$(( N_STEPS_L + N_STEPS_R + 1 ))
  local N_STEPS_U=$(( ( MID_Z - MIN_Z ) / STEP_SIZE ))
  local N_STEPS_D=$(( ( MAX_Z - MID_Z ) / STEP_SIZE ))
  local N_STEPS_Y=$(( N_STEPS_NORTH + N_STEPS_SOUTH + 1 ))

  local LONGER_X=$(( N_STEPS_Z - N_STEPS_X ))
  [ $LONGER_X -ge 1 ] || LONGER_X=0
  local LONGER_Z=$(( N_STEPS_X - N_STEPS_Z ))
  [ $LONGER_Z -ge 1 ] || LONGER_Z=0

  [ "$DBGLV" -lt 2 ] || local -p >&2
}










return 0
