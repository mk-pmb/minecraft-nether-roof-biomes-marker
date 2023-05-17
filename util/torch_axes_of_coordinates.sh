#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function torches () {
  [ "${1:-0}" -ge 1 ] || return 4$(
    echo 'E: No distances given as command line arguments! Try "1 2 3".' >&2)
  local D=
  let D="$# * 8"
  echo "//# n_msgs=$D"
  [ "$#" -lt 4 ] || echo "W: Using $D" \
    "/setblock commands will take significant time." \
    "Consider placing just two markers in each direction and then" \
    "using WorldEdit with '//gmask air' and e.g. '//stack 50'." >&2
  for D in "$@"; do
    (( D *= 10 ))

    # East axis:
    echo "/setblock $D ~ 1 glass"
    echo "/setblock $(( $D - 1 )) ~ 1 wall_torch[facing=west]"
    # Playing torches right of the axes is the only RIGHT choice.

    # South axis:
    echo "/setblock -1 ~ $D glass"
    echo "/setblock -1 ~ $(( $D - 1 )) wall_torch[facing=north]"

    # West axis:
    echo "/setblock -$D ~ -1 glass"
    echo "/setblock $(( 1 - $D )) ~ -1 wall_torch[facing=east]"

    # North axis:
    echo "/setblock 1 ~ -$D glass"
    echo "/setblock 1 ~ $(( 1 - $D )) wall_torch[facing=south]"
  done
}










torches "$@"; exit $?
