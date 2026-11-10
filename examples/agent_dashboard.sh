#!/bin/sh

# SPDX-License-Identifier: ISC
# Live system/server dashboard and managed heartbeat-agent processes.
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

_DASH_SELECTED=0
_DASH_AGENT_NAMES='api-worker queue-consumer scheduler'
_DASH_PID_0=''
_DASH_PID_1=''
_DASH_PID_2=''

_dash_agent_pid () {
	case "$1" in
		0) TUISH_AGENT_PID=$_DASH_PID_0;;
		1) TUISH_AGENT_PID=$_DASH_PID_1;;
		2) TUISH_AGENT_PID=$_DASH_PID_2;;
		*) TUISH_AGENT_PID=''; return 1;;
	esac
}
_dash_agent_start () {
	( trap 'exit 0' TERM INT; while :; do sleep 2; done ) >/dev/null 2>&1 &
	case "$1" in 0) _DASH_PID_0=$!;; 1) _DASH_PID_1=$!;; 2) _DASH_PID_2=$!;; esac
}
_dash_agent_stop () {
	_dash_agent_pid "$1"
	if test -n "$TUISH_AGENT_PID"
	then kill "$TUISH_AGENT_PID" 2>/dev/null || :; wait "$TUISH_AGENT_PID" 2>/dev/null || :; fi
	case "$1" in 0) _DASH_PID_0=''; tuish_actor_stop api_worker;; 1) _DASH_PID_1=''; tuish_actor_stop queue_consumer;; 2) _DASH_PID_2=''; tuish_actor_stop scheduler;; esac
}
_dash_agent_toggle () {
	_dash_agent_pid "$_DASH_SELECTED"
	if test -n "$TUISH_AGENT_PID" && kill -0 "$TUISH_AGENT_PID" 2>/dev/null
	then _dash_agent_stop "$_DASH_SELECTED"
	else _dash_agent_start "$_DASH_SELECTED"
	fi
	tuish_request_redraw
}
_dash_cleanup () { _dash_agent_stop 0; _dash_agent_stop 1; _dash_agent_stop 2; }

_dash_render () {
	tuish_monitor_snapshot
	tuish_begin
	tuish_clear_screen
	tuish_vmove 1 2; tuish_text "TUILWIND / ACTOR CONTROL PLANE"
	tuish_vmove 2 2; tuish_text "HOST: $TUISH_MON_HOST   OS: $TUISH_MON_OS   UPTIME: $TUISH_MON_UPTIME"
	tuish_vmove 4 2; tuish_text "SYSTEM"
	tuish_vmove 5 4; tuish_text "Load average: $TUISH_MON_LOAD"
	tuish_vmove 6 4; tuish_text "Memory: $TUISH_MON_MEM"
	tuish_vmove 7 4; tuish_text "Processes: $TUISH_MON_PROCS"
	tuish_vmove 9 2; tuish_text "SERVER / SESSION"
	tuish_vmove 10 4; tuish_text "Terminal: ${TUISH_COLUMNS}x${TUISH_LINES}   Shell: ${SHELL:-unknown}"
	tuish_vmove 11 4; tuish_text "Dashboard PID: $$   Refresh interval: 1s"
	tuish_vmove 13 2; tuish_text "AGENT MANAGER (heartbeat workers)"
	tuish_vmove 14 4; tuish_text "AGENT           STATE       PID"
	_i=0
	for _name in $_DASH_AGENT_NAMES
	do
		_dash_agent_pid "$_i"
		_pid=$TUISH_AGENT_PID
		_state=STOPPED
		if test -n "$_pid" && kill -0 "$_pid" 2>/dev/null; then _state=RUNNING; else _pid='-'; fi
		_marker=' '
		test "$_DASH_SELECTED" -eq "$_i" && _marker='>'
		tuish_vmove $((15 + _i)) 4; tuish_text "$_marker $_name"
		tuish_vmove $((15 + _i)) 21; tuish_text "$_state"
		tuish_vmove $((15 + _i)) 33; tuish_text "$_pid"
		_i=$((_i + 1))
	done
	tuish_vmove 20 2; tuish_text "UP/DOWN select   ENTER start/stop   R refresh   Q quit"
	tuish_end
}
_dash_next () { _DASH_SELECTED=$(( (_DASH_SELECTED + 1) % 3 )); tuish_request_redraw; }
_dash_prev () { _DASH_SELECTED=$(( (_DASH_SELECTED + 2) % 3 )); tuish_request_redraw; }
_dash_refresh () { tuish_request_redraw; }
_dash_quit () { tuish_quit; }

_dash_agent_start 0
_dash_agent_start 1
_dash_agent_start 2
tuish_bind up _dash_prev
tuish_bind down _dash_next
tuish_bind enter _dash_agent_toggle
tuish_bind char r _dash_refresh
tuish_bind char q _dash_quit
tuish_bind ctrl-c _dash_quit
tuish_bind idle _dash_render
tuish_bind signal _dash_quit
tuish_bind resize _dash_refresh

tuish_start
_dash_cleanup
