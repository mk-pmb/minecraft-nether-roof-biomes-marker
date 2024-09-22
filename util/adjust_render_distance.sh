#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
#
# Mojang removed the hotkeys for adjusting render distance:
# https://feedback.minecraft.net/hc/en-us/community/posts/11514487299469
#
# Iris shaders won't add such hotkeys:
# https://github.com/IrisShaders/Iris/issues/1999


function srd_cli_init () {
  set -o errexit -o pipefail
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  source -- "$SELFPATH"/save_or_discard_sodium_settings.sh --lib || return $?

  local MSGBOX_PROG='gxmessage'
  local INDICATOR_WNAME='MinecraftRenderDistanceIndicator'
  local INDICATOR_TITLE_SUFFIX=' render distance'
  local INDICATOR_FOUND="$(srd_query_indicator)"
  local SEND_KEYS_CMD='send_keys_with_delay'

  local ARG="$1"; shift
  case "$ARG" in
    -i | --start-indicator ) srd_start_indicator "$@"; return $?;;
    -u | --update-indicator ) srd_update_indicator "$@"; return $?;;
    -Q | --query-indicator )
      [ -n "$INDICATOR_FOUND" ] && echo "$INDICATOR_FOUND"
      return $?;;
    -*[^0-9]* ) echo "E: Unsupported option $1" >&2; return 3;;
  esac

  local DIST="$ARG"
  # Go to settings
  $SEND_KEYS_CMD Escape Up Up Return
  # Go to video settings
  $SEND_KEYS_CMD Down Down Return
  # Select render distance slider
  #   * assuming traditional Sodium
  #     * i.e. not using Reese's Sodium Options
  $SEND_KEYS_CMD Down

  local MIN_DIST=2    # The left-most limit of the slider.
  case "$DIST" in
    - | + ) DIST+=1;;
    [0-9]* ) $SEND_KEYS_CMD $(str_repeat 64 'Left ');;
  esac
  srd_update_indicator "$DIST" || true
  case "$DIST" in
    -[0-9]* ) $SEND_KEYS_CMD $(str_repeat "${DIST#-}" 'Left ');;
    +[0-9]* ) $SEND_KEYS_CMD $(str_repeat "${DIST#+}" 'Right ');;
    [0-9]* )
      [ "$DIST" -ge "$MIN_DIST" ] || return 4$(
        echo "E: Minimum render distance in slider is $MIN_DIST" >&2)
      (( DIST -= MIN_DIST )) || true
      $SEND_KEYS_CMD $(str_repeat "$DIST" 'Right ')
      ;;
    * ) echo "E: Unsupported render distance format." >&2; return 3;;
  esac

  save_or_discard_sodium_settings || return $?
}


function send_keys_with_delay () {
  [ "$#" -ge 1 ] || return 0
  local CTD="$KEY_PREVIEW_CTD"
  if [ -n "$CTD" ]; then
    echo "D: $FUNCNAME: $*" >&2
    sleep "$CTD" || return $?
  fi

  xdotool key "$@"
  local DELAY=
  let DELAY="50 + (15 * $#)"
  printf -v DELAY '%s.%03ds' $(( DELAY / 1000 )) $(( DELAY % 1000 ))
  sleep "$DELAY" || return 4$(echo "E: Failed to wait for $DELAY" >&2)
}


function str_repeat () {
  [ "${1:-0}" -ge 1 ] || return 0
  local BUF=
  printf -v BUF '% *s' "$1" ''
  shift
  echo -n "${BUF// /$*}"
}


function srd_start_indicator () {
  local DIST="$1"
  [ -n "$DIST" ] || return 4$(
    echo 'E: Initial render distance must be given as CLI argument.' >&2)
  [ "$DIST" -ge 1 ] || return 4$(
    echo 'E: Initial render distance must be a positive number.' >&2)

  if [ -n "$INDICATOR_FOUND" ]; then
    srd_update_indicator "$DIST"
    wmctrl -iFR "${INDICATOR_FOUND#* }"
    return 0
  fi

  setsid "$MSGBOX_PROG" -name "$INDICATOR_WNAME" \
    -title "$DIST$INDICATOR_TITLE_SUFFIX" \
    -buttons GTK_STOCK_QUIT -default GTK_STOCK_QUIT -file - <<<'
    The window title of this message
    box should (hopefully) show the
    current render distance. Most
    window managers do have ways to
    "roll up" the window, so only its
    titlebar is shown.
    ' &

  local RETRY=
  for RETRY in {1..20}; do
    sleep 0.2s
    INDICATOR_FOUND="$(srd_query_indicator)"
    srd_update_indicator +0 && return 0 || true
  done
}


function srd_query_indicator () {
  wmctrl -xl | sed -nre 's~^(0x\S+)\s+\S+\s+'"$INDICATOR_WNAME$(
    ).$MSGBOX_PROG"'\s+\S+\s+([0-9]+) .*$~\2 \1~ip' || true
}


function srd_update_indicator () {
  local DIST="$1" UPD=
  [ -n "$INDICATOR_FOUND" ] || return 2
  local WIN_ID="${INDICATOR_FOUND#* }"
  local OLD_RD="${INDICATOR_FOUND% *}"
  wmctrl -iFr "$WIN_ID" -b add,above,shaded || true
  case "$DIST" in
    +0 | -0 ) return 0;; # Meant to just set the default window properties.
    +[0-9]* | -[0-9]* ) let UPD="$OLD_RD$DIST";;
    [0-9]* ) let UPD="$DIST";;
  esac
  [ "${UPD:-0}" -ge 1 ] || return 4$(
    echo 'E: Failed to update indicator: Invalid new render distance!' >&2)
  wmctrl -iFr "$WIN_ID" -T "$UPD$INDICATOR_TITLE_SUFFIX" || return 5$(
    echo 'E: Failed to set indicator window title!' >&2)
}










srd_cli_init "$@"; exit $?
