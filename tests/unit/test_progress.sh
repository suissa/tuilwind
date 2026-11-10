#!/bin/sh

# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/actor.sh"
. "$TESTS_DIR/../src/progress.sh"

printf 'Unit tests: progress Actor\n'

tuish_progress_create build 10 Build
tuish_actor_get build kind
assert_eq "$TUISH_ACTOR_VALUE" progress "progress actor type"
tuish_progress_set build 45
tuish_actor_get build percent
assert_eq "$TUISH_ACTOR_VALUE" 45 "percentage update"
tuish_progress_set build -5
tuish_actor_get build percent
assert_eq "$TUISH_ACTOR_VALUE" 0 "percentage clamps at zero"
tuish_progress_set build 150
tuish_actor_get build percent
assert_eq "$TUISH_ACTOR_VALUE" 100 "percentage clamps at one hundred"
tuish_progress_set build 50
_render=$(tuish_progress_render build)
assert_eq "$_render" 'Build [#####-----] 50%' "bar rendering"
tuish_progress_tick build
tuish_actor_get build animation_state
assert_eq "$TUISH_ACTOR_VALUE" 1 "animation tick advances"
tuish_progress_resize build 5
tuish_actor_get build width
assert_eq "$TUISH_ACTOR_VALUE" 5 "resize updates width"
_status=0
tuish_progress_set build invalid || _status=$?
assert_eq "$_status" 2 "invalid percentage rejected"
_status=0
tuish_progress_resize build 0 || _status=$?
assert_eq "$_status" 2 "zero width rejected"
tuish_actor_destroy build
test_summary
