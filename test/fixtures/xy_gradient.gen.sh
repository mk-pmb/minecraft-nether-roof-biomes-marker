#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function xy_gradient_gen () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?

  make_one_gradient 32 30 34 30 || return $?
}


function make_one_gradient () {
  local DEST="xy_gradient.$*.ppm"
  DEST="${DEST// /_}"
  local X_FROM="$1"; shift
  local X_STEP="$1"; shift
  local Y_FROM="$1"; shift
  local Y_STEP="$1"; shift
  local COLOR_MAX=255
  local X_SEQ=( $(seq "$X_FROM" "$X_STEP" "$COLOR_MAX") )
  local Y_SEQ=( $(seq "$Y_FROM" "$Y_STEP" "$COLOR_MAX") )
  printf '%s\n' P3 "${#X_SEQ[@]} ${#Y_SEQ[@]}" "$COLOR_MAX" >"$DEST" \
    || return 3$(echo "E: Failed to write file header for $DEST" >&2)
  local R=0 G=64 B=0
  for R in "${Y_SEQ[@]}"; do
    for B in "${X_SEQ[@]}"; do
      echo -n "$R $G $B " >>"$DEST"
    done
    echo >>"$DEST"
  done
  file -- "$DEST" || return $?
}










xy_gradient_gen "$@"; exit $?
