#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_calculate_config_formulae () {
  local DEST_VAR= ORIG= FORMULA= RESOLVE= ORIG= OPT=
  for DEST_VAR in "$@"; do
    ORIG=
    eval 'FORMULA=$'"$DEST_VAR"
    RESOLVE="${CFG[formulae_var_max_nesting]}"
    while [ "$RESOLVE" -ge 0 ]; do
      (( RESOLVE -= 1 ))
      [[ "$FORMULA" == *'{'*'}'* ]] || break
      ORIG="$FORMULA"
      # echo "$DEST_VAR orig: '$ORIG'"
      for OPT in "${!CFG[@]}"; do
        FORMULA="${FORMULA//"{$OPT}"/"${CFG[$OPT]}"}"
      done
      # echo "$DEST_VAR   --> '$FORMULA'"
      [ "$FORMULA" == "$ORIG" ] && break
    done
    let "$DEST_VAR=$FORMULA" 1 || return 5$(
      echo "E: Failed to calculate $DEST_VAR = $FORMULA" >&2)
  done
}













return 0
