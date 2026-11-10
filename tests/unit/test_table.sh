#!/bin/sh

# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/actor.sh"
. "$TESTS_DIR/../src/table.sh"

_table_callback () { TABLE_EVENT="$2:$1"; }
printf 'Unit tests: interactive data table Actor\n'

tuish_table_create inventory 3 3 2
tuish_actor_on inventory data_change _table_callback
tuish_actor_on inventory select _table_callback
tuish_actor_on inventory scroll _table_callback
tuish_actor_on inventory resize _table_callback
tuish_actor_on inventory render _table_callback

tuish_table_set_header inventory 1 Name
tuish_table_set_header inventory 2 Quantity
tuish_table_set_header inventory 3 Status
tuish_table_set_width inventory 1 8
tuish_table_set_padding inventory 2
tuish_table_set_border_style inventory rounded
tuish_table_set_width inventory 2 6
tuish_table_set_width inventory 3 8

tuish_table_set_row inventory 1 sku-a Alpha 12 Ready
tuish_table_set_row inventory 2 sku-b Beta 4 Pending
tuish_table_set_row inventory 3 sku-c Gamma 99 Archived
tuish_actor_get inventory kind
assert_eq "$TUISH_ACTOR_VALUE" table "table Actor type"
tuish_actor_get inventory row_count
assert_eq "$TUISH_ACTOR_VALUE" 3 "row count initialized"
tuish_actor_get inventory cell_2_2
assert_eq "$TUISH_ACTOR_VALUE" 4 "row data stored by cell"
assert_eq "$TABLE_EVENT" 'sku-c:inventory' "data change callback receives row key"

tuish_table_select inventory 2
tuish_actor_get inventory selected_key
assert_eq "$TUISH_ACTOR_VALUE" sku-b "selection retains stable row key"
assert_eq "$TABLE_EVENT" 'sku-b:inventory' "select callback receives stable key"
tuish_table_move inventory 1
tuish_actor_get inventory cursor
assert_eq "$TUISH_ACTOR_VALUE" 3 "next moves cursor"
tuish_table_move inventory -1
tuish_actor_get inventory cursor
assert_eq "$TUISH_ACTOR_VALUE" 2 "previous moves cursor"

tuish_table_set_row inventory 1 sku-b Beta 5 Ready
tuish_table_set_row inventory 2 sku-a Alpha 12 Ready
tuish_table_set_rows inventory 3
tuish_actor_get inventory cursor
assert_eq "$TUISH_ACTOR_VALUE" 1 "selected row follows stable key after reorder"
tuish_actor_get inventory selected_key
assert_eq "$TUISH_ACTOR_VALUE" sku-b "stable key remains selected after reorder"

tuish_table_scroll inventory 2
tuish_actor_get inventory viewport_offset
assert_eq "$TUISH_ACTOR_VALUE" 2 "scroll updates viewport offset"
assert_eq "$TABLE_EVENT" '2:inventory' "scroll callback fires"
tuish_table_resize inventory 1
tuish_actor_get inventory visible_rows
assert_eq "$TUISH_ACTOR_VALUE" 1 "resize updates visible row count"
assert_eq "$TABLE_EVENT" '1:inventory' "resize callback fires"
tuish_actor_get inventory viewport_offset
assert_eq "$TUISH_ACTOR_VALUE" 2 "resize keeps selected row visible"

_output=$(tuish_table_render inventory)
assert_contains "$_output" 'Name' "render includes column headers"
assert_contains "$_output" 'Alpha' "render includes selected row data"
assert_contains "$_output" '> ' "render marks selected row"
assert_eq "$TABLE_EVENT" '2:inventory' "render callback fires"

tuish_table_set_width inventory 1 4
tuish_table_select inventory 2
_output=$(tuish_table_render inventory)
assert_contains "$_output" 'Alph' "wide cell content is truncated to configured display width"

tuish_table_set_cell inventory 1 2 7
tuish_actor_get inventory cell_1_2
assert_eq "$TUISH_ACTOR_VALUE" 7 "cell update changes data"
assert_eq "$TABLE_EVENT" '1:2:inventory' "cell update emits data change"

_status=0
tuish_table_select inventory 0 || _status=$?
assert_eq "$_status" 2 "zero row selection rejected"
_status=0
tuish_table_set_width inventory 2 0 || _status=$?
assert_eq "$_status" 2 "zero column width rejected"
_status=0
tuish_table_set_cell inventory 9 1 invalid || _status=$?
assert_eq "$_status" 2 "out-of-range row update rejected"
_status=0
tuish_table_set_row inventory 1 unsafe 'bad|cell' 2 Ready || _status=$?
assert_eq "$_status" 2 "record separator in cell rejected"
_status=0
tuish_table_resize inventory 0 || _status=$?
assert_eq "$_status" 2 "zero visible rows rejected"
_status=0
tuish_table_set_border_style inventory invalid || _status=$?
assert_eq "$_status" 2 "unknown border style rejected"

tuish_table_set_rows inventory 1
tuish_actor_get inventory selected_key
assert_eq "$TUISH_ACTOR_VALUE" '' "selection clears when its stable key is removed"
tuish_actor_get inventory cell_2_1
assert_eq "$TUISH_ACTOR_VALUE" '' "removed row storage is cleared"

tuish_table_create empty 0 2 3
tuish_table_set_header empty 1 ID
tuish_table_set_header empty 2 Description
_output=$(tuish_table_render empty)
assert_contains "$_output" 'ID' "empty table still renders headers"
assert_contains "$_output" '(no rows)' "empty table renders empty state"

tuish_actor_destroy inventory
tuish_actor_destroy empty
tuish_actor_count
assert_eq "$TUISH_ACTOR_COUNT" 0 "table Actors clean up"
test_summary
