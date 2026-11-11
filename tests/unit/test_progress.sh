#!/bin/sh

# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/actor.sh"
. "$TESTS_DIR/../src/progress.sh"

_progress_callback () { PROGRESS_CALLBACK="$1:$2"; }
_progress_tick () { PROGRESS_TICK="$1:$2"; }
_progress_render () { PROGRESS_RENDER="$1:$2"; }
_progress_resize () { PROGRESS_RESIZE="$1:$2"; }
printf 'Unit tests: progress Actor\n'

tuish_progress_create build 10 Build
tuish_actor_on build progress_change _progress_callback
tuish_actor_on build tick _progress_tick
tuish_actor_on build render _progress_render
tuish_actor_on build resize _progress_resize
tuish_actor_get build kind
assert_eq "$TUISH_ACTOR_VALUE" progress "progress actor type"
tuish_progress_set build 45
tuish_actor_get build percent
assert_eq "$TUISH_ACTOR_VALUE" 45 "percentage update"
assert_eq "$PROGRESS_CALLBACK" build:45 "progress change callback"
tuish_progress_set build -5
tuish_actor_get build percent
assert_eq "$TUISH_ACTOR_VALUE" 0 "percentage clamps at zero"
tuish_progress_set build 150
tuish_actor_get build percent
assert_eq "$TUISH_ACTOR_VALUE" 100 "percentage clamps at one hundred"
tuish_progress_set build 50
_render=$(tuish_progress_render build)
assert_eq "$_render" 'Build [#####>----] 50%' "bar rendering"
assert_eq "$PROGRESS_RENDER" build: "render callback fires"
tuish_progress_start build
tuish_progress_start build
tuish_actor_get build lifecycle
assert_eq "$TUISH_ACTOR_VALUE" running "start is idempotent"
tuish_progress_tick build
tuish_actor_get build animation_state
assert_eq "$TUISH_ACTOR_VALUE" 1 "animation tick advances"
assert_eq "$PROGRESS_TICK" build:1 "tick callback receives frame"
_render=$(tuish_progress_render build)
assert_eq "$_render" 'Build [#####->---] 50%' "tick animates pending segment"
tuish_progress_resize build 5
tuish_actor_get build width
assert_eq "$TUISH_ACTOR_VALUE" 5 "resize updates width"
assert_eq "$PROGRESS_RESIZE" build:5 "resize callback receives width"
tuish_progress_stop build
tuish_progress_stop build
tuish_actor_get build lifecycle
assert_eq "$TUISH_ACTOR_VALUE" stopped "stop is idempotent"
tuish_progress_tick build
tuish_actor_get build animation_state
assert_eq "$TUISH_ACTOR_VALUE" 1 "stopped actor ignores ticks"
_status=0
tuish_progress_set build invalid || _status=$?
assert_eq "$_status" 2 "invalid percentage rejected"
_status=0
tuish_progress_resize build 0 || _status=$?
assert_eq "$_status" 2 "zero width rejected"
tuish_actor_destroy build
test_summary
