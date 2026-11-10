#!/bin/sh
# SPDX-License-Identifier: ISC
# src/compositor.sh - deterministic z-ordered composition of sparse cell buffers.
# Source after cellbuf.sh and draw.sh.
if test -n "${_tuish_compositor_loaded:-}"; then return 0; fi
_tuish_compositor_loaded=1

TUISH_COMPOSITOR_LAYERS=''
_tuish_compositor_sequence=0

tuish_compositor_clear () { TUISH_COMPOSITOR_LAYERS=''; _tuish_compositor_sequence=0; }

tuish_compositor_add () {
  local _co_buf=$1 _co_z=$2 _co_next='' _co_line _co_id _co_seq
  _tuish_cellbuf_name_ok "$_co_buf" || return 2
  case "$_co_z" in -*) case "${_co_z#-}" in ''|*[!0-9]*) return 2;; esac;; *) case "$_co_z" in ''|*[!0-9]*) return 2;; esac;; esac
  test "$_co_z" -ge -999 && test "$_co_z" -le 999 || return 2
  tuish_cellbuf_size "$_co_buf" || return 1
  while IFS= read -r _co_line; do
    test -z "$_co_line" && continue
    _co_id=${_co_line%%|*}
    test "$_co_id" = "$_co_buf" || _co_next="${_co_next}${_co_line}
"
  done <<EOF
$TUISH_COMPOSITOR_LAYERS
EOF
  _tuish_compositor_sequence=$((_tuish_compositor_sequence + 1))
  TUISH_COMPOSITOR_LAYERS="${_co_next}${_co_buf}|$_co_z|$_tuish_compositor_sequence
"
}

tuish_compositor_remove () {
  local _co_buf=$1 _co_next='' _co_line _co_id
  while IFS= read -r _co_line; do
    test -z "$_co_line" && continue
    _co_id=${_co_line%%|*}
    test "$_co_id" = "$_co_buf" || _co_next="${_co_next}${_co_line}
"
  done <<EOF
$TUISH_COMPOSITOR_LAYERS
EOF
  TUISH_COMPOSITOR_LAYERS=$_co_next
}

# Compose all registered layers into TARGET, ascending z; later layers win.
# Equal z values preserve registration order.
tuish_compositor_compose () {
  local _co_target=$1 _co_z _co_line _co_buf _co_row _co_col _co_glyph _co_fg _co_bg _co_attrs
  local _co_zpart _co_seq _co_cell _co_target_w _co_target_h
  tuish_cellbuf_size "$_co_target" || return 1
  _co_target_w=$TUISH_CELLBUF_WIDTH _co_target_h=$TUISH_CELLBUF_HEIGHT
  tuish_cellbuf_clear "$_co_target" || return
  _co_z=-999
  while test "$_co_z" -le 999; do
    while IFS= read -r _co_line; do
      test -z "$_co_line" && continue
      _co_buf=${_co_line%%|*}; _co_line=${_co_line#*|}
      _co_zpart=${_co_line%%|*}
      test "$_co_zpart" = "$_co_z" || continue
      while IFS= read -r _co_cell; do
        test -z "$_co_cell" && continue
        _co_line=${_co_cell%%|*}; _co_cell=${_co_cell#*|}
        test "$_co_line" = "$_co_buf" || continue
        _co_row=${_co_cell%%|*}; _co_cell=${_co_cell#*|}
        _co_col=${_co_cell%%|*}; _co_cell=${_co_cell#*|}
        _co_glyph=${_co_cell%%|*}; _co_cell=${_co_cell#*|}
        _co_fg=${_co_cell%%|*}; _co_cell=${_co_cell#*|}
        _co_bg=${_co_cell%%|*}; _co_attrs=${_co_cell#*|}
        test "$_co_row" -le "$_co_target_h" && test "$_co_col" -le "$_co_target_w" || continue
        tuish_cellbuf_set "$_co_target" "$_co_row" "$_co_col" "$_co_glyph" "fg=$_co_fg" "bg=$_co_bg" "attrs=$_co_attrs" || return
      done <<EOF
$TUISH_CELLBUF_CELLS
EOF
    done <<EOF
$TUISH_COMPOSITOR_LAYERS
EOF
    _co_z=$((_co_z + 1))
  done
}

tuish_compositor_render () {
  local _co_buf=$1 _co_line _co_id _co_row _co_col _co_glyph _co_fg _co_bg _co_attrs
  while IFS= read -r _co_line; do
    test -z "$_co_line" && continue
    _co_id=${_co_line%%|*}; _co_line=${_co_line#*|}
    test "$_co_id" = "$_co_buf" || continue
    _co_row=${_co_line%%|*}; _co_line=${_co_line#*|}
    _co_col=${_co_line%%|*}; _co_line=${_co_line#*|}
    _co_glyph=${_co_line%%|*}; _co_line=${_co_line#*|}
    _co_fg=${_co_line%%|*}; _co_line=${_co_line#*|}
    _co_bg=${_co_line%%|*}; _co_attrs=${_co_line#*|}
    if test -n "$_co_fg" && test -n "$_co_bg"; then
      tuish_draw_text "$_co_row" "$_co_col" "$_co_glyph" fg="$_co_fg" bg="$_co_bg"
    elif test -n "$_co_fg"; then
      tuish_draw_text "$_co_row" "$_co_col" "$_co_glyph" fg="$_co_fg"
    elif test -n "$_co_bg"; then
      tuish_draw_text "$_co_row" "$_co_col" "$_co_glyph" bg="$_co_bg"
    else
      tuish_draw_text "$_co_row" "$_co_col" "$_co_glyph"
    fi
  done <<EOF
$TUISH_CELLBUF_CELLS
EOF
}
