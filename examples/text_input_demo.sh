#!/bin/sh
# Single-line TextInput Actor demonstration.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/src/compat.sh"
. "$ROOT/src/ord.sh"
. "$ROOT/src/tui.sh"
. "$ROOT/src/str.sh"
. "$ROOT/src/actor.sh"
. "$ROOT/src/text_input.sh"

tuish_text_input_create username 'Username' 32
tuish_text_input_focus username 1
tuish_text_input_set username 'suissa'
printf 'TextInput: '
tuish_text_input_render username
printf '\nMove left twice and insert !: '
tuish_text_input_move username -2
tuish_text_input_insert username '!'
tuish_text_input_render username
printf '\nPaste is inserted as text, never dispatched as key bindings.\n'
tuish_actor_destroy username
