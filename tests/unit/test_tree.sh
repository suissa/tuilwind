#!/bin/sh

# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/actor.sh"
. "$TESTS_DIR/../src/tree.sh"

_tree_event () { TREE_EVENT="$2:$1"; }
printf 'Unit tests: expandable Tree Actor\n'

tuish_tree_create files Files 3
tuish_actor_on files data_change _tree_event
tuish_actor_on files select _tree_event
tuish_actor_on files expand _tree_event
tuish_actor_on files collapse _tree_event
tuish_actor_on files resize _tree_event
tuish_actor_on files render _tree_event
tuish_tree_add_node files src files Source
tuish_tree_add_node files tests files Tests
tuish_tree_add_node files main src main.sh
tuish_tree_add_node files lib src lib
tuish_tree_add_node files unit tests unit
tuish_actor_get files item_count
assert_eq "$TUISH_ACTOR_VALUE" 3 "collapsed tree only exposes root children"
tuish_tree_toggle files src
tuish_actor_get files item_count
assert_eq "$TUISH_ACTOR_VALUE" 5 "expanding a branch reveals descendants"
assert_eq "$TREE_EVENT" 'src:files' "expand callback receives stable node ID"

tuish_tree_select files main
tuish_actor_get files selected_id
assert_eq "$TUISH_ACTOR_VALUE" main "selection uses stable node ID"
assert_eq "$TREE_EVENT" 'main:files' "select callback receives selected ID"
tuish_tree_move files -1
tuish_actor_get files selected_id
assert_eq "$TUISH_ACTOR_VALUE" lib "keyboard navigation moves to previous visible node"

tuish_tree_select files main
tuish_tree_toggle files src
tuish_actor_get files selected_id
assert_eq "$TUISH_ACTOR_VALUE" files "selection moves to nearest visible root when selected branch collapses"

_status=0
tuish_tree_add_node files invalid missing no || _status=$?
assert_eq "$_status" 4 "missing parent is rejected"
_status=0
tuish_tree_add_node files src files Duplicate || _status=$?
assert_eq "$_status" 3 "duplicate stable IDs are rejected"
_status=0
tuish_tree_set_parent files files src || _status=$?
assert_eq "$_status" 2 "root cannot be reparented"
_status=0
tuish_tree_set_parent files src main || _status=$?
assert_eq "$_status" 2 "reparenting cannot create a cycle"
_status=0
tuish_tree_select files main || _status=$?
assert_eq "$_status" 2 "hidden nodes cannot be selected"

tuish_tree_toggle files src
tuish_tree_select files main
tuish_tree_resize files 1
tuish_actor_get files visible_rows
assert_eq "$TUISH_ACTOR_VALUE" 1 "resize changes viewport height"
_output="$(tuish_tree_render files)"
assert_contains "$_output" 'main.sh' "render includes expanded child label"
assert_contains "$_output" '> ' "render marks selected node"
assert_eq "$TREE_EVENT" 'main:files' "render callback receives selected node"
tuish_actor_get files viewport_offset
assert_eq "$TUISH_ACTOR_VALUE" 3 "viewport clips around selected node"

tuish_tree_set_label files main entrypoint.sh
tuish_actor_get files node_label_main
assert_eq "$TUISH_ACTOR_VALUE" entrypoint.sh "node label updates without changing ID"
tuish_actor_action files expand files
_tuish_tree_status=0
tuish_tree_resize files 0 || _tuish_tree_status=$?
assert_eq "$_tuish_tree_status" 2 "zero viewport height is rejected"
tuish_actor_destroy files
tuish_actor_count
assert_eq "$TUISH_ACTOR_COUNT" 0 "tree Actor cleanup removes registry data"
test_summary
