#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function biodb_upd () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?

  biodb_download_we_biomes_list || return $?
  # Unfortunately I was unable to convince WE devs to add dimension info to
  # their biome IDs list: https://github.com/EngineHub/WorldEdit/issues/2331
  # So instead we'll make a guessing algorithm to generate that information:
  biodb_guess_dimensions || return $?

  # … and then optionally verify the result by comparing with a non-free
  # source:
  [ "$VERIFY" == skip ] || biodb_verify_dimensions || return $?
}


function biodb_download_we_biomes_list () {
  local SAVE='tmp.biomes.we-defs.java'
  wget_dl_maybe we-biometypes || return $?
  sed -nrf <(echo '
    / @Deprecated /d
    / public static final BiomeType /!d
    s~"[^A-Za-z]+$~~
    s~^.* = get\("minecraft:~~p
    ') -- "$SAVE" | sort >tmp.biomes.we-plain.txt
}


function wget_dl_maybe () {
  [ -s "$SAVE" ] && return 0
  local L="$1"
  local R='README.md'
  local U="$(grep -Fe " [$L]:" -- "$R")"
  [ -n "$U" ] || return 4$(echo "E: Cannot find URL for [$L] in $R!" >&2)
  U="${U#*: }"
  case "$U" in
    'https://github.com/'*/blob/* ) U="${U/'/blob/'/'/raw/'}";;
  esac
  echo -n "D: download $SAVE <- "
  local T="tmp.dl-$$.$SAVE"
  wget --output-document="$T" -- "$U" || return $?
  mv --verbose --no-target-directory -- "$T" "$SAVE" || return $?
}


function biodb_guess_dimensions () {
  local NETHER='
    s~\(|\)~~g
    /#/b
    /[a-z]/!b
    s~^~/^~
    s~$~\$/s:^:@nether :~
    p
    '
  NETHER="$(sed -nrf <(echo "$NETHER") -- nether.txt)"
  local SED="$NETHER"'
    /(^|_)end_/s~^~@end ~
    /_(end|void)$/s~^~@end ~
    /^@/!s~^~@overworld ~
    '
  local DIMS='tmp.biomes.we-dims.txt'
  grep -vFe "$NETHER" -- tmp.biomes.we-plain.txt | sed -rf <(echo "$SED"
    ) | sort >"$DIMS"

  local DIM='
    end
    overworld
    '
  for DIM in $DIM; do
    ( echo "# Generated from $DIMS"
      grep -Fe "@$DIM " -- "$DIMS" | cut -d ' ' -sf 2-
    ) >"$DIM.txt"
  done
}


function biodb_verify_dimensions () {
  local SAVE='tmp.biomes.dig.html'
  wget_dl_maybe digmc-biomes || return $?

  local DIG='tmp.biomes.dig.all.txt'
  sed -nre '/<table id="minecraft_items"/,/<\/table>/p' -- "$SAVE" \
    | sed -re 's!</?tr>!\a!' | tr -d '\r\n' | tr '\a' '\n' | sed -nrf <(echo '
    s~\s+~ ~g
    /<em>/!b
    s~</td>~\t~g
    s~<[^<>]*>~~g
    # s~</?(td|em|a)\b[<>]*>~~g
    s~^(\S+)\t(\S+)\t.*$~@\L\2\E \1~p
    ') | sort >"$DIG"
  local COM='tmp.biomes.dig.common.txt'
  grep -wFe "$(cat -- tmp.biomes.we-plain.txt)" -- "$DIG" >"$COM"
  colordiff -sU 2 -- "$COM" tmp.biomes.we-dims.txt
}














biodb_upd "$@"; exit $?
