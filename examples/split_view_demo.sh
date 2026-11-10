#!/bin/sh
# SplitView Actor layout demonstration.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/src/actor.sh"
. "$ROOT/src/split_view.sh"

tuish_split_view_create workspace horizontal 80 24 65 1
tuish_split_view_add_pane workspace files "Files"
tuish_split_view_add_pane workspace editor "Editor"
tuish_split_view_focus workspace editor
printf 'SplitView geometry (pane|row|column|width|height):\n'
tuish_split_view_render workspace
printf '\nResize: tuish_split_view_resize workspace 100 30\n'
tuish_split_view_resize workspace 100 30
tuish_split_view_render workspace
printf '\nFocus: tuish_split_view_focus workspace files\n'
tuish_split_view_focus workspace files
tuish_split_view_render workspace
