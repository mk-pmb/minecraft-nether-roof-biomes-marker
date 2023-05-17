#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_stdin_pixels_to_hex () {
  local PM=()
  readarray -t PM < <(convert - -compress none ppm:- \
    | grep -vFe '#' | grep -oPe '\w+')
  [ "${PM[0]} ${PM[3]}" == 'P3 255' ] || return 7$(
    echo "E: Unexpected image file format after conversion." >&2)
  [ "${PM[1]} ${PM[2]}" == "${CFG[sshot_w]} ${CFG[sshot_h]}" ] || return 7$(
    echo "E: Wrong screenshot dimensions:" \
      "Expected ${CFG[sshot_w]} × ${CFG[sshot_h]}" \
      "but got ${PM[1]} × ${PM[2]}." >&2)
  local ADD="${CFG[sshot_n]}"
  [ "${ADD:-0}" -ge 1 ] || return 4$(
    echo 'E: Bad value for option sshot_n.' >&2)
  (( ADD *= 3 ))
  local IDX=4
  while [ "$IDX" -lt "${#PM[@]}" ]; do
    printf -- '%02X%02X%02X\n' ${PM[@]:$IDX:3}
    (( IDX += ADD ))
  done
}


function nrbm_sshot_to_stdout () {
  local AREA="${CFG[sshot_x]},${CFG[sshot_y]},${CFG[sshot_w]},${CFG[sshot_h]}"
  scrot --silent --autoselect "$AREA" --overwrite -- /dev/stdout
}














return 0
