#!/bin/sh

# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/actor.sh"
. "$TESTS_DIR/../src/slide_motion.sh"

_motion_callback () { MOTION_CALLBACK="$1:$2"; }
printf 'Unit tests: SlideMotion timeline and scrubbing Actor\n'

tuish_motion_create intro 1000 11 Intro
tuish_actor_on intro enter _motion_callback
tuish_actor_on intro advance _motion_callback
tuish_actor_on intro scrub _motion_callback
tuish_actor_on intro wait _motion_callback
tuish_actor_on intro finish _motion_callback
tuish_actor_on intro exit _motion_callback
tuish_actor_on intro resize _motion_callback

tuish_actor_get intro kind
assert_eq "$TUISH_ACTOR_VALUE" slide-motion "motion actor type"
tuish_actor_get intro phase
assert_eq "$TUISH_ACTOR_VALUE" idle "new timeline starts idle"
tuish_motion_enter intro
tuish_actor_get intro phase
assert_eq "$TUISH_ACTOR_VALUE" running "enter starts timeline"
assert_eq "$MOTION_CALLBACK" intro: "enter callback"

tuish_motion_advance intro 250
tuish_actor_get intro elapsed_ms
assert_eq "$TUISH_ACTOR_VALUE" 250 "advance tracks elapsed milliseconds"
tuish_actor_get intro current_frame
assert_eq "$TUISH_ACTOR_VALUE" 2 "time maps deterministically to frame"
assert_eq "$MOTION_CALLBACK" intro:2 "advance callback receives frame"

tuish_actor_action intro seek 8
tuish_actor_get intro current_frame
assert_eq "$TUISH_ACTOR_VALUE" 8 "Actor seek delegates to scrub adapter"
tuish_actor_get intro elapsed_ms
assert_eq "$TUISH_ACTOR_VALUE" 800 "scrub maps frame back to time"
assert_eq "$MOTION_CALLBACK" intro:8 "scrub callback receives frame"

tuish_motion_scrub intro 999
tuish_actor_get intro current_frame
assert_eq "$TUISH_ACTOR_VALUE" 10 "scrub clamps at final frame"
tuish_actor_get intro elapsed_ms
assert_eq "$TUISH_ACTOR_VALUE" 1000 "last frame maps to timeline duration"

tuish_motion_scrub intro 0
tuish_motion_wait intro
tuish_actor_get intro phase
assert_eq "$TUISH_ACTOR_VALUE" waiting "wait pauses timeline"
assert_eq "$MOTION_CALLBACK" intro: "wait callback"
_status=0
tuish_motion_advance intro 100 || _status=$?
assert_eq "$_status" 2 "waiting timeline does not advance"
tuish_motion_resume intro
tuish_actor_get intro phase
assert_eq "$TUISH_ACTOR_VALUE" running "resume restarts timeline"

tuish_actor_action intro advance 500
tuish_actor_get intro current_frame
assert_eq "$TUISH_ACTOR_VALUE" 5 "advance uses bounded integer frame mapping"
tuish_actor_action intro advance 900
tuish_actor_get intro phase
assert_eq "$TUISH_ACTOR_VALUE" finished "duration boundary finishes timeline"
tuish_actor_get intro current_frame
assert_eq "$TUISH_ACTOR_VALUE" 10 "finish lands on final frame"
assert_eq "$MOTION_CALLBACK" intro:10 "finish callback receives final frame"
_status=0
tuish_motion_advance intro 1 || _status=$?
assert_eq "$_status" 2 "finished timeline cannot advance again"

tuish_motion_create resized 1000 5 Resize
tuish_actor_on resized resize _motion_callback
tuish_motion_enter resized
tuish_motion_advance resized 500
tuish_motion_resize resized 9
tuish_actor_get resized current_frame
assert_eq "$TUISH_ACTOR_VALUE" 4 "resize preserves elapsed time and remaps frame"
assert_eq "$MOTION_CALLBACK" resized:9 "resize callback receives frame count"
_render=$(tuish_motion_render resized)
assert_eq "$_render" 'Resize: frame 4/8 500/1000ms [running]' "timeline render is deterministic"
_status=0
tuish_motion_resize resized 0 || _status=$?
assert_eq "$_status" 2 "zero frame count is rejected"

tuish_motion_create single 50 1 Single
tuish_motion_enter single
tuish_motion_advance single 50
tuish_actor_get single current_frame
assert_eq "$TUISH_ACTOR_VALUE" 0 "single-frame timeline remains at frame zero"
tuish_actor_get single phase
assert_eq "$TUISH_ACTOR_VALUE" finished "single-frame timeline can finish"

tuish_motion_create cancelled 100 3 Cancel
tuish_actor_on cancelled exit _motion_callback
tuish_motion_enter cancelled
tuish_motion_cancel cancelled
assert_eq "$MOTION_CALLBACK" cancelled:cancelled "cancel emits exit callback"
tuish_actor_get cancelled phase
assert_eq "$TUISH_ACTOR_VALUE" cancelled "cancel changes timeline phase"
_status=0
tuish_motion_scrub cancelled 1 || _status=$?
assert_eq "$_status" 2 "cancelled timeline rejects scrubbing"
_status=0
tuish_motion_finish cancelled || _status=$?
assert_eq "$_status" 2 "cancelled timeline cannot be finished"

_status=0
tuish_motion_create bad_label 100 3 "bad|label" || _status=$?
assert_eq "$_status" 2 "unsafe labels are rejected before registration"
_status=0
tuish_motion_create leading_zero 010 3 || _status=$?
assert_eq "$_status" 2 "non-canonical numeric input is rejected"

_status=0
tuish_motion_create bad_duration 0 3 || _status=$?
assert_eq "$_status" 2 "zero duration is rejected"
_status=0
tuish_motion_create bad_frames 100 0 || _status=$?
assert_eq "$_status" 2 "zero frame count is rejected"

tuish_actor_destroy intro
tuish_actor_destroy resized
tuish_actor_destroy single
tuish_actor_destroy cancelled
tuish_actor_count
assert_eq "$TUISH_ACTOR_COUNT" 0 "all timeline actors clean up"
test_summary
