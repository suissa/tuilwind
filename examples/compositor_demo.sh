#!/bin/sh
# Layered composition demo using the cyber design palette.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/src/compat.sh"
. "$ROOT/src/ord.sh"
. "$ROOT/src/tui.sh"
. "$ROOT/src/term.sh"
. "$ROOT/src/str.sh"
. "$ROOT/src/draw.sh"
. "$ROOT/src/viewport.sh"
. "$ROOT/src/theme.sh"
. "$ROOT/src/cellbuf.sh"
. "$ROOT/src/compositor.sh"

tuish_theme_use cyber
tuish_cellbuf_init background 48 14
tuish_cellbuf_init modal 48 14
tuish_cellbuf_init frame 48 14
tuish_cellbuf_set background 2 3 'TUILWIND // COMPOSITOR' fg="$TUISH_THEME_PRIMARY"
tuish_cellbuf_set background 4 3 'FRAME BUFFER' fg="$TUISH_THEME_MUTED"
tuish_cellbuf_set background 5 3 'LAYERS: 02' fg="$TUISH_THEME_SUCCESS"
tuish_cellbuf_set modal 7 12 '╭────────────────────────────╮' fg="$TUISH_THEME_SECONDARY"
tuish_cellbuf_set modal 8 12 '│  OVERLAY / Z-INDEX  10     │' fg="$TUISH_THEME_SECONDARY"
tuish_cellbuf_set modal 9 12 '│  TRANSPARENT CELLS         │' fg="$TUISH_THEME_TEXT"
tuish_cellbuf_set modal 10 12 '╰────────────────────────────╯' fg="$TUISH_THEME_SECONDARY"
tuish_compositor_add background 0
tuish_compositor_add modal 10
tuish_compositor_compose frame
tuish_init
tuish_viewport fullscreen
tuish_begin
tuish_clear_screen
tuish_compositor_render frame
tuish_end
tuish_fini
