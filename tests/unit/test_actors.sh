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
	tuish_actor_destroy "$id"
	case " $TUISH_ACTORS " in *" $id "*) assert_eq present absent "$kind destroyed";; *) assert_eq absent absent "$kind destroyed";; esac
done

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
