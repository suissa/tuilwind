#!/bin/sh
# SPDX-License-Identifier: ISC
# src/text_input.sh - single-line TextInput Actor. Source after actor.sh and str.sh.
if test -n "${_tuish_text_input_loaded:-}"; then return 0; fi
_tuish_text_input_loaded=1


# Grapheme boundaries: base codepoint plus combining marks, variation selectors,
# emoji modifiers, ZWJ-linked codepoints and paired regional indicators.
_tuish_input_cp_at () {
  local _s=$1 _i=$2 _b0 _b1 _b2 _b3
  _tuish_ord "${_s:$_i:1}"; _b0=$_tuish_code
  if test "$_b0" -lt 128; then _tuish_input_cp=$_b0; _tuish_input_bytes=1
  elif test "$_b0" -lt 224; then
    _tuish_ord "${_s:$((_i + 1)):1}"; _b1=$_tuish_code
    _tuish_input_cp=$(( ((_b0 & 31) << 6) | (_b1 & 63) )); _tuish_input_bytes=2
  elif test "$_b0" -lt 240; then
    _tuish_ord "${_s:$((_i + 1)):1}"; _b1=$_tuish_code
    _tuish_ord "${_s:$((_i + 2)):1}"; _b2=$_tuish_code
    _tuish_input_cp=$(( ((_b0 & 15) << 12) | ((_b1 & 63) << 6) | (_b2 & 63) )); _tuish_input_bytes=3
  else
    _tuish_ord "${_s:$((_i + 1)):1}"; _b1=$_tuish_code
    _tuish_ord "${_s:$((_i + 2)):1}"; _b2=$_tuish_code
    _tuish_ord "${_s:$((_i + 3)):1}"; _b3=$_tuish_code
    _tuish_input_cp=$(( ((_b0 & 7) << 18) | ((_b1 & 63) << 12) | ((_b2 & 63) << 6) | (_b3 & 63) )); _tuish_input_bytes=4
  fi
}
_tuish_input_is_extend () {
  test "$1" -eq 8204 && return 0
  test "$1" -ge 768 && test "$1" -le 879 && return 0
  test "$1" -ge 6832 && test "$1" -le 6911 && return 0
  test "$1" -ge 7616 && test "$1" -le 7679 && return 0
  test "$1" -ge 8400 && test "$1" -le 8447 && return 0
  test "$1" -ge 65024 && test "$1" -le 65039 && return 0
  test "$1" -ge 65056 && test "$1" -le 65071 && return 0
  test "$1" -ge 917760 && test "$1" -le 917999 && return 0
  test "$1" -ge 127995 && test "$1" -le 127999 && return 0
  test "$1" -ge 917536 && test "$1" -le 917631 && return 0
  return 1
}
_tuish_input_next_boundary () {
  local _s=$1 _i=$2 _n _first
  test "$_i" -lt "${#_s}" || { TUISH_TEXT_INPUT_NEXT=$_i; return 0; }
  _tuish_input_cp_at "$_s" "$_i"; _first=$_tuish_input_cp; _i=$((_i + _tuish_input_bytes))
  if test "$_first" -ge 127462 && test "$_first" -le 127487
  then
    if test "$_i" -lt "${#_s}"; then _tuish_input_cp_at "$_s" "$_i"; if test "$_tuish_input_cp" -ge 127462 && test "$_tuish_input_cp" -le 127487; then _i=$((_i + _tuish_input_bytes)); fi; fi
  fi
  while test "$_i" -lt "${#_s}"
  do
    _tuish_input_cp_at "$_s" "$_i"; _n=$_tuish_input_cp
    if _tuish_input_is_extend "$_n"; then _i=$((_i + _tuish_input_bytes)); continue; fi
    if test "$_n" -eq 8205
    then
      _i=$((_i + _tuish_input_bytes))
      test "$_i" -lt "${#_s}" || break
      _tuish_input_cp_at "$_s" "$_i"; _i=$((_i + _tuish_input_bytes))
      continue
    fi
    break
  done
  TUISH_TEXT_INPUT_NEXT=$_i
}
_tuish_input_graphemes () {
  local _s=$1 _i=0 _n=0
  while test "$_i" -lt "${#_s}"
  do
    _tuish_input_next_boundary "$_s" "$_i"; _i=$TUISH_TEXT_INPUT_NEXT
    _n=$((_n + 1))
  done
  TUISH_TEXT_INPUT_LENGTH=$_n
}
_tuish_input_byte_offset () {
  local _s=$1 _target=$2 _i=0 _n=0
  while test "$_n" -lt "$_target" && test "$_i" -lt "${#_s}"
  do
    _tuish_input_next_boundary "$_s" "$_i"; _i=$TUISH_TEXT_INPUT_NEXT
    _n=$((_n + 1))
  done
  TUISH_TEXT_INPUT_OFFSET=$_i
}

_tuish_input_clean () {
  local _s=$1 _i=0 _ch _out='' _n
  # Preserve UTF-8 bytes; remove C0 controls and DEL to prevent terminal injection.
  while test $_i -lt ${#_s}
  do
    _ch=${_s:$_i:1}
    _tuish_ord "$_ch"; _n=$_tuish_code
    if test "$_n" -ge 32 && test "$_n" -ne 127; then _out="${_out}${_ch}"; fi
    _i=$((_i + 1))
  done
  TUISH_TEXT_INPUT_CLEAN=$_out
}
tuish_text_input_create () {
  local _id=$1 _placeholder=${2:-} _max=${3:-0} _mask=${4:-}
  _tuish_actor_valid_name "$_id" && tuish_actor_supported text-input || return 2
  tuish_actor_valid_value "$_placeholder" && tuish_actor_valid_value "$_mask" || return 2
  _tuish_actor_is_uint "$_max" || return 2
  tuish_actor_create "$_id" text-input || return
  tuish_actor_set "$_id" value '' || return
  tuish_actor_set "$_id" cursor_position 0 || return
  tuish_actor_set "$_id" placeholder "$_placeholder" || return
  tuish_actor_set "$_id" max_length "$_max" || return
  tuish_actor_set "$_id" mask_char "$_mask" || return
  tuish_actor_set "$_id" focus_state 0 || return
  tuish_actor_set "$_id" validation valid || return
}
tuish_text_input_set () {
  local _id=$1 _text=${2:-} _max _len
  _tuish_input_clean "$_text"; _text=$TUISH_TEXT_INPUT_CLEAN
  tuish_actor_get "$_id" max_length || return; _max=$TUISH_ACTOR_VALUE
  # Count grapheme clusters (not bytes); reject rather than silently truncate.
  local _tuish_input_text=$_text
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  test "$_max" -eq 0 || test "$_len" -le "$_max" || return 2
  tuish_actor_set "$_id" value "$_text" || return
  tuish_actor_set "$_id" cursor_position "$_len" || return
  tuish_actor_set "$_id" validation valid
  _tuish_actor_emit "$_id" data_change "$_text"
}
tuish_text_input_insert () {
  local _id=$1 _insert=${2:-} _value _cursor _max _len _left _right _next _insert_len _i
  _tuish_input_clean "$_insert"; _insert=$TUISH_TEXT_INPUT_CLEAN
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" max_length || return; _max=$TUISH_ACTOR_VALUE
  local _tuish_input_text=$_value
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  local _tuish_input_text=$_insert
  _tuish_input_len; _insert_len=$TUISH_TEXT_INPUT_LENGTH
  test "$_max" -eq 0 || test $((_len + _insert_len)) -le "$_max" || return 2
  _tuish_input_byte_offset "$_value" "$_cursor"; _i=$TUISH_TEXT_INPUT_OFFSET
  _left=${_value:0:$_i}; _right=${_value:$_i}
  _next="${_left}${_insert}${_right}"
  tuish_actor_set "$_id" value "$_next" || return
  local _tuish_input_text=$_insert
  _tuish_input_len
  tuish_actor_set "$_id" cursor_position "$((_cursor + TUISH_TEXT_INPUT_LENGTH))" || return
  _tuish_actor_emit "$_id" data_change "$_next"
}
tuish_text_input_move () {
  local _id=$1 _delta=$2 _value _cursor _len
  case "$_delta" in -*) _tuish_actor_is_uint "${_delta#-}" || return 2;; *) _tuish_actor_is_uint "$_delta" || return 2;; esac
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  local _tuish_input_text=$_value
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  _cursor=$((_cursor + _delta))
  test "$_cursor" -ge 0 || _cursor=0
  test "$_cursor" -le "$_len" || _cursor=$_len
  tuish_actor_set "$_id" cursor_position "$_cursor"
}
tuish_text_input_backspace () {
  local _id=$1 _value _cursor _left _right _next _i _j
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  test "$_cursor" -gt 0 || return 0
  local _tuish_input_text=$_value
  _tuish_input_byte_offset "$_value" "$((_cursor - 1))"; _i=$TUISH_TEXT_INPUT_OFFSET
  _tuish_input_byte_offset "$_value" "$_cursor"; _j=$TUISH_TEXT_INPUT_OFFSET
  _left=${_value:0:$_i}; _right=${_value:$_j}
  _next="${_left}${_right}"
  tuish_actor_set "$_id" value "$_next" || return
  tuish_actor_set "$_id" cursor_position "$((_cursor - 1))" || return
  _tuish_actor_emit "$_id" data_change "$_next"
}
tuish_text_input_delete () {
  local _id=$1 _value _cursor _left _right _next _len _i _j
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  local _tuish_input_text=$_value
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  test "$_cursor" -lt "$_len" || return 0
  _tuish_input_byte_offset "$_value" "$_cursor"; _i=$TUISH_TEXT_INPUT_OFFSET
  _tuish_input_byte_offset "$_value" "$((_cursor + 1))"; _j=$TUISH_TEXT_INPUT_OFFSET
  _left=${_value:0:$_i}; _right=${_value:$_j}
  _next="${_left}${_right}"
  tuish_actor_set "$_id" value "$_next" || return
  _tuish_actor_emit "$_id" data_change "$_next"
}
tuish_text_input_paste () { tuish_text_input_insert "$1" "${TUISH_PASTE:-${2:-}}"; }
tuish_text_input_focus () {
  local _id=$1 _state=${2:-1}
  case "$_state" in 0|1) ;; *) return 2;; esac
  tuish_actor_set "$_id" focus_state "$_state" || return
  if test "$_state" -eq 1; then _tuish_actor_emit "$_id" on_focus ''; else _tuish_actor_emit "$_id" on_blur ''; fi
}
tuish_text_input_validate () {
  local _id=$1 _fn=${2:-} _value _status=valid
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  if test -n "$_fn"; then
    command -v "$_fn" >/dev/null 2>&1 || return 3
    "$_fn" "$_value" || _status=invalid
  fi
  tuish_actor_set "$_id" validation "$_status" || return
  _tuish_actor_emit "$_id" on_validate "$_status"
  test "$_status" = valid
}
tuish_text_input_render () {
  local _id=$1 _value _mask _placeholder _focus _shown _cursor _left _right
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" mask_char || return; _mask=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" placeholder || return; _placeholder=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" focus_state || return; _focus=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  if test -z "$_value"; then _shown=$_placeholder
  elif test -n "$_mask"; then
    local _tuish_input_text=$_value
    _tuish_input_len; tuish_str_repeat "$_mask" "$TUISH_TEXT_INPUT_LENGTH"; _shown=$TUISH_SREPEATED
  else _shown=$_value; fi
  printf '%s' "$_shown"
  test "$_focus" -eq 1 && printf ' [cursor:%s]' "$_cursor"
}
