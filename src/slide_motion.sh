#!/bin/sh

# SPDX-License-Identifier: ISC
# src/slide_motion.sh - deterministic timeline and scrubbing Actor.
# Source after actor.sh. No timers, sleeps, loops or background processes.

if test -n "${_tuish_slide_motion_loaded:-}"; then return 0; fi
_tuish_slide_motion_loaded=1

_tuish_motion_uint_range () {
	_tuish_actor_is_uint "$1" || return 1
	test "$1" -ge "$2" && test "$1" -le "$3"
}

_tuish_motion_frame_for_time () {
	local _elapsed=$1 _duration=$2 _frames=$3
	if test "$_frames" -le 1; then TUISH_MOTION_FRAME=0
	elif test "$_elapsed" -ge "$_duration"; then TUISH_MOTION_FRAME=$((_frames - 1))
	else TUISH_MOTION_FRAME=$((_elapsed * (_frames - 1) / _duration))
	fi
}

_tuish_motion_time_for_frame () {
	local _frame=$1 _duration=$2 _frames=$3
	if test "$_frames" -le 1; then TUISH_MOTION_TIME=0
	elif test "$_frame" -ge $((_frames - 1)); then TUISH_MOTION_TIME=$_duration
	else TUISH_MOTION_TIME=$((_frame * _duration / (_frames - 1)))
	fi
}

tuish_motion_create () {
	local _id=$1 _duration=$2 _frames=$3 _label=${4:-}
	_tuish_motion_uint_range "$_duration" 1 2147483647 || return 2
	_tuish_motion_uint_range "$_frames" 1 100000 || return 2
	tuish_actor_create "$_id" slide-motion || return
	tuish_actor_set "$_id" duration_ms "$_duration" || return
	tuish_actor_set "$_id" frame_count "$_frames" || return
	tuish_actor_set "$_id" current_frame 0 || return
	tuish_actor_set "$_id" elapsed_ms 0 || return
	tuish_actor_set "$_id" phase idle || return
	tuish_actor_set "$_id" easing_type linear || return
	tuish_actor_set "$_id" scroll_scrub 1 || return
	tuish_actor_set "$_id" label "$_label"
}

tuish_motion_enter () {
	local _id=$1 _phase
	tuish_actor_get "$_id" phase || return
	_phase=$TUISH_ACTOR_VALUE
	case "$_phase" in idle|waiting) ;; *) return 2;; esac
	tuish_actor_set "$_id" phase running || return
	_tuish_actor_emit "$_id" enter ''
}

tuish_motion_wait () {
	local _id=$1 _phase
	tuish_actor_get "$_id" phase || return
	_phase=$TUISH_ACTOR_VALUE
	test "$_phase" = running || return 2
	tuish_actor_set "$_id" phase waiting || return
	_tuish_actor_emit "$_id" wait ''
}

tuish_motion_resume () {
	local _id=$1 _phase
	tuish_actor_get "$_id" phase || return
	_phase=$TUISH_ACTOR_VALUE
	test "$_phase" = waiting || return 2
	tuish_actor_set "$_id" phase running || return
	_tuish_actor_emit "$_id" enter resume
}

tuish_motion_exit () {
	local _id=$1 _phase
	tuish_actor_get "$_id" phase || return
	_phase=$TUISH_ACTOR_VALUE
	case "$_phase" in finished|exited|cancelled) return 2;; esac
	tuish_actor_set "$_id" phase exited || return
	_tuish_actor_emit "$_id" exit ''
}

tuish_motion_cancel () {
	local _id=$1 _phase
	tuish_actor_get "$_id" phase || return
	_phase=$TUISH_ACTOR_VALUE
	case "$_phase" in finished|exited|cancelled) return 2;; esac
	tuish_actor_set "$_id" phase cancelled || return
	_tuish_actor_emit "$_id" exit cancelled
}

tuish_motion_finish () {
	local _id=$1 _duration _frames _last
	tuish_actor_get "$_id" duration_ms || return; _duration=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" frame_count || return; _frames=$TUISH_ACTOR_VALUE
	_last=$((_frames - 1))
	tuish_actor_set "$_id" elapsed_ms "$_duration" || return
	tuish_actor_set "$_id" current_frame "$_last" || return
	tuish_actor_set "$_id" phase finished || return
	_tuish_actor_emit "$_id" advance "$_last"
	_tuish_actor_emit "$_id" finish "$_last"
}

# Advance by an explicit elapsed-time delta. The caller owns the clock; this
# function never sleeps, polls or starts a timer.
tuish_motion_advance () {
	local _id=$1 _delta=$2 _phase _elapsed _duration _frames
	_tuish_motion_uint_range "$_delta" 0 2147483647 || return 2
	tuish_actor_get "$_id" phase || return; _phase=$TUISH_ACTOR_VALUE
	test "$_phase" = running || return 2
	tuish_actor_get "$_id" elapsed_ms || return; _elapsed=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" duration_ms || return; _duration=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" frame_count || return; _frames=$TUISH_ACTOR_VALUE
	_elapsed=$((_elapsed + _delta))
	test "$_elapsed" -le "$_duration" || _elapsed=$_duration
	_tuish_motion_frame_for_time "$_elapsed" "$_duration" "$_frames"
	tuish_actor_set "$_id" elapsed_ms "$_elapsed" || return
	tuish_actor_set "$_id" current_frame "$TUISH_MOTION_FRAME" || return
	_tuish_actor_emit "$_id" advance "$TUISH_MOTION_FRAME"
	if test "$_elapsed" -ge "$_duration"; then
		tuish_actor_set "$_id" phase finished || return
		_tuish_actor_emit "$_id" finish "$TUISH_MOTION_FRAME"
	fi
}

# Scrub to a zero-based frame. Out-of-range frames clamp to the timeline.
tuish_motion_scrub () {
	local _id=$1 _frame=$2 _duration _frames _phase _enabled
	_tuish_actor_is_uint "$_frame" || return 2
	tuish_actor_get "$_id" scroll_scrub || return; _enabled=$TUISH_ACTOR_VALUE
	test "$_enabled" = 1 || return 2
	tuish_actor_get "$_id" phase || return; _phase=$TUISH_ACTOR_VALUE
	case "$_phase" in exited|cancelled) return 2;; esac
	tuish_actor_get "$_id" duration_ms || return; _duration=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" frame_count || return; _frames=$TUISH_ACTOR_VALUE
	test "$_frame" -lt "$_frames" || _frame=$((_frames - 1))
	_tuish_motion_time_for_frame "$_frame" "$_duration" "$_frames"
	tuish_actor_set "$_id" current_frame "$_frame" || return
	tuish_actor_set "$_id" elapsed_ms "$TUISH_MOTION_TIME" || return
	_tuish_actor_emit "$_id" scrub "$_frame"
}

tuish_motion_resize () {
	local _id=$1 _frames=$2 _duration _elapsed
	_tuish_motion_uint_range "$_frames" 1 100000 || return 2
	tuish_actor_get "$_id" duration_ms || return; _duration=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" elapsed_ms || return; _elapsed=$TUISH_ACTOR_VALUE
	tuish_actor_set "$_id" frame_count "$_frames" || return
	_tuish_motion_frame_for_time "$_elapsed" "$_duration" "$_frames"
	tuish_actor_set "$_id" current_frame "$TUISH_MOTION_FRAME" || return
	_tuish_actor_emit "$_id" resize "$_frames"
}

tuish_motion_render () {
	local _id=$1 _label _frame _frames _phase _duration _elapsed
	tuish_actor_get "$_id" label || :; _label=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" current_frame || return; _frame=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" frame_count || return; _frames=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" phase || return; _phase=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" elapsed_ms || return; _elapsed=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" duration_ms || return; _duration=$TUISH_ACTOR_VALUE
	printf '%s%sframe %s/%s %s/%sms [%s]' "$_label" "${_label:+: }" "$_frame" "$((_frames - 1))" "$_elapsed" "$_duration" "$_phase"
}
