#!/bin/sh
# SPDX-License-Identifier: ISC
# src/ui.sh - reusable futuristic visual primitives; source after draw.sh/theme.sh.
if test -n "${_tuish_ui_loaded:-}"; then return 0; fi
_tuish_ui_loaded=1

# tuish_ui_panel ROW COL WIDTH HEIGHT TITLE [state=active|idle|warning|danger]
tuish_ui_panel () {
  local _ui_r=$1 _ui_c=$2 _ui_w=$3 _ui_h=$4 _ui_title=$5 _ui_state=idle _ui_color
  shift 5
  while test $# -gt 0; do
    case "$1" in state=*) _ui_state=${1#*=};; esac
    shift
  done
  case "$_ui_state" in
    active) _ui_color=$TUISH_THEME_PRIMARY;;
    warning) _ui_color=$TUISH_THEME_WARNING;;
    danger) _ui_color=$TUISH_THEME_DANGER;;
    idle) _ui_color=$TUISH_THEME_BORDER;;
    *) return 2;;
  esac
  test "$_ui_w" -ge 4 && test "$_ui_h" -ge 3 || return 2
  tuish_draw_box "$_ui_r" "$_ui_c" "$_ui_w" "$_ui_h" style=rounded fg="$_ui_color" || return
  tuish_draw_text "$_ui_r" "$((_ui_c + 2))" " $_ui_title " fg="$_ui_color" maxwidth="$((_ui_w - 4))"
}

# tuish_ui_badge ROW COL LABEL [tone=primary|success|warning|danger|muted]
tuish_ui_badge () {
  local _ui_r=$1 _ui_c=$2 _ui_label=$3 _ui_tone=primary _ui_color
  shift 3
  while test $# -gt 0; do case "$1" in tone=*) _ui_tone=${1#*=};; esac; shift; done
  case "$_ui_tone" in
    primary) _ui_color=$TUISH_THEME_PRIMARY;; success) _ui_color=$TUISH_THEME_SUCCESS;;
    warning) _ui_color=$TUISH_THEME_WARNING;; danger) _ui_color=$TUISH_THEME_DANGER;;
    muted) _ui_color=$TUISH_THEME_MUTED;; *) return 2;;
  esac
  tuish_draw_text "$_ui_r" "$_ui_c" "[ $_ui_label ]" fg="$_ui_color"
}

# tuish_ui_progress ROW COL WIDTH PERCENT [LABEL]
tuish_ui_progress () {
  local _ui_r=$1 _ui_c=$2 _ui_w=$3 _ui_pct=$4 _ui_label=${5:-}
  local _ui_inner _ui_done _ui_empty _ui_bar _ui_i
  case "$_ui_w:$_ui_pct" in *[!0-9:]*) return 2;; esac
  test "$_ui_w" -ge 3 && test "$_ui_pct" -le 100 || return 2
  _ui_inner=$((_ui_w - 2))
  _ui_done=$((_ui_inner * _ui_pct / 100))
  _ui_empty=$((_ui_inner - _ui_done))
  _ui_bar=''
  _ui_i=0
  if test "${TUISH_DRAW_BACKEND:-ascii}" = unicode; then
    while test "$_ui_i" -lt "$_ui_done"; do _ui_bar="${_ui_bar}█"; _ui_i=$((_ui_i + 1)); done
    while test "$_ui_i" -lt "$_ui_inner"; do _ui_bar="${_ui_bar}░"; _ui_i=$((_ui_i + 1)); done
  else
    while test "$_ui_i" -lt "$_ui_done"; do _ui_bar="${_ui_bar}#"; _ui_i=$((_ui_i + 1)); done
    while test "$_ui_i" -lt "$_ui_inner"; do _ui_bar="${_ui_bar}-"; _ui_i=$((_ui_i + 1)); done
  fi
  tuish_draw_text "$_ui_r" "$_ui_c" "$_ui_bar" fg="$TUISH_THEME_PRIMARY" maxwidth="$_ui_inner"
  if test -n "$_ui_label"; then tuish_draw_text "$_ui_r" "$((_ui_c + _ui_inner + 1))" "$_ui_label"; fi
}

# tuish_ui_section ROW COL TEXT [tone=primary|muted]
tuish_ui_section () {
  local _ui_r=$1 _ui_c=$2 _ui_text=$3 _ui_tone=primary _ui_color
  shift 3
  while test $# -gt 0; do case "$1" in tone=*) _ui_tone=${1#*=};; esac; shift; done
  case "$_ui_tone" in primary) _ui_color=$TUISH_THEME_PRIMARY;; muted) _ui_color=$TUISH_THEME_MUTED;; *) return 2;; esac
  tuish_draw_text "$_ui_r" "$_ui_c" "/// $_ui_text" fg="$_ui_color"
}
