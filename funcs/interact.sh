#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_send_chat_cmd () {
  # Ninja debug: ./nrbm.sh xdoprog=echo chat:y=128 !=send_chat_cmd setblock
  local CHAT_CMD="$1"
  local SCRIPT="${CFG[${CHAT_CMD}_cmd]}"
  case "$SCRIPT" in
    '' )
      echo "E: No such chat command template: $CHAT_CMD" >&2
      return 8;;
    *$'\f'* | *$'\r'* | *$'\t'* | *$'\v'* )
      # Seems like your text editor had some kind of accident.
      echo "E: Chat command template for $CHAT_CMD" \
        "contains unsupported types of whitespace." >&2
      return 8;;
  esac

  local SLOT=
  for SLOT in "${!CFG[@]}"; do case "$SLOT" in
    chat:* ) SCRIPT="${SCRIPT//%${SLOT#*:}/${CFG[$SLOT]}}";;
  esac; done

  local MSG= COND=
  SCRIPT+=$'\n' # <- ensure we can always split off the last actual line.
  while [ -n "$SCRIPT" ]; do
    case "${SCRIPT:0:1}" in
      ' ' | $'\n' ) SCRIPT="${SCRIPT:1}"; continue;;
    esac
    MSG="${SCRIPT%%$'\n'*}"
    SCRIPT="${SCRIPT#*$'\n'}"
    if [[ "$MSG" == *'?'* ]]; then
      test ${MSG%%\?*} || continue
      MSG="${MSG#*\?}"
    fi
    nrbm_send_chat_msg "$MSG"
    nrbm_wait_for_interaction "$CHAT_CMD" || return $?
  done
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
  local LN= N_SENT=0 N_TOTAL=
  while sleep "${CHAT_DELAY:-0.5s}"; do
    LN=
    IFS= read -r LN || break
    LN="${LN%$'\r'}"
    case "$LN" in
      '//# n_msgs='* ) N_TOTAL="${LN#*=}";;
      '' | '#'* ) ;;
      . ) break;;
      * )
        (( N_SENT += 1 ))
        [ -z "$N_TOTAL" ] || echo -n $'\r'"Message #$N_SENT of $N_TOTAL (≈"$((
            ( 100 * N_SENT ) / N_TOTAL ))'%). '
        nrbm_send_chat_msg "$LN"
        ;;
    esac
  done
  [ -z "$N_TOTAL" ] || echo "Done: Sent $N_TOTAL chat messages."
}


function nrbm_wait_for_interaction () {
  local WAIT="${CFG[${1}_wait]}"
  [ -z "$WAIT" ] || sleep "$WAIT" || return 3$(
    echo "E: Failed to wait for $1. Is the duration configured correctly?" >&2)
}


function nrbm_wepos12 () {
  echo //pos1 "$1"; shift
  echo //pos2 "$1"; shift
  [ "$#" == 0 ] || printf -- '//%s\n' "$@"
}













return 0
