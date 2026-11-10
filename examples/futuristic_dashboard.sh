#!/bin/sh
# Futuristic dashboard composition demo.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/src/compat.sh"
. "$ROOT/src/ord.sh"
. "$ROOT/src/tui.sh"
. "$ROOT/src/term.sh"
. "$ROOT/src/str.sh"
. "$ROOT/src/draw.sh"
. "$ROOT/src/theme.sh"
. "$ROOT/src/ui.sh"

tuish_theme_use cyber
tuish_update_size
tuish_begin
tuish_clear_screen
tuish_ui_section 2 4 "TUILWIND / SYSTEM OVERVIEW"
tuish_draw_text 2 62 "CORE  //  ONLINE" fg="$TUISH_THEME_SUCCESS"
tuish_ui_panel 4 4 34 9 "RUNTIME STATUS" state=active
tuish_draw_text 6 7 "Workers" fg="$TUISH_THEME_MUTED"
tuish_draw_text 6 24 "08 / 12" fg="$TUISH_THEME_TEXT"
tuish_ui_progress 8 7 25 68 "68%"
tuish_ui_panel 4 41 35 9 "TELEMETRY"
tuish_draw_text 6 44 "LATENCY" fg="$TUISH_THEME_MUTED"
tuish_draw_text 6 58 "24 ms" fg="$TUISH_THEME_PRIMARY"
tuish_draw_text 8 44 "UPTIME" fg="$TUISH_THEME_MUTED"
tuish_draw_text 8 58 "99.98%" fg="$TUISH_THEME_SUCCESS"
tuish_ui_section 15 4 "ACTIVE PIPELINES"
tuish_ui_badge 17 4 "NOMINAL" tone=success
tuish_ui_badge 17 16 "DEPLOYING" tone=warning
tuish_draw_text 20 4 "F1  Overview    F2  Metrics    Q  Quit" fg="$TUISH_THEME_MUTED"
tuish_end
