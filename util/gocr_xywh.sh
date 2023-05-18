#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function gocr_xywh () {
  local XYWH="$1" # comma-separated
  local DBGLV="${DEBUGLEVEL:-0}"
  local CAPTURE="$(gen_capture_cmd)"
  local SED='
    s~[A-Z]+~\L&\E~g
    s~ ~~g
    s~^[s_]oul[s_]andvalley~soulsand~
    s~^(basalt|crimson|warped).*$~\1~
    s~^.*(wastes)$~\1~
    '
  eval "$CAPTURE" | sed -rf <(echo "$SED")
}

function gen_capture_cmd () {
  echo -n "scrot --silent --autoselect $XYWH --overwrite /dev/stdout"
  [ "$DBGLV" -lt 2 ] || echo -n " | tee -- ocr_debug.png"
  echo -n ' | convert - -threshold 95% -monochrome pbm:-'
  [ "$DBGLV" -lt 2 ] || echo -n " | tee -- ocr_debug.pbm"
  echo -n ' | gocr -C "A-Za-z " -f ASCII'
  [ "$DBGLV" -lt 2 ] || echo -n " | tee -- ocr_debug.txt"
}

gocr_xywh "$@"; exit $?
