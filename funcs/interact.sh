#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_send_chat_cmd () {
  local CMD="$1"
  local MSG="${CFG[${CMD}_cmd]}"
  [ -n "$MSG" ] || return 8$(
    echo "E: No such chat command template: $CMD" >&2)

  "${CFG[xdoprog]}" key "${CFG[chat_open_key]}" || return $?
  nrbm_wait_for_interaction chat_open || return $?

  MSG="${MSG//%x/$POS_X}"
  MSG="${MSG//%y/$POS_Y}"
  MSG="${MSG//%z/$POS_Z}"
  MSG="${MSG//%f/$TPF_X $TPF_Y $TPF_Z}"
  MSG="${MSG//%c/$COLOR}"
  "${CFG[xdoprog]}" type "$MSG" || return $?
  nrbm_wait_for_interaction chat_type || return $?
  nrbm_wait_for_interaction chat_read_"$CMD" || return $?
  "${CFG[xdoprog]}" key "${CFG[chat_send_key]}" || return $?
  nrbm_wait_for_interaction "$CMD" || return $?
}


function nrbm_wait_for_interaction () {
  local WAIT="${CFG[${1}_wait]}"
  [ -z "$WAIT" ] || sleep "$WAIT" || return 3$(
    echo "E: Failed to wait for $1. Is the duration configured correctly?" >&2)
}













return 0
