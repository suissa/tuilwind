#!/bin/sh
# SPDX-License-Identifier: ISC
set -euf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/compat.sh"
. "$TESTS_DIR/../src/ord.sh"
. "$TESTS_DIR/../src/tui.sh"
. "$TESTS_DIR/../src/term.sh"
. "$TESTS_DIR/../src/str.sh"
. "$TESTS_DIR/../src/draw.sh"
. "$TESTS_DIR/../src/cellbuf.sh"
. "$TESTS_DIR/../src/diff_renderer.sh"
command -v tuish_fnfix >/dev/null 2>&1 && tuish_fnfix

_diff_calls=0
_diff_output=''
tuish_draw_text () {
  _diff_calls=$((_diff_calls + 1))
  _diff_output="${_diff_output}[$1,$2,$3]"
}

printf 'Unit tests: incremental cell diff renderer\n'
tuish_cellbuf_init previous 3 2
tuish_cellbuf_init current 3 2
tuish_cellbuf_set current 1 1 A
tuish_cellbuf_set current 1 2 B fg=42
_diff_calls=0
tuish_diff_render_full current
assert_eq "$_diff_calls" 6 "full render paints every cell including blanks"

# Snapshot the first frame as the previous frame.
tuish_cellbuf_set previous 1 1 A
tuish_cellbuf_set previous 1 2 B fg=42
_diff_calls=0
tuish_diff_render previous current
assert_eq "$_diff_calls" 0 "identical frames emit no draw calls"

tuish_cellbuf_set current 1 1 X
_diff_calls=0
tuish_diff_render previous current
assert_eq "$_diff_calls" 1 "glyph-only change redraws one cell"
assert_contains "$_diff_output" '[1,1,X]' "changed glyph is emitted"

tuish_cellbuf_set previous 1 1 X
tuish_cellbuf_set current 1 2 B fg=39
_diff_calls=0
tuish_diff_render previous current
assert_eq "$_diff_calls" 1 "style-only change redraws one cell"

tuish_cellbuf_clear current
_diff_calls=0
_diff_output=''
tuish_diff_render previous current
assert_eq "$_diff_calls" 2 "removed populated cells are erased"
assert_contains "$_diff_output" '[1,1, ]' "removed glyph is replaced by a blank"
assert_contains "$_diff_output" '[1,2, ]' "removed styled glyph is replaced by a blank"

_diff_calls=0
tuish_diff_invalidate
tuish_diff_render previous current
assert_eq "$_diff_calls" 6 "invalidation forces a complete redraw"

tuish_cellbuf_init wrong_size 2 2
_diff_status=0
tuish_diff_render previous wrong_size || _diff_status=$?
assert_eq "$_diff_status" 2 "dimension mismatch is rejected"

_diff_calls=0
tuish_diff_render_full current
assert_eq "$_diff_calls" 6 "explicit full render clears empty cells"
test_summary
