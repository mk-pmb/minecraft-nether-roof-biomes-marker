#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function nrbm_mark_we () { "$FUNCNAME"_preview | nrbm_stdin2chat --precount; }


function nrbm_mark_we_preview () {
  local RADIUS="${CFG[we]}"
  case "$RADIUS" in
    cc ) nrbm_mark_we_chunk_corners; return $?;;
  esac
  let RADIUS="$RADIUS"
  [ "${RADIUS:-0}" -ge 1 ] || return 4$(
    echo 'E: WorldEdit radius (option "we") must be positive!' >&2)

  echo //pos1
  echo //pos2
  echo //expand "$RADIUS" n,s,w,e
  echo //gmask air,cave_air
  nrbm_mark_we_replace_biomes || return $?
  echo //gmask
  echo '/;'
}


function nrbm_mark_we_replace_biomes () {
  local BIOMES=()
  nrbm_parse_biomes_list BIOMES "${CFG[b]:-@nether}" || return $?
  local SB_MAT=$'\n'"${CFG[setblock_cmd]}"
  while [[ "$SB_MAT" == *$'\n '* ]]; do
    SB_MAT="${SB_MAT//$'\n '/$'\n'}"
  done
  SB_MAT="${SB_MAT#*$'\n/setblock %x %y %z '}"
  SB_MAT="${SB_MAT%%$'\n'*}"

  local BIOME= MAT=
  for BIOME in "${BIOMES[@]}"; do
    MAT="${BIOME#*=}"
    BIOME="${BIOME%=*}"
    MAT="${CFG[color:$MAT]}"
    MAT="${SB_MAT//%c/$MAT}"
    echo '//replace $'"$BIOME $MAT"
  done
}



function nrbm_mark_we_chunk_corners () {
  if [ "${CFG[x]:0:2}" == 'z=' ]; then
    CFG[x]="${CFG[x]:2}"
    CFG[z]="${CFG[x]}"
  fi
  local {MIN,MAX}_C{X,Z}=
  local {MIN,MAX}_Y=
  local AIRGAP=9
  local KEY= VAL=
  for KEY in x z; do
    VAL="${CFG[$KEY]:-0}"
    case "$VAL" in
      +-[0-9]* | -+[0-9]* | ±[0-9]* )
        VAL="${VAL//-/}"
        VAL="${VAL//+/}"
        VAL="${VAL//±/}"
        VAL="-$VAL..$VAL"
        ;;
      :[0-9]* ) VAL="${VAL#:}"; VAL="-$VAL..$VAL-1";;
    esac
    let "MIN_C${KEY^^}=${VAL%..*}" 1 || return $?
    let "MAX_C${KEY^^}=${VAL#*..}" 1 || return $?
  done

  MAX_BY="${CFG[y]:-160}"
  case "$MAX_BY" in
    *,*,* )
      AIRGAP="${MAX_BY#*,}"
      let AIRGAP="${AIRGAP%%,*}" 1 || return $?
      MIN_BY="${MAX_BY%%,*}"
      MAX_BY="${MAX_BY#*,*,}"
      ;;
  esac
  let MIN_BY="$MIN_BY" MAX_BY="$MAX_BY" 1 || return $?
  [ "$MAX_BY" -ge "$MIN_BY" ] || return 4$(
    echo "E: Y range: Maximum ($MAX_BY) cannot be below minimum ($MIN_BY)!" >&2)
  let AG1="AIRGAP + 1" || return $?
  let EXTRA_FLOORS="( MAX_BY - MIN_BY ) / AG1" 1 || return $?
  let VAL="MIN_BY + ( EXTRA_FLOORS * ( AIRGAP + 1 ) )"
  if [ "$VAL" != "$MAX_BY" ]; then
    MAX_BY="$VAL"
    echo "W: Maximum Y level adjusted to $VAL based on air gap." \
      "Will create $(( EXTRA_FLOORS + 1 )) layer(s) in total.">&2
  fi

  local CHUNK_LENGTH=16
  local MIN_BX=$(( MIN_CX * CHUNK_LENGTH ))
  local MIN_BZ=$(( MIN_CZ * CHUNK_LENGTH ))
  local MAX_BX=$(( ( ( MAX_CX + 1 ) * CHUNK_LENGTH ) - 1 ))
  local MAX_BZ=$(( ( ( MAX_CZ + 1 ) * CHUNK_LENGTH ) - 1 ))
  [ "$DBGLV" -lt 2 ] || local -p >&2
  local {B,D}{X,Y,Z}=0 # block positions and distances

  local TOUR_STEP="${CFG[tour]}"
  local TOUR_STAY="${TOUR_STEP#*,}"
  TOUR_STEP="${TOUR_STEP%,*}"
  if [ "${TOUR_STEP:-0}" -ge 1 ]; then
    nrbm_mark_we_previsit_chunks; return $?
  fi

  local CAM_DIST=10
  echo /tp @s $(( MIN_BX - CAM_DIST )) $(( MIN_BY + CAM_DIST )) $((
    MIN_BZ - CAM_DIST )) facing $MAX_BX $MIN_BY $MAX_BZ
  local DECO_BELOW="${CFG[below]:-glowstone}"
  [ "$DECO_BELOW" == . ] || DY=1
  echo //pos1 $MIN_BX,$(( MIN_BY - DY )),$MIN_BZ

  # Clear the air side border
  (( BZ = MIN_BZ + CHUNK_LENGTH - 1 ))
  local DECO_ABOVE="${CFG[above]:-.}"
  DY=0
  [ "$DECO_ABOVE" == . ] || DY=1

  local AIRSIDE="${CFG[a]:-n}"
  case "$AIRSIDE" in
    a | n ) echo //pos2 $MAX_BX,$(( MAX_BY + DY )),$BZ;;
      # ^-- In case if a=a, to save memory and time, we won't really clear
      #     the entire area now, but instead we'll copy the air later.

    * ) echo "E: Currenlty, only a=a and a=n implemented." >&2; return 4;;
  esac
  echo //gmask
  echo //'# confirm_we_done=clear_airside<60' set air

  # Create lowest level of the template chunk
  (( BX = MIN_BX + CHUNK_LENGTH - 1 ))
  [ "$DECO_BELOW" == . ] || echo //pos1 $MIN_BX,$MIN_BY,$MIN_BZ
  echo //pos2 $BX,$MIN_BY,$BZ
  local PLACEHOLDER="${CFG[t]:-structure_block}"
  printf -- "/setblock %s $PLACEHOLDER\n" {$MIN_BX,$BX}" $MIN_BY "{$MIN_BZ,$BZ}

  if [ "$EXTRA_FLOORS" -ge 1 ]; then
    echo //stack $EXTRA_FLOORS 0,$AG1,0
    echo //pos2 $BX,$MAX_BY,$BZ$(
      )$'\t# Expand marker template range to top floor.'" (y=$MAX_BY)"
  fi

  echo /tp @s $(( MAX_BX + CAM_DIST )) $(( MIN_BY + CAM_DIST )) $((
    MIN_BZ - CAM_DIST )) facing $MIN_BX $MIN_BY $MAX_BZ
  if [ "$MAX_CX" != "$MIN_CX" ]; then
    echo //stack $(( MAX_CX - MIN_CX )) e
    echo //'# confirm_we_done=expand_east<60' pos2 $MAX_BX,$MAX_BY,$BZ$(
      )$'\t# Expand marker template range to east border.'$(
      )" (ch_x=$MAX_CX blk_x=$MAX_BX)"
  fi

  [ "$DECO_ABOVE$DECO_BELOW" == .. ] || echo //gmask
  if [ "$DECO_ABOVE" != . ]; then
    echo //pos2 $MAX_BX,$(( MAX_BY + 1 )),$BZ
    echo //replace ">$PLACEHOLDER" "$DECO_ABOVE"
  fi
  if [ "$DECO_BELOW" != . ]; then
    echo //pos1 $MIN_BX,$(( MIN_BY - 1 )),$MIN_BZ
    echo //replace "<$PLACEHOLDER" "$DECO_BELOW"
  fi

  if [ "$MAX_CZ" != "$MIN_CZ" ]; then
    [ "$AIRSIDE" == a ] || echo //gmask air
    echo //'# confirm_we_done=stack_south<180' stack $(( MAX_CZ - MIN_CZ
      )) 's'$'\t# Stack marker template range to south border.'$(
      )" (ch_z=$MAX_CZ blk_z=$MAX_BZ)"
  fi

  # We can't operate on huge selections due to WE not-a-bug #2343,
  # so instead we'll move the selection south in steps of one chunk.

  echo //'# confirm_we_done=prep_plh<60' gmask "$PLACEHOLDER"$(
      )$'\t# Prepare for replaceing placeholders with actual biome markers.'
  (( DZ = MIN_CZ ))
  while [ "$DZ" -le "$MAX_CZ" ]; do
    (( BZ = DZ * CHUNK_LENGTH ))
    echo /tp @s $(( MIN_BX - CAM_DIST )) $(( MIN_BY + CAM_DIST )) $((
      BZ - CAM_DIST )) facing $MAX_BX $MIN_BY $MAX_BZ
    if [ "$DZ" == "$MIN_CZ" ]; then
      echo "//# confirm_we_done=plh_tp1<60" \
        "# First teleport in placeholder replacement loop"
    else
      echo //'# confirm_we_done=shift_south<30' shift "$CHUNK_LENGTH" s$(
        )$'\t# Move marker replacement range to chunks' \
        "ch_z=$DZ / blk_z=$(( DZ * CHUNK_LENGTH ))."
    fi
    nrbm_mark_we_replace_biomes || return $?
    (( DZ += 1 ))
  done

  echo //gmask
  echo '/;'
}


function nrbm_mark_we_previsit_chunks () {
  local STEPS_COORDS=()
  VAL="$MIN_CX $MIN_CZ $MAX_CX $MAX_CZ $TOUR_STEP"
  case "${CFG[pat]}" in
    zx | '' ) STEPS_COORDS=( $( gen_2d_yx_grid $VAL ) );;
    cws ) STEPS_COORDS=( $( nrbm_gen_2d_spiral_cw $VAL ) );;
    * ) echo "E: $FUNCNAME: unsupportet pattern: ${CFG[pat]}" >&2; return 4;;
  esac

  local MAPKEY="${CFG[mapkey]}"
  local N_STEPS_TOTAL="${#STEPS_COORDS[@]}"
  local N_STEPS_SKIP="${CFG[skip]:-0}"
  local N_STEPS_EFF="$(( N_STEPS_TOTAL - N_STEPS_SKIP ))"
  echo "D: Total steps in this tour: $N_STEPS_TOTAL" \
    "- $N_STEPS_SKIP steps skipped = $N_STEPS_EFF steps effectively." >&2

  local DURA=
  let DURA="$(( ( ( N_STEPS_EFF * TOUR_STAY ) / 60 ) + 1 ))"
  # We need to also add the chat delay for each line, but it's probably
  # not important enough for precise floating-point calculation,
  # so we'll just do a rough estimate.
  let DURA+="N_STEPS_EFF / 30"
  echo "D: This tour will hopefully take less than $DURA minute(s)." >&2

  [ "$N_STEPS_SKIP" == 0 ] || STEPS_COORDS=(
    "${STEPS_COORDS[@]:$N_STEPS_SKIP}" )
  local EFF_STEPS_DONE=0
  for VAL in "${STEPS_COORDS[@]}"; do
    let BX="${VAL%:*} * CHUNK_LENGTH" 1 || return $?
    let BZ="${VAL#*:} * CHUNK_LENGTH" 1 || return $?
    [ -z "$MAPKEY" ] || [ "$EFF_STEPS_DONE" == 0 ] || echo "//# key=Escape"
    echo /tp @s $BX $MIN_BY $BZ facing $BX 0 $(( BZ - 1 ))
    [ -z "$MAPKEY" ] || echo "//# key=$MAPKEY"
    echo "//# delay=$TOUR_STAY # chunk was $VAL"
    (( EFF_STEPS_DONE += 1 ))
  done
}













return 0
