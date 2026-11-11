#!/bin/sh
# Incremental cell rendering demo.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/src/compat.sh"
. "$ROOT/src/ord.sh"
. "$ROOT/src/tui.sh"
. "$ROOT/src/term.sh"
. "$ROOT/src/str.sh"
. "$ROOT/src/draw.sh"
. "$ROOT/src/viewport.sh"
. "$ROOT/src/cellbuf.sh"
. "$ROOT/src/diff_renderer.sh"
command -v tuish_fnfix >/dev/null 2>&1 && tuish_fnfix

tuish_cellbuf_init previous 42 8
tuish_cellbuf_init current 42 8
tuish_cellbuf_set current 2 3 'TUILWIND // DIFF RENDERER'
tuish_cellbuf_set current 4 3 'FRAME 01: initial full paint'
tuish_cellbuf_set current 6 3 'Only changed cells are emitted'
tuish_init
tuish_viewport fullscreen
tuish_begin
tuish_clear_screen
tuish_diff_render_full current
tuish_end

# The next frame changes one glyph and one style; only those cells are repainted.
tuish_cellbuf_set previous 2 3 'TUILWIND // DIFF RENDERER'
tuish_cellbuf_set previous 4 3 'FRAME 01: initial full paint'
tuish_cellbuf_set previous 6 3 'Only changed cells are emitted'
tuish_cellbuf_set current 4 3 'FRAME 02: incremental update' fg=42
tuish_cellbuf_set current 6 3 'Only changed cells are emitted' fg=39
tuish_begin
tuish_diff_render previous current
tuish_end
tuish_fini
