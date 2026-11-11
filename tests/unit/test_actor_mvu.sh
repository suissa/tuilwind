#!/bin/sh

# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/actor.sh"

_MVU_TRACE=''
_MVU_VIEW=''

_mvu_message () {
	_MVU_TRACE="${_MVU_TRACE}message:$2;"
	if test "$2" = ping; then tuish_actor_post "$1" pong; fi
}
_mvu_update () { _MVU_TRACE="${_MVU_TRACE}update:$2;"; tuish_actor_cmd "$1" redraw; }
_mvu_view () { _MVU_VIEW="$1:$2"; }
_mvu_effect () { _MVU_TRACE="${_MVU_TRACE}effect:$2;"; }
_mvu_child () { _MVU_TRACE="${_MVU_TRACE}child:$2;"; }
_mvu_init () { _MVU_TRACE="${_MVU_TRACE}init:$1;"; }
_mvu_shutdown () { _MVU_TRACE="${_MVU_TRACE}shutdown:$1;"; }

printf 'Unit tests: Elm/MVU Actor mailbox broker\n'
tuish_actor_create root list
tuish_actor_get root actor_id
assert_eq "$TUISH_ACTOR_VALUE" root 'Actor stores its stable ID'
tuish_actor_get root parent_id
assert_eq "$TUISH_ACTOR_VALUE" '' 'root has no parent ID'
tuish_actor_create leaf list root
tuish_actor_get leaf parent_id
assert_eq "$TUISH_ACTOR_VALUE" root 'child stores its parent ID'
tuish_actor_program root _mvu_message _mvu_update _mvu_view _mvu_effect _mvu_child _mvu_init _mvu_shutdown
tuish_actor_program leaf _mvu_message _mvu_update _mvu_view _mvu_effect
assert_contains "$_MVU_TRACE" 'init:root;' 'program registers init lifecycle callback'
assert_contains "$_MVU_TRACE" 'init:leaf;' 'child initializes independently'

_MVU_TRACE=''
tuish_actor_send root ping
assert_eq "$_MVU_TRACE" 'message:ping;update:ping;effect:redraw;message:pong;update:pong;effect:redraw;' 'nested posts are FIFO and dispatch is non-reentrant'

tuish_actor_render root dashboard
assert_eq "$_MVU_VIEW" 'root:dashboard' 'view callback is invoked separately from update'

_MVU_TRACE=''
tuish_actor_send_child leaf selected
assert_eq "$_MVU_TRACE" 'child:leaf|selected;update:child:leaf|selected;effect:redraw;' 'child messages route to parent and update its state'

tuish_actor_post root deferred
assert_eq "$TUISH_ACTOR_SEQUENCE" 4 'posting does not synchronously dispatch'
tuish_actor_dispatch
assert_contains "$_MVU_TRACE" 'message:deferred;' 'explicit dispatch drains posted messages'

_MVU_TRACE=''
tuish_actor_destroy root
assert_contains "$_MVU_TRACE" 'shutdown:root;' 'shutdown callback runs on destroy'
tuish_actor_get leaf lifecycle
assert_eq "$TUISH_ACTOR_VALUE" running 'destroying parent does not implicitly destroy a child'
tuish_actor_destroy leaf

# Values that would corrupt the line protocol are rejected before enqueue.
tuish_actor_create safe list
_status=0
tuish_actor_post safe 'invalid|message' || _status=$?
assert_eq "$_status" 2 'mailbox rejects record separators'
tuish_actor_post safe 'invalid
message' || _status=$?
assert_eq "$_status" 2 'mailbox rejects multiline messages'
tuish_actor_destroy safe
test_summary
