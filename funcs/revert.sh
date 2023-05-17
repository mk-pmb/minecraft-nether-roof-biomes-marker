#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_revert () { nrbm_revert_preview | nrbm_stdin2chat; }


function nrbm_revert_preview () {
  echo //pos1
  echo //pos2
  echo //expand "${CFG[radius]}" n,s,w,e

  # Ingame chat cannot deal with the immense long message that we'd need
  # to replace all blocks in one go, so we divvy them up a bit.
  # First, colorless items:

  local BLK='
    redstone_lamp
    campfire
    '
  echo //replace "$(printf %s, $BLK)" air

  BLK='
    carpet
    wool
    banner
    candle
    '
  for BLK in $BLK; do
    echo //replace "$(printf "%s_$BLK," ${CFG[minecraft_colors]})" air
  done

  echo '//distr'
}













return 0
