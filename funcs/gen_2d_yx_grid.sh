#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function gen_2d_yx_grid () {
  local MIN_X="$1"; shift
  local MIN_Y="$1"; shift
  local MAX_X="$1"; shift
  local MAX_Y="$1"; shift
  local STEP_SIZE="${1:-1}"; shift
  local X= Y=
  for Y in $(seq "$MIN_Y" "$STEP_SIZE" "$MAX_Y" ); do
    for X in $(seq "$MIN_X" "$STEP_SIZE" "$MAX_X" ); do
      echo "$X:$Y"
    done
  done
}










return 0
