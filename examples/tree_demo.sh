#!/bin/sh
# Expandable tree Actor demonstration.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/src/actor.sh"
. "$ROOT/src/tree.sh"

tuish_tree_create project Project 12
tuish_tree_add_node project src project src/
tuish_tree_add_node project tests project tests/
tuish_tree_add_node project readme project README.md
tuish_tree_add_node project actor src actor.sh
tuish_tree_add_node project table src table.sh
tuish_tree_add_node project tree src tree.sh
tuish_tree_add_node project unit tests unit/
tuish_tree_toggle project project
tuish_tree_toggle project src
tuish_tree_toggle project tests
tuish_tree_toggle project src
tuish_tree_render project
printf '\nUse tuish_tree_move project 1/-1, tuish_tree_toggle project, and tuish_tree_render project.\n'
