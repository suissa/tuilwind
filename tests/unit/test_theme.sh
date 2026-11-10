#!/bin/sh
# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/theme.sh"
. "$TESTS_DIR/../src/ui.sh"

_UI_CAPTURE=""
tuish_draw_box () { _UI_CAPTURE="${_UI_CAPTURE}BOX:$*|"; }
tuish_draw_text () { _UI_CAPTURE="${_UI_CAPTURE}TEXT:$*|"; }
printf 'Unit tests: theme and UI primitives\n'
assert_eq "$TUISH_THEME_NAME" cyber "default theme"
tuish_theme_get primary
assert_eq "$TUISH_THEME_VALUE" 51 "cyber primary token"
tuish_theme_use midnight
assert_eq "$TUISH_THEME_PRIMARY" 39 "midnight primary token"
tuish_theme_set primary 99
assert_eq "$TUISH_THEME_PRIMARY" 99 "custom token override"
tuish_theme_set unknown 10 && _rc=0 || _rc=$?
assert_eq "$_rc" 2 "unknown token rejected"
tuish_theme_set primary 256 && _rc=0 || _rc=$?
assert_eq "$_rc" 2 "out-of-range color rejected"
tuish_theme_use mono
assert_eq "$TUISH_THEME_NAME" mono "mono theme"
tuish_theme_use invalid && _rc=0 || _rc=$?
assert_eq "$_rc" 2 "unknown theme rejected"
# Render primitives against a capture backend (no terminal required).
tuish_theme_use cyber
_UI_CAPTURE=''
tuish_ui_panel 1 2 30 8 Runtime state=active
assert_contains "$_UI_CAPTURE" "BOX:1 2 30 8 style=rounded fg=51" "panel uses active accent"
assert_contains "$_UI_CAPTURE" "TEXT:1 4  Runtime " "panel prints title"
_UI_CAPTURE=''
tuish_ui_badge 2 3 READY tone=success
assert_contains "$_UI_CAPTURE" "TEXT:2 3 [ READY ] fg=42" "badge resolves semantic tone"
_UI_CAPTURE=''
tuish_ui_progress 3 4 10 50 "50%"
assert_contains "$_UI_CAPTURE" "TEXT:3 4 ####---- fg=51 maxwidth=8" "progress uses ASCII fallback"
assert_contains "$_UI_CAPTURE" "TEXT:3 13 50%" "progress label is positioned after bar"
_UI_CAPTURE=''
tuish_ui_section 4 5 PIPELINES
assert_contains "$_UI_CAPTURE" "TEXT:4 5 /// PIPELINES fg=51" "section uses primary accent"
_status=0
tuish_ui_badge 1 1 BAD tone=unknown || _status=$?
assert_eq "$_status" 2 "unknown badge tone rejected"
_status=0
tuish_ui_panel 1 1 3 2 Invalid || _status=$?
assert_eq "$_status" 2 "undersized panel rejected"
test_summary
