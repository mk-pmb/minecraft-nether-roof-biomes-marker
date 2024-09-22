#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function save_or_discard_sodium_settings () {
  if [ -z "$SEND_KEYS_CMD" ]; then
    function send_keys_debug () {
      echo "D: $FUNCNAME: $*" >&2
      sleep 2s
      xdotool key "$@"
    }
    local SEND_KEYS_CMD='send_keys_debug'
  fi

  # Fortunately, with Sodium 0.5.11 (maybe even earlier), the category tabs
  # on top no longer wrap around if you go too far to the left or right.
  # We have to go very far to the right in order to make our later "Down"
  # moves "fall" to the bottom-right buttons, rather than selecting one of
  # the options inside the category.
  $SEND_KEYS_CMD Up{,,,,,,,,,,} Right{,,,,,,,,,,}

  sleep "${WAIT_SODIUM_CONFIRM_BUTTON:-0}" || return $?
  # ^-- Debug: See which button ("Done" or "Apply") we happened to focus.

  # Now the input focus should be on one of the buttons in the bottom right
  # corner. If no effective changes have been made, the last "Right" move
  # actually already dropped down to the "Done" button.
  # If changes have been made, we instead have to press "Down" once in
  # order to reach the "Apply" button.
  # Pressing "Down" on the "Done" button does nothing, so we can safely
  # do that without checking:
  $SEND_KEYS_CMD Down

  # Now let's hit what was either apply or done:
  $SEND_KEYS_CMD space

  # In case it was the "Done" button, we're now in the "Options" menu.
  #   * Pressing "Up" a lot (at least twice) will focus on the FOV slider.
  #     * Pressing "Return" on the FOV slider will toggle the focus between
  #       the entire slider (from which "Right" key would jump to the
  #       difficulty option) and its knob (where sideways movement will
  #       adjust the slider).
  #       * Whether the slider or its knob are toggled has no effect on the
  #         "Escape" key: It always returns to the Game Menu.
  # If instead it was the "Apply" button, we're still in the Sodium options,
  # with no button focussed. In this case:
  #   * The "Down" key would do nothing.
  #   * The "Right" key would focus the "Done" button.
  #   * The "Up" key would focus a far-right category tab,
  #     and further "Up" keys woudl do nothing.

  # My original idea was to construct a key sequence that uses the FOV slider
  # as a sink for extranous "Return" keys, but I think it's easier to rely on
  # several "Escape" presses to reach either the Main menu or ingame, and then
  # invoke the chat (which only triggers ingame) to have the next "Escape"
  # key reliably go back to ingame.

  $SEND_KEYS_CMD Escape{,,,}

  # Minecraft may need a moment to react to config changes before it will
  # be ready to accept the chat input request:
  sleep 0.2s
  $SEND_KEYS_CMD t Escape
}







[ "$1" == --lib ] && return 0; save_or_discard_sodium_settings "$@"; exit $?
