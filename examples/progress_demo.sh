#!/bin/sh

# SPDX-License-Identifier: ISC
# Standalone progress Actor demonstration.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$ROOT/src/actor.sh"
. "$ROOT/src/progress.sh"

tuish_progress_create download 30 "Download"
_i=0
while test "$_i" -le 100
do
	tuish_progress_set download "$_i"
	printf '\r'
	tuish_progress_render download
	_i=$((_i + 5))
	sleep 0.1
done
printf '\n'
tuish_actor_destroy download
