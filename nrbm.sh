#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  local -A CFG=(
    [task]='scan_and_mark'
    [formulae_var_max_nesting]=5
    )
  nrbm_source_these_in_func "$SELFPATH"/funcs/*.sh || return $?
  nrbm_read_config "$@" || return $?
  nrbm_"${CFG[task]}" || return $?$(
    echo "E: Task '${CFG[task]}' failed with error code $?." >&2)
}


function nrbm_source_one_in_func () { source -- "$@"; }


function nrbm_source_these_in_func () {
  local ARG=
  for ARG in "$@"; do
    nrbm_source_one_in_func "$ARG" || return $?
  done
}















nrbm_init "$@"; exit $?
