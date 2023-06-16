#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function save_or_discard_iris_settings () {
  if [ -z "$SEND_KEYS_CMD" ]; then
    function send_keys_debug () {
      echo "D: $FUNCNAME: $*" >&2
      sleep 2s
      xdotool key "$@"
    }
    local SEND_KEYS_CMD='send_keys_debug'
  fi

  # Focus the right-most enabled bottom row button, which will be
  # either "Apply" or "Done" depending on whether we changed something
  # Assuming traditional Iris with the "buy us coffee" button already
  # hidden (using the "X" next to it). Feature Request for more reliable
  # input focus control: https://github.com/IrisShaders/Iris/issues/2028
  $SEND_KEYS_CMD Up{,,} Right{,,,,,}

  [ -z "$WAIT_IRIS_CONFIRM_BUTTON" ] || sleep "$WAIT_IRIS_CONFIRM_BUTTON"
  # ^-- Debug: See which button ("Done" or "Apply") we happened to focus.

  # The problem now is whether the button we have selected is "Done" (which
  # would bring us back to the "Options" menu) or it's "Apply" (which means
  # we'll still need to press the "Done" button).
  #
  # We could press it optimisically and then detect Microsoft-style menus
  # by pixel color, as they have large grey areas and Iris has not.
  # Unless in High Contrast Mode. Yay.
  # Fortunately, we can assume that most of the time, the script will be
  # invoked in a situation where we do effectively modify the config,
  # which means hitting the "Done" button first time is a rare event.
  #
  # For a rare event, we can afford mitigation strategies that will break
  # the interaction flow as long as it breaks in a controlled, safe way.
  # We defer implementation of that…
  mitigate_immediate_done_button || return $?
  # … in order to first show the more likely scenario:

  press_what_will_hopefully_be_the_apply_button || return $?
}


function press_what_will_hopefully_be_the_apply_button () {
  # Assume we have focussed the "Apply" button.
  $SEND_KEYS_CMD Return
  # ^-- Cannot be merged with keys below because Minecraft will freeze
  #     for a fraction of a second while "Apply"ing.

  local KEYS=

  # This means Iris now accepts the Escsape for "Done":
  KEYS+=' Escape'

  # Now be in the "Options" menu, we can use "Escape" to immediately return
  # to world interaction mode.
  KEYS+=' Escape'

  $SEND_KEYS_CMD $KEYS
}


function mitigate_immediate_done_button () {
  local KEYS=

  # As described above, in case our right-most bottom row button happened
  # to be "Done", we need to arrange a situation where wrongly executing
  # press_what_will_hopefully_be_the_apply_button
  # will do the least amount of damage.
  #
  # We can use the fact that Iris will ignore the Escape button as long
  # as there are unsaved changes in the config. One way to mitigate the
  # "Return" key is to open chat, assuming the chat input buffer is empty-
  # Fortunately, there seems to be no way to have something in the chat
  # input buffer while playing the game in world interaction mode.
  # If chat is open, amd then closes by Return, the game will be back
  # in world interaction mode, which means the upcoming double Escape key
  # will do no damage – it will just open and close the "Game Menu".

  # Assume input focus is on the "Done" button.
  # Our actions here MUST have NO effect if there are config changes.

  KEYS+=' Escape'
  # ^-- If we had config changes (and thus focus on "Apply"),
  #     this will have done nothing.
  #     If we had focus on "Done", we're now in the "Options" menu.

  KEYS+=' Escape'
  # ^-- if "Apply": Still no effect.
  #     If "Done": We're now in world interaction mode.

  KEYS+=" ${OPEN_CHAT_KEY:-t}"
  # ^-- if "Apply": No effect.
  #     If "Done": We're now in ingame chat input mode.

  # Nice!
  $SEND_KEYS_CMD $KEYS
}






[ "$1" == --lib ] && return 0; save_or_discard_iris_settings "$@"; exit $?
