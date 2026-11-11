#!/usr/bin/env bash

# SPDX-License-Identifier: ISC
# Standalone progress Actor demonstration. The event clock belongs to this demo.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$ROOT/src/actor.sh"
. "$ROOT/src/progress.sh"

_progress_redraw () {
	printf '\r'
	tuish_progress_render "$1"
}
_progress_tick_event () {
	tuish_progress_tick "$1"
	_progress_redraw "$1"
}
_progress_resize_event () {
	local _cols
	_cols=$(stty size 2>/dev/null | awk '{print $2}')
	case "$_cols" in ''|*[!0-9]*) return 0;; esac
	_cols=$((_cols - 10))
	test "$_cols" -lt 1 && _cols=1
	test "$_cols" -gt 200 && _cols=200
	tuish_progress_resize "$1" "$_cols"
	_progress_redraw "$1"
}
_progress_cleanup () {
	tuish_progress_stop download 2>/dev/null || :
	printf '\n'
	tuish_actor_destroy download 2>/dev/null || :
}
_progress_key () {
	case "$1" in
		q|Q) _progress_done=1;;
		+) tuish_actor_get download percent; _p=$((TUISH_ACTOR_VALUE + 5)); tuish_progress_set download "$_p"; _progress_redraw download;;
		-) tuish_actor_get download percent; _p=$((TUISH_ACTOR_VALUE - 5)); tuish_progress_set download "$_p"; _progress_redraw download;;
	esac
}
tuish_progress_create download 30 "Download"
tuish_actor_on download tick _progress_tick_event
tuish_actor_on download resize _progress_resize_event
tuish_progress_start download

if test ! -t 1 || test ! -t 0
then
	tuish_progress_set download 65
	tuish_progress_render download
	printf '\n'
	_progress_cleanup
	exit 0
fi

_progress_done=0
_progress_value=0
_progress_old_stty=$(stty -g 2>/dev/null) || _progress_old_stty=''
trap '_progress_cleanup; test -z "$_progress_old_stty" || stty "$_progress_old_stty" 2>/dev/null || :' EXIT HUP INT TERM
trap '_progress_resize_event download' WINCH
stty -echo -icanon min 0 time 1 2>/dev/null || :
printf '  [+/-] change progress  [q] quit\n'
while test "$_progress_done" -eq 0
do
	if IFS= read -r -n 1 _key 2>/dev/null
	then
		_progress_key "$_key"
	else
		_progress_value=$((_progress_value + 1))
		test "$_progress_value" -le 100 || _progress_value=0
		tuish_progress_set download "$_progress_value"
		tuish_progress_tick download
		_progress_redraw download
	fi
done
_progress_cleanup
trap - EXIT HUP INT TERM WINCH
test -z "$_progress_old_stty" || stty "$_progress_old_stty" 2>/dev/null || :
