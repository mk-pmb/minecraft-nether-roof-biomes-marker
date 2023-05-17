#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_send_chat_cmd () {
  local CHAT_CMD="$1"
  local MSG="${CFG[${CHAT_CMD}_cmd]}"
  [ -n "$MSG" ] || return 8$(
    echo "E: No such chat command template: $CHAT_CMD" >&2)
  local SLOT=
  for SLOT in "${!CHAT_SLOTS[@]}"; do
    MSG="${MSG//%$SLOT/${CHAT_SLOTS[$SLOT]}}"
  done
  nrbm_send_chat_msg "$MSG"
  nrbm_wait_for_interaction "$CHAT_CMD" || return $?
}


function nrbm_send_chat_msg () {
  local MSG="$*"
  [ "$DBGLV" -lt 4 ] || echo "D: chat: '$MSG'"
  "${CFG[xdoprog]}" key "${CFG[chat_open_key]}" || return $?
  nrbm_wait_for_interaction chat_open || return $?
  "${CFG[xdoprog]}" type "$MSG" || return $?
  nrbm_wait_for_interaction chat_type || return $?
  nrbm_wait_for_interaction chat_read_"$CHAT_CMD" || return $?
  "${CFG[xdoprog]}" key "${CFG[chat_send_key]}" || return $?
}


function nrbm_stdin2chat () {
  local LN=
  while sleep "${CHAT_DELAY:-0.5s}"; do
    LN=
    IFS= read -r LN || break
    LN="${LN%$'\r'}"
    case "$LN" in
      '#'* ) ;;
      . ) break;;
      * )
        nrbm_send_chat_msg "$LN"
        ;;
    esac
  done
}


function nrbm_wait_for_interaction () {
  local WAIT="${CFG[${1}_wait]}"
  [ -z "$WAIT" ] || sleep "$WAIT" || return 3$(
    echo "E: Failed to wait for $1. Is the duration configured correctly?" >&2)
}













return 0
