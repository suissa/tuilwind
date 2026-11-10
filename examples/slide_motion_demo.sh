#!/bin/sh

# SPDX-License-Identifier: ISC
# Interactive SlideMotion demo. Enter n/p/w/r/q then press Enter.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$ROOT/src/actor.sh"
. "$ROOT/src/slide_motion.sh"

tuish_motion_create tour 10000 11 "Timeline"
tuish_motion_enter tour

_motion_show () {
	printf '\r\033[2K'
	tuish_motion_render tour
	printf '\n'
}

_motion_show
printf 'Commands: n=advance 1s, p=previous frame, w=wait, r=resume, q=quit\n'
while IFS= read -r _command
do
	case "$_command" in
		n) tuish_motion_advance tour 1000 || :;;
		p)
			tuish_actor_get tour current_frame || break
			_frame=$TUISH_ACTOR_VALUE
			test "$_frame" -gt 0 && _frame=$((_frame - 1))
			tuish_motion_scrub tour "$_frame" || :
			;;
		w) tuish_motion_wait tour || :;;
		r) tuish_motion_resume tour || :;;
		q) tuish_motion_exit tour || :; break;;
		*) printf 'Unknown command: %s\n' "$_command";;
	esac
	_motion_show
done

tuish_actor_destroy tour
