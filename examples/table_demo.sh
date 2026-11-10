#!/bin/sh

# SPDX-License-Identifier: ISC
# Interactive table demo. Enter j/k/s/r/q then press Enter.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$ROOT/src/actor.sh"
. "$ROOT/src/table.sh"

tuish_table_create inventory 5 3 4
tuish_table_set_header inventory 1 Product
tuish_table_set_header inventory 2 Stock
tuish_table_set_header inventory 3 State
tuish_table_set_width inventory 1 16
tuish_table_set_width inventory 2 7
tuish_table_set_width inventory 3 12
tuish_table_set_row inventory 1 sku-101 "Keyboard" 24 Available
tuish_table_set_row inventory 2 sku-102 "Mouse" 0 "Out of stock"
tuish_table_set_row inventory 3 sku-103 "Monitor" 8 Available
tuish_table_set_row inventory 4 sku-104 "USB-C hub" 3 "Low stock"
tuish_table_set_row inventory 5 sku-105 "Webcam" 11 Available

_table_draw () {
	printf '\033[H\033[2J'
	printf 'Inventory — interactive table\n\n'
	tuish_table_render inventory
	printf '\nCommands: j=next, k=previous, s=scroll, r=resize, q=quit\n'
}
_table_draw
while IFS= read -r _command
do
	case "$_command" in
		j) tuish_actor_action inventory next '' || :;;
		k) tuish_actor_action inventory previous '' || :;;
		s) tuish_actor_action inventory scroll 1 || :;;
		r) tuish_actor_action inventory resize 3 || :;;
		q) break;;
		*) printf 'Unknown command: %s\n' "$_command";;
	esac
	_table_draw
done
tuish_actor_destroy inventory
