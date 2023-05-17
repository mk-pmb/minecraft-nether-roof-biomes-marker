#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_scan_and_mark () {
  local $(nrbm_calculate_ranges) || return $?
  local -p
  while [ "$POS_Y" -le "$MAX_Y" ]; do
    nrbm_calculate_next_block || return $?
  done
}


function nrbm_mark_here () {
  # local PIXELS=( $(sshot_to_stdout | nrbm_stdin_pixels_to_hex) )
  local -p
}













return 0
