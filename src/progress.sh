#!/bin/sh

# SPDX-License-Identifier: ISC
# src/progress.sh - portable, event-driven animated progress Actor.
# Source after actor.sh. The caller owns the clock/event loop; this module never
# starts a timer, subprocess, or background job.

if test -n "${_tuish_progress_loaded:-}"; then return 0; fi
_tuish_progress_loaded=1

tuish_progress_create () {
	local _id=$1 _width=${2:-20} _label=${3:-}
	_tuish_actor_is_uint "$_width" && test "$_width" -ge 1 && test "$_width" -le 200 || return 2
	tuish_actor_create "$_id" progress || return
	tuish_actor_set "$_id" width "$_width" || return
	tuish_actor_set "$_id" label "$_label" || return
	tuish_actor_set "$_id" percent 0 || return
	tuish_actor_set "$_id" animation_state 0 || return
	tuish_actor_set "$_id" animation_active 0
}

tuish_progress_set () {
	local _id=$1 _percent=$2
	case "$_percent" in ''|*[!0-9-]*) return 2;; esac
	case "$_percent" in -[0-9]*) _tuish_actor_is_uint "${_percent#-}" || return 2;; *-*) return 2;; esac
	test "$_percent" -lt 0 && _percent=0
	test "$_percent" -gt 100 && _percent=100
	tuish_actor_action "$_id" set "$_percent" || return
	tuish_actor_emit "$_id" progress_change "$_percent"
}

tuish_progress_resize () {
	local _id=$1 _width=$2
	_tuish_actor_is_uint "$_width" && test "$_width" -ge 1 && test "$_width" -le 200 || return 2
	tuish_actor_set "$_id" width "$_width" || return
	tuish_actor_emit "$_id" resize "$_width"
}

# Start/stop only change Actor lifecycle. The application/event loop decides
# when to call tick; this keeps animation deterministic and shell-portable.
tuish_progress_start () {
	local _id=$1
	tuish_actor_get "$_id" animation_active || return
	test "$TUISH_ACTOR_VALUE" = 1 && return 0
	tuish_actor_set "$_id" animation_active 1 || return
	tuish_actor_start "$_id"
}

tuish_progress_stop () {
	local _id=$1
	tuish_actor_get "$_id" animation_active || return
	test "$TUISH_ACTOR_VALUE" = 0 && return 0
	tuish_actor_set "$_id" animation_active 0 || return
	tuish_actor_stop "$_id"
}

tuish_progress_tick () {
	local _id=$1 _width _frame _active
	tuish_actor_get "$_id" width || return
	_width=$TUISH_ACTOR_VALUE
	_tuish_actor_is_uint "$_width" && test "$_width" -gt 0 || return 2
	tuish_actor_get "$_id" animation_active || :; _active=${TUISH_ACTOR_VALUE:-0}
	test "$_active" = 1 || return 0
	tuish_actor_get "$_id" animation_state || :
	_frame=${TUISH_ACTOR_VALUE:-0}
	_tuish_actor_is_uint "$_frame" || return 2
	_frame=$(( (_frame + 1) % _width ))
	tuish_actor_set "$_id" animation_state "$_frame" || return
	tuish_actor_emit "$_id" tick "$_frame"
}

tuish_progress_render () {
	local _id=$1 _label _width _percent _filled _empty _i _color='' _frame=0 _marker=-1
	tuish_actor_emit "$_id" render || return
	tuish_actor_get "$_id" label || :; _label=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" width || return; _width=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" percent || :; _percent=${TUISH_ACTOR_VALUE:-0}
	_tuish_actor_is_uint "$_width" && test "$_width" -gt 0 || return 2
	_tuish_actor_is_uint "$_percent" && test "$_percent" -le 100 || return 2
	_filled=$(( _width * _percent / 100 ))
	_empty=$(( _width - _filled ))
	tuish_actor_get "$_id" animation_state || :; _frame=${TUISH_ACTOR_VALUE:-0}
	_tuish_actor_is_uint "$_frame" || return 2
	if test "$_empty" -gt 0; then _marker=$(( _filled + (_frame % _empty) )); fi
	tuish_actor_get "$_id" start_color || :; _color=$TUISH_ACTOR_VALUE
	if test "$_percent" -eq 100
	then tuish_actor_get "$_id" end_color || :; _color=$TUISH_ACTOR_VALUE; fi
	case "$_color" in *[!0-9\;]*) test -z "$_color" || return 2;; esac
	printf '%s' "$_label"
	test -z "$_label" || printf ' '
	if test -n "$_color"; then printf '\033[%sm' "$_color"; fi
	printf '['
	_i=0
	while test "$_i" -lt "$_filled"; do printf '#'; _i=$((_i + 1)); done
	_i=0
	while test "$_i" -lt "$_empty"
	do
		if test "$_marker" -eq $((_filled + _i)); then printf '>'; else printf '-'; fi
		_i=$((_i + 1))
	done
	printf ']'
	if test -n "$_color"; then printf '\033[0m'; fi
	printf ' %s%%' "$_percent"
}
