#!/bin/sh
# SPDX-License-Identifier: ISC
# src/diff.sh - cell-level incremental rendering for CellBuffers.
# Source after cellbuf.sh, term.sh, str.sh and draw.sh.
if test -n "${_tuish_diff_loaded:-}"; then return 0; fi
_tuish_diff_loaded=1

TUISH_DIFF_CHANGED_CELLS=0
_tuish_diff_force=0

# Invalidate the cached frame after terminal reset, resize or external screen writes.
tuish_diff_invalidate () { _tuish_diff_force=1; }

_tuish_diff_width () {
  local _df_text=$1
  if test -n "${_tuish_str_loaded:-}"; then
    tuish_str_width _df_text
    TUISH_DIFF_WIDTH=$TUISH_SWIDTH
  else
    TUISH_DIFF_WIDTH=${#_df_text}
  fi
}

_tuish_diff_draw () {
  local _df_row=$1 _df_col=$2 _df_text=$3 _df_width=$4 _df_fg=$5 _df_bg=$6 _df_attrs=$7
  set -- "$_df_row" "$_df_col" "$_df_text"
  test -n "$_df_width" && set -- "$@" "width=$_df_width"
  test -n "$_df_fg" && set -- "$@" "fg=$_df_fg"
  test -n "$_df_bg" && set -- "$@" "bg=$_df_bg"
  test -n "$_df_attrs" && set -- "$@" "attrs=$_df_attrs"
  tuish_draw_text "$@"
}

# Copy CURRENT into PREVIOUS after a successful render. This makes PREVIOUS a
# renderer-owned snapshot; callers should not mutate it between diff calls.
_tuish_diff_snapshot () {
  local _ds_previous=$1 _ds_current=$2 _ds_w=$3 _ds_h=$4
  local _ds_line _ds_id _ds_row _ds_col _ds_glyph _ds_fg _ds_bg _ds_attrs
  tuish_cellbuf_init "$_ds_previous" "$_ds_w" "$_ds_h" || return
  while IFS= read -r _ds_line; do
    test -n "$_ds_line" || continue
    _ds_id=${_ds_line%%|*}; _ds_line=${_ds_line#*|}
    test "$_ds_id" = "$_ds_current" || continue
    _ds_row=${_ds_line%%|*}; _ds_line=${_ds_line#*|}
    _ds_col=${_ds_line%%|*}; _ds_line=${_ds_line#*|}
    _ds_glyph=${_ds_line%%|*}; _ds_line=${_ds_line#*|}
    _ds_fg=${_ds_line%%|*}; _ds_line=${_ds_line#*|}
    _ds_bg=${_ds_line%%|*}; _ds_attrs=${_ds_line#*|}
    tuish_cellbuf_set "$_ds_previous" "$_ds_row" "$_ds_col" "$_ds_glyph" \
      "fg=$_ds_fg" "bg=$_ds_bg" "attrs=$_ds_attrs" || return
  done <<EOF
$TUISH_CELLBUF_CELLS
EOF
}

# tuish_diff_render PREVIOUS CURRENT [force]
# PREVIOUS is an internal snapshot buffer and is replaced after each successful call.
# CURRENT is never modified. A missing snapshot, resize or force flag performs a full redraw.
tuish_diff_render () {
  test "$#" -ge 2 && test "$#" -le 3 || return 2
  local _dr_previous=$1 _dr_current=$2 _dr_arg=${3:-}
  local _dr_old_w=0 _dr_old_h=0 _dr_w _dr_h _dr_row _dr_col
  local _dr_old_present _dr_new_present _dr_old_glyph _dr_old_fg _dr_old_bg _dr_old_attrs
  local _dr_new_glyph _dr_new_fg _dr_new_bg _dr_new_attrs _dr_old_width _dr_new_width _dr_pad
  test "$_dr_previous" != "$_dr_current" || return 2
  test -z "$_dr_arg" || test "$_dr_arg" = force || return 2
  tuish_cellbuf_size "$_dr_current" || return 1
  _dr_w=$TUISH_CELLBUF_WIDTH _dr_h=$TUISH_CELLBUF_HEIGHT
  if tuish_cellbuf_size "$_dr_previous"; then
    _dr_old_w=$TUISH_CELLBUF_WIDTH _dr_old_h=$TUISH_CELLBUF_HEIGHT
    _dr_old_present=1
  else
    _dr_old_present=0
  fi

  _dr_arg_force=$_tuish_diff_force
  test "$_dr_arg" = force && _dr_arg_force=1
  if test "$_dr_old_present" -eq 0 || test "$_dr_old_w" -ne "$_dr_w" || test "$_dr_old_h" -ne "$_dr_h"; then
    _dr_arg_force=1
    if test "$_dr_old_w" -gt "$_dr_w"; then _dr_clear_w=$_dr_old_w; else _dr_clear_w=$_dr_w; fi
    if test "$_dr_old_h" -gt "$_dr_h"; then _dr_clear_h=$_dr_old_h; else _dr_clear_h=$_dr_h; fi
    tuish_clear_region 1 1 "$_dr_clear_w" "$_dr_clear_h"
  elif test "$_dr_arg_force" -eq 1; then
    tuish_clear_region 1 1 "$_dr_w" "$_dr_h"
  fi

  TUISH_DIFF_CHANGED_CELLS=0
  _dr_row=1
  while test "$_dr_row" -le "$_dr_h"; do
    _dr_col=1
    while test "$_dr_col" -le "$_dr_w"; do
      _dr_old_present=0 _dr_new_present=0
      _dr_old_glyph='' _dr_old_fg='' _dr_old_bg='' _dr_old_attrs=''
      _dr_new_glyph='' _dr_new_fg='' _dr_new_bg='' _dr_new_attrs=''
      if test "$_dr_arg_force" -eq 0 && tuish_cellbuf_get "$_dr_previous" "$_dr_row" "$_dr_col"; then
        _dr_old_present=1
        _dr_old_glyph=$TUISH_CELL_GLYPH _dr_old_fg=$TUISH_CELL_FG
        _dr_old_bg=$TUISH_CELL_BG _dr_old_attrs=$TUISH_CELL_ATTRS
      fi
      if tuish_cellbuf_get "$_dr_current" "$_dr_row" "$_dr_col"; then
        _dr_new_present=1
        _dr_new_glyph=$TUISH_CELL_GLYPH _dr_new_fg=$TUISH_CELL_FG
        _dr_new_bg=$TUISH_CELL_BG _dr_new_attrs=$TUISH_CELL_ATTRS
      fi

      _dr_changed=0
      if test "$_dr_old_present" -ne "$_dr_new_present"; then
        _dr_changed=1
      elif test "$_dr_new_present" -eq 1; then
        if test "$_dr_old_glyph" != "$_dr_new_glyph" || test "$_dr_old_fg" != "$_dr_new_fg" || \
           test "$_dr_old_bg" != "$_dr_new_bg" || test "$_dr_old_attrs" != "$_dr_new_attrs"; then
          _dr_changed=1
        fi
      fi

      if test "$_dr_changed" -eq 1 || test "$_dr_arg_force" -eq 1 && test "$_dr_new_present" -eq 1; then
        _dr_pad=''
        if test "$_dr_old_present" -eq 1; then
          _tuish_diff_width "$_dr_old_glyph"
          _dr_old_width=$TUISH_DIFF_WIDTH
        else
          _dr_old_width=0
        fi
        if test "$_dr_new_present" -eq 1; then
          _tuish_diff_width "$_dr_new_glyph"
          _dr_new_width=$TUISH_DIFF_WIDTH
          test "$_dr_old_width" -gt "$_dr_new_width" && _dr_pad=$_dr_old_width
          _tuish_diff_draw "$_dr_row" "$_dr_col" "$_dr_new_glyph" "$_dr_pad" \
            "$_dr_new_fg" "$_dr_new_bg" "$_dr_new_attrs"
        elif test "$_dr_old_present" -eq 1; then
          _tuish_diff_draw "$_dr_row" "$_dr_col" ' ' "$_dr_old_width" '' '' ''
        fi
        TUISH_DIFF_CHANGED_CELLS=$((TUISH_DIFF_CHANGED_CELLS + 1))
      fi
      _dr_col=$((_dr_col + 1))
    done
    _dr_row=$((_dr_row + 1))
  done

  _tuish_diff_snapshot "$_dr_previous" "$_dr_current" "$_dr_w" "$_dr_h" || return
  _tuish_diff_force=0
}
