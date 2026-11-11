#!/bin/sh
# SPDX-License-Identifier: ISC
set -uf
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/src/compat.sh"
. "$ROOT/src/ord.sh"
. "$ROOT/src/tui.sh"
. "$ROOT/src/str.sh"
. "$ROOT/src/actor.sh"
. "$ROOT/src/text_input.sh"
. "$ROOT/tests/lib/test_framework.sh"

printf 'Unit tests: TextInput Actor\n'
tuish_text_input_create name 'Your name' 8
tuish_text_input_set name 'Alice'
tuish_actor_get name cursor_position
assert_eq "$TUISH_ACTOR_VALUE" 5 'set places cursor at end'
tuish_text_input_move name -2
tuish_text_input_insert name 'X'
tuish_actor_get name value
assert_eq "$TUISH_ACTOR_VALUE" 'AliXce' 'insert occurs at cursor'
tuish_text_input_backspace name
tuish_actor_get name value
assert_eq "$TUISH_ACTOR_VALUE" 'Alice' 'backspace removes previous character'
tuish_text_input_move name 99
tuish_actor_get name cursor_position
assert_eq "$TUISH_ACTOR_VALUE" 5 'cursor clamps to end'
tuish_text_input_delete name
tuish_actor_get name value
assert_eq "$TUISH_ACTOR_VALUE" 'Alice' 'delete at end is safe'
_status=0
tuish_text_input_set name '123456789' || _status=$?
assert_eq "$_status" 2 'maximum length rejects overflow without truncation'
tuish_text_input_set name 'João'
tuish_actor_get name value
assert_eq "$TUISH_ACTOR_VALUE" 'João' 'UTF-8 value is preserved'
tuish_actor_get name cursor_position
assert_eq "$TUISH_ACTOR_VALUE" 4 'UTF-8 cursor counts grapheme clusters rather than bytes'
tuish_text_input_set name 'éx'
tuish_actor_get name cursor_position
assert_eq "$TUISH_ACTOR_VALUE" 2 'combining mark stays in the preceding grapheme'
tuish_text_input_backspace name
tuish_actor_get name value
assert_eq "$TUISH_ACTOR_VALUE" 'é' 'backspace removes one complete grapheme'
tuish_text_input_set name '👨‍👩‍👧‍👦'
tuish_actor_get name cursor_position
assert_eq "$TUISH_ACTOR_VALUE" 1 'ZWJ emoji sequence is one grapheme'
tuish_text_input_backspace name
tuish_actor_get name value
assert_eq "$TUISH_ACTOR_VALUE" '' 'backspace removes complete ZWJ emoji sequence'
tuish_text_input_create secret 'Password' 0 '*'
tuish_text_input_set secret 'abc'
_rendered="$(tuish_text_input_render secret)"
assert_eq "$_rendered" '***' 'masking hides the stored value'
tuish_text_input_focus secret 1
tuish_actor_get secret focus_state
assert_eq "$TUISH_ACTOR_VALUE" 1 'focus state is stored'
tuish_actor_action secret input 'xyz'
tuish_actor_get secret value
assert_eq "$TUISH_ACTOR_VALUE" xyz 'Actor action delegates to TextInput adapter'
tuish_actor_destroy name
tuish_actor_destroy secret
test_summary
