#!/bin/sh
# SPDX-License-Identifier: ISC
set -euf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/compat.sh"
. "$TESTS_DIR/../src/ord.sh"
. "$TESTS_DIR/../src/tui.sh"
. "$TESTS_DIR/../src/cellbuf.sh"
. "$TESTS_DIR/../src/term.sh"
. "$TESTS_DIR/../src/str.sh"
. "$TESTS_DIR/../src/draw.sh"
. "$TESTS_DIR/../src/diff.sh"
command -v tuish_fnfix >/dev/null 2>&1 && tuish_fnfix

printf 'Unit tests: incremental DiffRenderer\n'
tuish_cellbuf_init current 5 2
tuish_cellbuf_set current 1 1 ABC fg=51
tuish_cellbuf_set current 1 4 X
_draw_log='' _clear_log=''
tuish_draw_text () { _draw_log="${_draw_log}R$1,$2,$3|"; _draw_opts="${_draw_opts:-} $*"; }
tuish_clear_region () { _clear_log="${_clear_log}C$1,$2,$3,$4|"; }

# A missing snapshot performs a full first render and captures the frame.
tuish_diff_render previous current
assert_eq "$TUISH_DIFF_CHANGED_CELLS" 2 "initial frame draws each populated cell"
assert_contains "$_draw_log" 'R1,1,ABC' "initial frame draws first text run"
assert_contains "$_draw_log" 'R1,4,X' "initial frame draws second text run"
assert_contains "$_clear_log" 'C1,1,5,2' "initial frame clears its viewport region"

# Identical frames must produce no terminal writes.
_draw_log='' _clear_log=''
tuish_diff_render previous current
assert_eq "$TUISH_DIFF_CHANGED_CELLS" 0 "identical frame has no changed cells"
assert_eq "$_draw_log" '' "identical frame produces no draw calls"
assert_eq "$_clear_log" '' "identical frame does not clear the viewport"

# Shorter text is padded to the old display width, preventing stale trailing glyphs.
tuish_cellbuf_set current 1 1 AB fg=203
_draw_log='' _draw_opts=''
tuish_diff_render previous current
assert_eq "$TUISH_DIFF_CHANGED_CELLS" 1 "glyph and style change redraws one cell"
assert_contains "$_draw_log" 'R1,1,AB' "changed glyph is redrawn"
assert_contains "$_draw_opts" 'width=3' "shorter replacement clears the old text tail"
assert_contains "$_draw_opts" 'fg=203' "style changes are detected and forwarded"

# Removing a cell clears its previous display span.
tuish_cellbuf_clear current
tuish_cellbuf_set current 1 1 AB fg=203
_draw_log=''
tuish_diff_render previous current
assert_eq "$TUISH_DIFF_CHANGED_CELLS" 1 "removed cell is counted as changed"
assert_contains "$_draw_log" 'R1,4, ' "removed cell is erased with a space"

# A dimension change clears the union of old and new viewports, then redraws.
tuish_cellbuf_init current 3 1
tuish_cellbuf_set current 1 1 Z
_draw_log='' _clear_log=''
tuish_diff_render previous current
assert_eq "$TUISH_DIFF_CHANGED_CELLS" 1 "resized frame is fully redrawn"
assert_contains "$_clear_log" 'C1,1,5,2' "resize clears the previous larger viewport"
assert_contains "$_draw_log" 'R1,1,Z' "resized frame is rendered"

# Explicit invalidation forces a redraw even when the frame is unchanged.
_draw_log='' _clear_log=''
tuish_diff_invalidate
tuish_diff_render previous current
assert_eq "$TUISH_DIFF_CHANGED_CELLS" 1 "invalidated frame is fully redrawn"
assert_contains "$_clear_log" 'C1,1,3,1' "invalidation clears current viewport"
assert_contains "$_draw_log" 'R1,1,Z' "invalidation redraws current content"

# Caller errors are rejected.
tuish_diff_render previous current unexpected && _rc=0 || _rc=$?
assert_eq "$_rc" 2 "unknown render option is rejected"
tuish_diff_render current current && _rc=0 || _rc=$?
assert_eq "$_rc" 2 "snapshot and current buffers must be distinct"

test_summary
