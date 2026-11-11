#!/bin/sh
# SPDX-License-Identifier: ISC
# src/text_input.sh - single-line TextInput Actor. Source after actor.sh and str.sh.
if test -n "${_tuish_text_input_loaded:-}"; then return 0; fi
_tuish_text_input_loaded=1

_tuish_input_len () {
  tuish_str_len _tuish_input_text
  TUISH_TEXT_INPUT_LENGTH=$TUISH_SLEN
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
  # Count Unicode codepoints (not bytes); reject rather than silently truncate.
  local _tuish_input_text=$_text
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  test "$_max" -eq 0 || test "$_len" -le "$_max" || return 2
  tuish_actor_set "$_id" value "$_text" || return
  tuish_actor_set "$_id" cursor_position "$_len" || return
  tuish_actor_set "$_id" validation valid
  _tuish_actor_emit "$_id" data_change "$_text"
}
tuish_text_input_insert () {
  local _id=$1 _insert=${2:-} _value _cursor _max _len _left _right _next _insert_len
  _tuish_input_clean "$_insert"; _insert=$TUISH_TEXT_INPUT_CLEAN
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" max_length || return; _max=$TUISH_ACTOR_VALUE
  local _tuish_input_text=$_value
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  local _tuish_input_text=$_insert
  _tuish_input_len; _insert_len=$TUISH_TEXT_INPUT_LENGTH
  test "$_max" -eq 0 || test $((_len + _insert_len)) -le "$_max" || return 2
  tuish_str_left _value "$_cursor"; _left=$TUISH_SLEFT
  tuish_str_right _value "$_cursor"; _right=$TUISH_SRIGHT
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
  local _id=$1 _value _cursor _left _right _next
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  test "$_cursor" -gt 0 || return 0
  local _tuish_input_text=$_value
  tuish_str_left _value "$((_cursor - 1))"; _left=$TUISH_SLEFT
  tuish_str_right _value "$_cursor"; _right=$TUISH_SRIGHT
  _next="${_left}${_right}"
  tuish_actor_set "$_id" value "$_next" || return
  tuish_actor_set "$_id" cursor_position "$((_cursor - 1))" || return
  _tuish_actor_emit "$_id" data_change "$_next"
}
tuish_text_input_delete () {
  local _id=$1 _value _cursor _left _right _next _len
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  local _tuish_input_text=$_value
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  test "$_cursor" -lt "$_len" || return 0
  tuish_str_left _value "$_cursor"; _left=$TUISH_SLEFT
  tuish_str_right _value "$((_cursor + 1))"; _right=$TUISH_SRIGHT
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
