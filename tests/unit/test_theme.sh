#!/bin/sh
# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/theme.sh"
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
test_summary
