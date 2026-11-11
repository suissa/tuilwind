#!/bin/sh
# SPDX-License-Identifier: ISC
# src/diff_renderer.sh - cell-based incremental rendering.
# Source after cellbuf.sh and draw.sh.
if test -n "${_tuish_diff_renderer_loaded:-}"; then return 0; fi
_tuish_diff_renderer_loaded=1

_tuish_diff_force_full=0

# tuish_diff_invalidate
# Force the next tuish_diff_render call to repaint the complete current frame.
# Call after resize, terminal reset, screen switch, or any out-of-band terminal write.
tuish_diff_invalidate () { _tuish_diff_force_full=1; }

_tuish_diff_emit () {
  local _dr_row=$1 _dr_col=$2 _dr_glyph=$3 _dr_fg=$4 _dr_bg=$5 _dr_attrs=$6
  if test -n "$_dr_fg" && test -n "$_dr_bg"; then
    tuish_draw_text "$_dr_row" "$_dr_col" "$_dr_glyph" fg="$_dr_fg" bg="$_dr_bg" attrs="$_dr_attrs"
  elif test -n "$_dr_fg"; then
    tuish_draw_text "$_dr_row" "$_dr_col" "$_dr_glyph" fg="$_dr_fg" attrs="$_dr_attrs"
  elif test -n "$_dr_bg"; then
    tuish_draw_text "$_dr_row" "$_dr_col" "$_dr_glyph" bg="$_dr_bg" attrs="$_dr_attrs"
  elif test -n "$_dr_attrs"; then
    tuish_draw_text "$_dr_row" "$_dr_col" "$_dr_glyph" attrs="$_dr_attrs"
  else
    tuish_draw_text "$_dr_row" "$_dr_col" "$_dr_glyph"
  fi
}

# tuish_diff_render PREVIOUS CURRENT
# Both buffers must have identical dimensions. Only changed cells are emitted.
# A cell removed from CURRENT is erased with a blank at its former position.
tuish_diff_render () {
  local _dr_previous=$1 _dr_current=$2
  local _dr_pw _dr_ph _dr_cw _dr_ch _dr_row _dr_col
  local _dr_pf _dr_cf _dr_pg _dr_pfg _dr_pbg _dr_pa
  local _dr_cg _dr_cfg _dr_cbg _dr_ca _dr_rc

  tuish_cellbuf_size "$_dr_previous" || return 1
  _dr_pw=$TUISH_CELLBUF_WIDTH _dr_ph=$TUISH_CELLBUF_HEIGHT
  tuish_cellbuf_size "$_dr_current" || return 1
  _dr_cw=$TUISH_CELLBUF_WIDTH _dr_ch=$TUISH_CELLBUF_HEIGHT
  test "$_dr_pw" = "$_dr_cw" && test "$_dr_ph" = "$_dr_ch" || return 2

  if test "$_tuish_diff_force_full" -eq 1; then
    tuish_diff_render_full "$_dr_current" || return
    _tuish_diff_force_full=0
    return 0
  fi

  _dr_row=1
  while test "$_dr_row" -le "$_dr_ch"; do
    _dr_col=1
    while test "$_dr_col" -le "$_dr_cw"; do
      _dr_pf=0 _dr_cf=0
      tuish_cellbuf_get "$_dr_previous" "$_dr_row" "$_dr_col" && _dr_pf=1
      _dr_pg=$TUISH_CELL_GLYPH _dr_pfg=$TUISH_CELL_FG _dr_pbg=$TUISH_CELL_BG _dr_pa=$TUISH_CELL_ATTRS
      tuish_cellbuf_get "$_dr_current" "$_dr_row" "$_dr_col" && _dr_cf=1
      _dr_cg=$TUISH_CELL_GLYPH _dr_cfg=$TUISH_CELL_FG _dr_cbg=$TUISH_CELL_BG _dr_ca=$TUISH_CELL_ATTRS

      if test "$_dr_pf" -eq 1 || test "$_dr_cf" -eq 1; then
        if test "$_dr_pf" -ne "$_dr_cf" || test "$_dr_pg" != "$_dr_cg" || test "$_dr_pfg" != "$_dr_cfg" || test "$_dr_pbg" != "$_dr_cbg" || test "$_dr_pa" != "$_dr_ca"; then
          if test "$_dr_cf" -eq 1; then
            _tuish_diff_emit "$_dr_row" "$_dr_col" "$_dr_cg" "$_dr_cfg" "$_dr_cbg" "$_dr_ca" || return
          else
            _tuish_diff_emit "$_dr_row" "$_dr_col" ' ' '' '' '' || return
          fi
        fi
      fi
      _dr_col=$((_dr_col + 1))
    done
    _dr_row=$((_dr_row + 1))
  done
}

# tuish_diff_render_full CURRENT
# Explicit initial/full paint. Empty cells are emitted as blanks to clear the
# complete rectangular viewport, not just the populated sparse cells.
tuish_diff_render_full () {
  local _dr_current=$1 _dr_w _dr_h _dr_row _dr_col _dr_glyph _dr_fg _dr_bg _dr_attrs
  tuish_cellbuf_size "$_dr_current" || return 1
  _dr_w=$TUISH_CELLBUF_WIDTH _dr_h=$TUISH_CELLBUF_HEIGHT
  _dr_row=1
  while test "$_dr_row" -le "$_dr_h"; do
    _dr_col=1
    while test "$_dr_col" -le "$_dr_w"; do
      if tuish_cellbuf_get "$_dr_current" "$_dr_row" "$_dr_col"; then
        _dr_glyph=$TUISH_CELL_GLYPH _dr_fg=$TUISH_CELL_FG _dr_bg=$TUISH_CELL_BG _dr_attrs=$TUISH_CELL_ATTRS
      else
        _dr_glyph=' ' _dr_fg='' _dr_bg='' _dr_attrs=''
      fi
      _tuish_diff_emit "$_dr_row" "$_dr_col" "$_dr_glyph" "$_dr_fg" "$_dr_bg" "$_dr_attrs" || return
      _dr_col=$((_dr_col + 1))
    done
    _dr_row=$((_dr_row + 1))
  done
  _tuish_diff_force_full=0
}
