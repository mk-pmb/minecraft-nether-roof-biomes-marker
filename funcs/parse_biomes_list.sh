#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_parse_biomes_list () {
  local D="$1" B="$2"
  [ "${B:0:1}" != '@' ] || B="<$NRBM_PATH/data/biome_shortnames/${B:1}.txt"
  [ "${B:0:1}" != '<' ] || B="$(grep -vFe '#' -- "${B:1}" | grep -Pe '[a-z]')"
  B="${B//[$'\r\t ,']/$'\n'}"
  B="$(<<<"$B" nrbm_parse_biomes_list__parens)" || return $?
  [ -n "$B" ] || return 4$(echo "E: $FUNCNAME: Found no biome names!" >&2)
  case "$D" in
    . | '' ) echo "$B";;
    * ) readarray -t "$D" <<<"$B" || return $?;;
  esac
}


function nrbm_parse_biomes_list__parens () {
  sed -rf <(echo '
    /\S/!d
    /\(/p
    s~\)~\r~g
    s~\(\S+\r~~g
    s~\r~~g
    ') | sed -rf <(echo '
    /\(/N
    s~\n~=~
    s~\(|\)~~g
    ')
}














return 0
