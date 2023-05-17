#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_calculate_ranges () {
  local PROP= AXIS= DIR= DEST= VAL=
  local N_PRI_SPT_TOTAL=1
  for AXIS in X=east Y=up Z=south; do
    DIR="${AXIS#*=}"
    AXIS="${AXIS%=*}"
    for PROP in min max step ; do
      VAL="${CFG["$PROP"_"$DIR"]}"
      DEST="${PROP^^}_$AXIS"
      local "$DEST=$VAL"
      nrbm_calculate_config_formulae "$DEST" || return $?
    done

    eval 'local POS_$AXIS="${CFG[resume_'${AXIS,,}']:-$MIN_'$AXIS'}"'

    # Number of positions on this axis = 1 for the initial position
    # + number of steps from there:
    let "(( VAL = 1 + ( ( MAX_$AXIS - MIN_$AXIS ) / STEP_$AXIS ) ))"
    local "N_VALUES_$AXIS=$VAL"
    (( N_PRI_SPT_TOTAL *= VAL ))
  done

  local N_PRI_SPT_DONE=
  nrbm_calculate_ranges__resume_progress || return $?

  unset PROP AXIS DIR DEST VAL
  local -p
}


function nrbm_calculate_ranges__resume_progress () {
  # How many floors are completed?
  local FULL_FLOORS=$(( ( POS_Y - MIN_Y ) / STEP_Y ))

  # How many lines are completed in previous floors and in the current floor?
  local LINES_IN_PREV_FL=$(( N_FLOORS_DONE * N_VALUES_Z ))
  local LINES_IN_CRNT_FL=$(( ( POS_Z - MIN_Z ) / STEP_Z ))
  local FULL_LINES=$(( LINES_IN_PREV_FL + LINES_IN_CRNT_FL ))

  # How many primary sampling points in previous lines and the current line?
  local SPT_IN_PREV_LN=$(( FULL_LINES * N_VALUES_X ))
  local SPT_IN_CRNT_LN=$(( ( POS_X - MIN_X ) / STEP_X ))
  local SPT_DONE=$(( SPT_IN_PREV_LN + SPT_IN_CRNT_LN ))

  N_PRI_SPT_DONE="$SPT_DONE"
}













return 0
