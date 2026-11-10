#!/bin/sh
# Incremental redraw demo. Press Enter between frames to compare the output.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/src/compat.sh"
. "$ROOT/src/ord.sh"
. "$ROOT/src/tui.sh"
. "$ROOT/src/term.sh"
. "$ROOT/src/str.sh"
. "$ROOT/src/draw.sh"
. "$ROOT/src/cellbuf.sh"
. "$ROOT/src/diff.sh"
command -v tuish_fnfix >/dev/null 2>&1 && tuish_fnfix

tuish_init
tuish_viewport fullscreen
tuish_begin
tuish_cellbuf_init frame 56 12
tuish_cellbuf_set frame 2 3 'TUILWIND // DIFF RENDERER' fg=51 attrs=1
tuish_cellbuf_set frame 4 3 'FRAME 001' fg=245
tuish_cellbuf_set frame 6 3 'UNCHANGED CELLS ARE NOT REPAINTED' fg=42
tuish_diff_render previous frame
tuish_end

printf '\nFrame 1 rendered. Press Enter to update one text run...'
IFS= read -r _key
tuish_begin
tuish_cellbuf_set frame 4 3 'FRAME 002 // 1 REGION CHANGED' fg=51 attrs=1
tuish_diff_render previous frame
tuish_end
printf '\nChanged cells: %s\n' "$TUISH_DIFF_CHANGED_CELLS"
tuish_fini
