#!/bin/sh

# SPDX-License-Identifier: ISC
# Live system/server dashboard with a small managed-agent registry.
# Run: sh examples/agent_dashboard.sh

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$ROOT/src/compat.sh"
. "$ROOT/src/ord.sh"
. "$ROOT/src/tui.sh"
. "$ROOT/src/term.sh"
. "$ROOT/src/event.sh"
. "$ROOT/src/hid.sh"
. "$ROOT/src/keybind.sh"
. "$ROOT/src/viewport.sh"
. "$ROOT/src/actor.sh"
. "$ROOT/src/monitor.sh"

_DASH_TICK=0
_DASH_AGENT_NAMES='api-worker queue-consumer scheduler'
_DASH_AGENT_STATES='running running idle'
_DASH_SELECTED=0
_DASH_STOP=0

_dash_agent_action () {
	case "$1" in
		0) _DASH_AGENT_STATES='stopped running idle';;
		1) _DASH_AGENT_STATES='running stopped idle';;
		2) _DASH_AGENT_STATES='running running stopped';;
	esac
}

_dash_render () {
	tuish_monitor_snapshot
	tuish_begin
	tuish_clear_screen
	tuish_vmove 1 2; tuish_text "TUILWIND / ACTOR CONTROL PLANE"
	tuish_vmove 2 2; tuish_text "HOST: $TUISH_MON_HOST   OS: $TUISH_MON_OS   UPTIME: $TUISH_MON_UPTIME"
	tuish_vmove 4 2; tuish_text "SYSTEM"
	tuish_vmove 5 4; tuish_text "Load: $TUISH_MON_LOAD"
	tuish_vmove 6 4; tuish_text "Memory: $TUISH_MON_MEM"
	tuish_vmove 7 4; tuish_text "Processes: $TUISH_MON_PROCS"
	tuish_vmove 9 2; tuish_text "SERVER"
	tuish_vmove 10 4; tuish_text "Terminal: ${TUISH_COLUMNS}x${TUISH_LINES}   Shell: ${SHELL:-unknown}"
	tuish_vmove 11 4; tuish_text "PID: $$   Refresh: 1s"
	tuish_vmove 13 2; tuish_text "AGENT MANAGER"
	tuish_vmove 14 4; tuish_text "ID              STATE       ACTION"
	_i=0
	for _name in $_DASH_AGENT_NAMES
	do
		set -- $_DASH_AGENT_STATES
		_state=''
		_j=0
		for _s in "$@"; do test $_j -eq $_i && _state=$_s; _j=$((_j + 1)); done
		_marker=' '
		test $_DASH_SELECTED -eq $_i && _marker='>'
		tuish_vmove $((15 + _i)) 4; tuish_text "$_marker $_name"
		tuish_vmove $((15 + _i)) 21; tuish_text "$_state"
		tuish_vmove $((15 + _i)) 33; tuish_text "[$((_i + 1))] toggle"
		_i=$((_i + 1))
	done
	tuish_vmove 20 2; tuish_text "↑/↓ select   Enter toggle state   R refresh   Q quit"
	tuish_end
}

_dash_next () { _DASH_SELECTED=$(( (_DASH_SELECTED + 1) % 3 )); tuish_request_redraw; }
_dash_prev () { _DASH_SELECTED=$(( (_DASH_SELECTED + 2) % 3 )); tuish_request_redraw; }
_dash_toggle () {
	case "$_DASH_SELECTED" in
		0) case "$_DASH_AGENT_STATES" in 'stopped running idle'*) _DASH_AGENT_STATES='running running idle';; *) _DASH_AGENT_STATES='stopped running idle';; esac;;
		1) case "$_DASH_AGENT_STATES" in *'running stopped idle'*) _DASH_AGENT_STATES='running running idle';; *) _DASH_AGENT_STATES='running stopped idle';; esac;;
		2) case "$_DASH_AGENT_STATES" in *'running running stopped'*) _DASH_AGENT_STATES='running running idle';; *) _DASH_AGENT_STATES='running running stopped';; esac;;
	esac
	tuish_request_redraw
}
_dash_refresh () { tuish_request_redraw; }
_dash_quit () { tuish_quit; }

tuish_bind up _dash_prev
tuish_bind down _dash_next
tuish_bind enter _dash_toggle
tuish_bind char r _dash_refresh
tuish_bind char q _dash_quit
tuish_bind ctrl-c _dash_quit
tuish_bind idle _dash_refresh
tuish_bind resize _dash_refresh
tuish_bind signal _dash_quit
tuish_bind idle _dash_render

tuish_start
