#!/bin/sh

# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/actor.sh"

_actor_test_callback () { ACTOR_CALLBACK="$1:$2"; }
printf 'Unit tests: Actor runtime and component behaviors\n'

for kind in progress slide-motion table tree split-view text-input text-area viewport spinner tabs mouse-adapter fullscreen command-launcher list help keymap cursor confirm-dialog file-picker timer paginator markdown code-editor bics-plugin bics-plugin-cli
do
	id="actor_$kind"
	tuish_actor_create "$id" "$kind" || { assert_eq failed created "$kind registers"; continue; }
	tuish_actor_get "$id" kind
	assert_eq "$TUISH_ACTOR_VALUE" "$kind" "$kind registered with its own type"
	tuish_actor_on "$id" message _actor_test_callback
	tuish_actor_start "$id"
	tuish_actor_get "$id" lifecycle
	assert_eq "$TUISH_ACTOR_VALUE" running "$kind starts"
	tuish_actor_send "$id" ping
	assert_eq "$ACTOR_CALLBACK" "$id:ping" "$kind receives messages"
	tuish_actor_set "$id" item_count 3
	tuish_actor_step "$id" next
	tuish_actor_get "$id" selected_index
	assert_eq "$TUISH_ACTOR_VALUE" 1 "$kind next selection"
	case "$kind" in
		progress) tuish_actor_action "$id" set 42; tuish_actor_get "$id" percent; assert_eq "$TUISH_ACTOR_VALUE" 42 "progress updates percentage";;
		slide-motion) tuish_actor_action "$id" seek 12; tuish_actor_get "$id" current_frame; assert_eq "$TUISH_ACTOR_VALUE" 12 "slide motion seeks frame";;
		table|list|tabs|command-launcher) tuish_actor_action "$id" filter active; tuish_actor_get "$id" filter; assert_eq "$TUISH_ACTOR_VALUE" active "$kind filters";;
		tree|help) tuish_actor_action "$id" toggle; tuish_actor_get "$id" expanded; assert_eq "$TUISH_ACTOR_VALUE" 1 "$kind toggles state";;
		split-view) tuish_actor_action "$id" ratio 60; tuish_actor_get "$id" split_ratio; assert_eq "$TUISH_ACTOR_VALUE" 60 "split view ratio";;
		text-input|text-area|code-editor) tuish_actor_action "$id" input hello; tuish_actor_get "$id" value; assert_eq "$TUISH_ACTOR_VALUE" hello "$kind accepts text";;
		viewport) tuish_actor_action "$id" scroll 3; tuish_actor_get "$id" offset; assert_eq "$TUISH_ACTOR_VALUE" 3 "viewport scrolls";;
		spinner) tuish_actor_action "$id" tick; tuish_actor_get "$id" frame_index; assert_eq "$TUISH_ACTOR_VALUE" 1 "spinner advances";;
		mouse-adapter) tuish_actor_action "$id" position 4,8; tuish_actor_get "$id" pointer; assert_eq "$TUISH_ACTOR_VALUE" 4,8 "mouse stores pointer";;
		fullscreen) tuish_actor_action "$id" enter; tuish_actor_get "$id" active; assert_eq "$TUISH_ACTOR_VALUE" 1 "fullscreen enters";;
		keymap) tuish_actor_action "$id" bind ctrl-x; tuish_actor_get "$id" binding; assert_eq "$TUISH_ACTOR_VALUE" ctrl-x "keymap binds";;
		cursor) tuish_actor_action "$id" move 3,2; tuish_actor_get "$id" position; assert_eq "$TUISH_ACTOR_VALUE" 3,2 "cursor moves";;
		confirm-dialog) tuish_actor_action "$id" confirm; tuish_actor_get "$id" result; assert_eq "$TUISH_ACTOR_VALUE" confirmed "confirm dialog resolves";;
		file-picker) tuish_actor_action "$id" navigate /tmp; tuish_actor_get "$id" path; assert_eq "$TUISH_ACTOR_VALUE" /tmp "file picker navigates";;
		timer) tuish_actor_set "$id" remaining_ms 500; tuish_actor_action "$id" tick 100; tuish_actor_get "$id" remaining_ms; assert_eq "$TUISH_ACTOR_VALUE" 400 "timer ticks";;
		paginator) tuish_actor_action "$id" next; tuish_actor_get "$id" page; assert_eq "$TUISH_ACTOR_VALUE" 1 "paginator advances";;
		markdown) tuish_actor_action "$id" source '# title'; tuish_actor_get "$id" source; assert_eq "$TUISH_ACTOR_VALUE" '# title' "markdown source updates";;
		bics-plugin) tuish_actor_action "$id" register; tuish_actor_get "$id" plugin_state; assert_eq "$TUISH_ACTOR_VALUE" registered "BICS plugin registers";;
		bics-plugin-cli) tuish_actor_action "$id" validate; tuish_actor_get "$id" cli_action; assert_eq "$TUISH_ACTOR_VALUE" validate "BICS plugin CLI action";;
	esac
	tuish_actor_destroy "$id"
	case " $TUISH_ACTORS " in *" $id "*) assert_eq present absent "$kind destroyed";; *) assert_eq absent absent "$kind destroyed";; esac
done

# Defensive validation: parent IDs, duplicate IDs, record delimiters, and numbers.
_actor_status=0
tuish_actor_create orphan list missing_parent || _actor_status=$?
assert_eq "$_actor_status" 4 "unknown parent is rejected"
tuish_actor_create parent list
_actor_status=0
tuish_actor_create parent list || _actor_status=$?

assert_eq "$_actor_status" 3 "duplicate actor IDs are rejected"
tuish_actor_create child slide-motion parent
_actor_status=0
tuish_actor_set child unsafe "bad|record" || _actor_status=$?

assert_eq "$_actor_status" 2 "record separators are rejected"
_actor_status=0
tuish_actor_action child seek "1; touch /tmp/pwned" || _actor_status=$?

assert_eq "$_actor_status" 2 "non-numeric seek is rejected"
tuish_actor_destroy child
tuish_actor_destroy parent

tuish_actor_create demo list
tuish_actor_set demo item_count 2
tuish_actor_step demo select 1
tuish_actor_get demo selected_index
assert_eq "$TUISH_ACTOR_VALUE" 1 "explicit selection updates index"
tuish_actor_step demo progress 50
_tuish_step_status=0
tuish_actor_step demo progress 150 || _tuish_step_status=$?
assert_eq "$_tuish_step_status" 2 "invalid progress is rejected"
tuish_actor_count
assert_eq "$TUISH_ACTOR_COUNT" 1 "actor registry count"
tuish_actor_destroy demo
test_summary
