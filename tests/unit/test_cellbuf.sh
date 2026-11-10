#!/bin/sh
# SPDX-License-Identifier: ISC
set -euf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/compat.sh"
. "$TESTS_DIR/../src/cellbuf.sh"
. "$TESTS_DIR/../src/compositor.sh"
. "$TESTS_DIR/../src/term.sh"
. "$TESTS_DIR/../src/str.sh"
. "$TESTS_DIR/../src/draw.sh"
command -v tuish_fnfix >/dev/null 2>&1 && tuish_fnfix

printf 'Unit tests: cell buffer and compositor\n'
tuish_cellbuf_init base 8 4
tuish_cellbuf_init overlay 8 4
tuish_cellbuf_init frame 8 4
tuish_cellbuf_set base 1 1 A fg=51
tuish_cellbuf_set base 2 2 B bg=17
tuish_cellbuf_get base 1 1
assert_eq "$TUISH_CELL_GLYPH" A "cell glyph read"
assert_eq "$TUISH_CELL_FG" 51 "cell foreground read"
assert_eq "$TUISH_CELL_BG" "" "unset background remains transparent"
tuish_cellbuf_get base 2 2
assert_eq "$TUISH_CELL_BG" 17 "cell background read"
tuish_cellbuf_set base 2 2 C fg=39
tuish_cellbuf_get base 2 2
assert_eq "$TUISH_CELL_GLYPH" C "cell overwrite"
assert_eq "$TUISH_CELL_FG" 39 "overwrite replaces style"
tuish_cellbuf_set base 5 1 X && _rc=0 || _rc=$?
assert_eq "$_rc" 2 "out-of-bounds write rejected"
tuish_cellbuf_set base 1 2 'bad|glyph' && _rc=0 || _rc=$?
assert_eq "$_rc" 2 "record separator rejected"
tuish_cellbuf_set overlay 1 1 Z fg=203 bg=17
tuish_cellbuf_set overlay 3 3 O
tuish_compositor_add base 0
tuish_compositor_add overlay 10
tuish_compositor_compose frame
tuish_cellbuf_get frame 1 1
assert_eq "$TUISH_CELL_GLYPH" Z "higher z layer overlays lower z"
assert_eq "$TUISH_CELL_FG" 203 "layer foreground preserved"
assert_eq "$TUISH_CELL_BG" 17 "layer background preserved"
tuish_cellbuf_get frame 2 2
assert_eq "$TUISH_CELL_GLYPH" C "lower layer remains visible through transparent cells"
tuish_cellbuf_get frame 3 3
assert_eq "$TUISH_CELL_GLYPH" O "overlay-only cell copied"
tuish_cellbuf_fill independent F 42 17
 tuish_cellbuf_get independent 2 2
assert_eq "$TUISH_CELL_GLYPH" F "fill writes every cell"
assert_eq "$TUISH_CELL_BG" 17 "fill preserves background"
tuish_cellbuf_init independent 2 2
tuish_cellbuf_set independent 1 1 I
tuish_cellbuf_get base 1 1
assert_eq "$TUISH_CELL_GLYPH" A "named buffers remain independent"
tuish_compositor_add overlay 1001 && _rc=0 || _rc=$?
assert_eq "$_rc" 2 "z-order range validated"
tuish_cellbuf_init small 2 2
tuish_cellbuf_set overlay 4 4 CLIP
tuish_compositor_compose small
 tuish_cellbuf_get small 1 1
assert_eq "$TUISH_CELL_GLYPH" "Z" "composition retains visible cells inside target dimensions"
tuish_cellbuf_get small 2 2
assert_eq "$TUISH_CELL_GLYPH" "C" "composition copies visible lower-layer cells"
tuish_compositor_remove overlay
tuish_compositor_compose frame
tuish_cellbuf_get frame 1 1
assert_eq "$TUISH_CELL_GLYPH" A "removing a layer reveals lower layer"
_render_capture=''
tuish_draw_text () { _render_capture="${_render_capture}R$1,$2,$3|"; }
tuish_compositor_render frame
assert_contains "$_render_capture" 'R1,1,A' "renderer emits composed cell"
assert_contains "$_render_capture" 'R2,2,C' "renderer emits remaining cells"
tuish_cellbuf_clear base
tuish_cellbuf_get base 1 1 && _rc=0 || _rc=$?
assert_eq "$_rc" 1 "clear makes cells transparent"
test_summary
