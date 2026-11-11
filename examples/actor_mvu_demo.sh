#!/bin/sh

# SPDX-License-Identifier: ISC
# Small, non-interactive Elm/MVU broker example.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$ROOT/src/actor.sh"

state=0
child_message () { printf 'parent received from %s: %s\n' "${2%%|*}" "${2#*|}"; }
message () { printf 'message: %s\n' "$2"; }
update () {
	state=$((state + 1))
	tuish_actor_set "$1" state "$state"
	printf 'update: state=%s\n' "$state"
	tuish_actor_cmd "$1" 'render-requested'
}
view () { printf 'view: actor=%s state=%s\n' "$1" "$2"; }
effect () { printf 'effect: %s\n' "$2"; }

tuish_actor_create app list
tuish_actor_create counter list app
tuish_actor_program app message update view effect child_message
tuish_actor_program counter message update view effect

tuish_actor_send app increment
tuish_actor_send_child counter changed
tuish_actor_render app main
tuish_actor_destroy counter
tuish_actor_destroy app
