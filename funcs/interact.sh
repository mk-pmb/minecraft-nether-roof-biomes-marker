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
  local LN= RCV_TIME= HINT= FX=
  local N_LINES_READ=0
  local N_CHATS_SENT=0
  local N_TOTAL=
  local TODO=()
  if [ "$1" == --precount ]; then
    readarray -t TODO < <(grep -Pe '^[^#]')
    N_TOTAL="${#TODO[@]}"
  fi
  [ -n "$CHAT_DELAY" ] || local CHAT_DELAY=0.5s
  while true; do
    LN=
    if [ "${#TODO[@]}" -ge 1 ]; then
      LN="${TODO[0]}"
      TODO=( "${TODO[@]:1}" )
    else
      IFS= read -r LN || break
    fi
    (( N_LINES_READ += 1 ))
    LN="${LN%$'\r'}"
    printf -v RCV_TIME '%(%T)T' -1
    HINT="${LN#*$'\t# '}"
    [ "$HINT" != "$LN" ] || HINT=
    LN="${LN%%$'\t# '*}"
    FX='chat'
    case "$LN" in
      '' | '#'* ) continue;;
      '//# '* )
        LN="${LN#* }"
        FX="${LN%%=*}"
        LN="${LN#*=}"
        [ "$LN" != "$FX" ] || LN=
        ;;
      . ) break;;
    esac
    [ -z "$N_TOTAL" ] || printf -- '\r%s #%s/%s (≈%s%) ' "$RCV_TIME" \
      "$N_LINES_READ" "$N_TOTAL" $(( ( 100 * N_LINES_READ ) / N_TOTAL ))
    [ -z "$HINT" ] || echo "# $HINT"
    [ "$DBGLV" -lt 4 ] || echo "$FX=$LN" >&2

    case "$FX" in
      chat ) nrbm_stdin2chat__send_chat_msg "$LN" || return $?;;
      confirm_continue ) nrbm_confirm_continue --hint "$LN" || return $?;;
      delay ) sleep "${LN%% *}" || return $?;;
      key ) xdotool key "$LN" || return $?;;
      n_msgs ) N_TOTAL="$LN"; continue;;
      confirm_we_done ) nrbm_confirm_we_done "$LN" || return $?;;
      * ) echo "E: $FUNCNAME: Unsupported command: $FX" >&2; return 4;;
    esac
  done
  [ -z "$N_TOTAL" ] || echo "Done: $N_LINES_READ commands processed." \
    "$N_CHATS_SENT chat messages sent."
}


function nrbm_stdin2chat__send_chat_msg () {
  DBGLV=0 nrbm_send_chat_msg "$*" || return $?
  sleep "$CHAT_DELAY" || return $?
  (( N_CHATS_SENT += 1 ))
}


function nrbm_confirm_continue () {
  local MSG=
  printf -v MSG -- '%s\n' "$@"
  local GX_TITLE='Nether Roof Biome Marker'
  local GX_OPT=(
    -title "$GX_TITLE"
    -center
    -buttons GTK_STOCK_ABORT:1,GTK_STOCK_CONTINUE:0
    -default GTK_STOCK_CONTINUE
    )

  if [ "$1" == --hint ]; then
    shift; MSG="${MSG#*$'\n'}"
    [ -z "$HINT" ] || MSG+=$'\n'"Hint: $HINT"$'\n'
  fi

  local LIMIT=9002
  if [ "$1" == --limit ]; then
    shift; MSG="${MSG#*$'\n'}"
    LIMIT="$1"
    shift; MSG="${MSG#*$'\n'}"
  fi
  if [ "$LIMIT" -ge 1 ]; then
    GX_OPT+=( -timeout "$LIMIT" )
  fi

  SECONDS=0
  gxmessage "${GX_OPT[@]}" -file <(echo "$MSG") &
  local GX_PID="$!"

  sleep 0.5s # Wait for gxm window to be ready.
  local GX_WIN='s~\s+~ ~g;s~^(0x\S+) \S+ '"$GX_PID"' .*$~\1~p'
  GX_WIN="$(wmctrl -pl | sed -nre "$GX_WIN")"
  case "$GX_WIN" in
    '' ) echo "E: Failed to find confirmation window ID" >&2; return 6;;
    *$'\n'* ) echo "E: Found too many confirmation window IDs" >&2; return 7;;
  esac

  while sleep 0.2s && kill -0 "$GX_PID" &>/dev/null; do
    wmctrl -iFr "$GX_WIN" -T "($SECONDS / $LIMIT) $GX_TITLE" \
      &>/dev/null || true
    # Errors here are not important: If the window still exists,
    # it will be updated again really soon. Usually the error is
    # just a race condition with the window already closed.
  done

  wait "$GX_PID" || return 6$(
    echo "E: Confirmation failed (rv=$?) or aborted by user after" \
      "$SECONDS sec." >&2)
  echo "D: Confirmed after $SECONDS sec." >&2
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


function nrbm_confirm_we_done () {
  local ORIG="$1"
  local BUF="$ORIG"

  local AUTOCTD_KEY="${BUF%% *}"; BUF="${BUF#* }"
  local AUTOCTD_MAX="${AUTOCTD_KEY#*<}"
  AUTOCTD_KEY="dura:${AUTOCTD_KEY%<*}"
  [ "${AUTOCTD_MAX:-0}" -ge 1 ] || return 4$(
    echo "E: $FUNCNAME: Missing autoctd limit for $ORIG" >&2)

  local VAL="${CFG[$AUTOCTD_KEY]}"
  [ -z "$VAL" ] || [ "$VAL" -ge "$AUTOCTD_MAX" ] || AUTOCTD_MAX="$VAL"

  if [ "${BUF:0:1}" != '#' ]; then
    nrbm_stdin2chat__send_chat_msg //size || return $?
    # ^-- Inject a reliably quick command to distinguish the success
    #     report in case of two consecutive potentially-slow commands.
    nrbm_stdin2chat__send_chat_msg "//$BUF" || return $?
  fi

  nrbm_confirm_continue --hint --limit "$AUTOCTD_MAX" \
    'This WorldEdit command may take a long time:' \
    "${BUF:-(none)}" "It was issued at about $RCV_TIME." \
    'Please confirm when WE reports it finished.' '' \
    "Time limit config key: $AUTOCTD_KEY" \
    || return $?
}

















return 0
