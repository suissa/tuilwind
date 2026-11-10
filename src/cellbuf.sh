#!/bin/sh
# SPDX-License-Identifier: ISC
# src/cellbuf.sh - sparse, named in-memory cell grids.
# Source after compat.sh. Coordinates are 1-based. Unset cells are transparent.
if test -n "${_tuish_cellbuf_loaded:-}"; then return 0; fi
_tuish_cellbuf_loaded=1

TUISH_CELLBUF_META=''
TUISH_CELLBUF_CELLS=''
TUISH_CELLBUF_WIDTH=0
TUISH_CELLBUF_HEIGHT=0
TUISH_CELL_GLYPH=''
TUISH_CELL_FG=''
TUISH_CELL_BG=''
TUISH_CELL_ATTRS=''

_tuish_cellbuf_name_ok () { case "$1" in ''|*[!A-Za-z0-9_-]*) return 1;; esac; }
_tuish_cellbuf_uint () { case "$1" in ''|*[!0-9]*) return 1;; esac; }
_tuish_cellbuf_value_ok () { case "$1" in *'|'*|*'
'*) return 1;; esac; }

tuish_cellbuf_init () {
  local _cb_name=$1 _cb_w=$2 _cb_h=$3 _cb_next='' _cb_line _cb_id
  _tuish_cellbuf_name_ok "$_cb_name" && _tuish_cellbuf_uint "$_cb_w" && _tuish_cellbuf_uint "$_cb_h" || return 2
  test "$_cb_w" -gt 0 && test "$_cb_h" -gt 0 || return 2
  while IFS= read -r _cb_line; do
    test -z "$_cb_line" && continue
    _cb_id=${_cb_line%%|*}
    test "$_cb_id" = "$_cb_name" || _cb_next="${_cb_next}${_cb_line}
"
  done <<EOF
$TUISH_CELLBUF_META
EOF
  TUISH_CELLBUF_META="${_cb_next}${_cb_name}|$_cb_w|$_cb_h
"
  tuish_cellbuf_clear "$_cb_name"
  TUISH_CELLBUF_WIDTH=$_cb_w TUISH_CELLBUF_HEIGHT=$_cb_h
}

tuish_cellbuf_size () {
  local _cb_name=$1 _cb_line
  TUISH_CELLBUF_WIDTH=0 TUISH_CELLBUF_HEIGHT=0
  while IFS= read -r _cb_line; do
    test "${_cb_line%%|*}" = "$_cb_name" || continue
    _cb_line=${_cb_line#*|}
    TUISH_CELLBUF_WIDTH=${_cb_line%%|*}
    TUISH_CELLBUF_HEIGHT=${_cb_line#*|}
    return 0
  done <<EOF
$TUISH_CELLBUF_META
EOF
  return 1
}

tuish_cellbuf_clear () {
  local _cb_name=$1 _cb_next='' _cb_line _cb_id
  _tuish_cellbuf_name_ok "$_cb_name" || return 2
  while IFS= read -r _cb_line; do
    test -z "$_cb_line" && continue
    _cb_id=${_cb_line%%|*}
    test "$_cb_id" = "$_cb_name" || _cb_next="${_cb_next}${_cb_line}
"
  done <<EOF
$TUISH_CELLBUF_CELLS
EOF
  TUISH_CELLBUF_CELLS=$_cb_next
}

# tuish_cellbuf_set BUFFER ROW COL GLYPH [fg=N] [bg=N] [attrs=TEXT]
tuish_cellbuf_set () {
  local _cb_name=$1 _cb_row=$2 _cb_col=$3 _cb_glyph=$4 _cb_fg='' _cb_bg='' _cb_attrs='' _cb_opt
  local _cb_next='' _cb_line _cb_id _cb_r _cb_c
  _tuish_cellbuf_name_ok "$_cb_name" && _tuish_cellbuf_uint "$_cb_row" && _tuish_cellbuf_uint "$_cb_col" || return 2
  test -n "$_cb_glyph" || return 2
  _tuish_cellbuf_value_ok "$_cb_glyph" || return 2
  shift 4
  while test $# -gt 0; do
    _cb_opt=$1
    case "$_cb_opt" in
      fg=*) _cb_fg=${_cb_opt#*=};;
      bg=*) _cb_bg=${_cb_opt#*=};;
      attrs=*) _cb_attrs=${_cb_opt#*=};;
      *) return 2;;
    esac
    shift
  done
  _tuish_cellbuf_value_ok "$_cb_fg" && _tuish_cellbuf_value_ok "$_cb_bg" && _tuish_cellbuf_value_ok "$_cb_attrs" || return 2
  case "$_cb_fg" in ''|*[!0-9]*) ;; *) test "$_cb_fg" -le 255 || return 2;; esac
  case "$_cb_bg" in ''|*[!0-9]*) ;; *) test "$_cb_bg" -le 255 || return 2;; esac
  case "$_cb_fg" in *[!0-9]*) test -z "$_cb_fg" || return 2;; esac
  case "$_cb_bg" in *[!0-9]*) test -z "$_cb_bg" || return 2;; esac
  tuish_cellbuf_size "$_cb_name" || return 1
  test "$_cb_row" -ge 1 && test "$_cb_row" -le "$TUISH_CELLBUF_HEIGHT" && test "$_cb_col" -ge 1 && test "$_cb_col" -le "$TUISH_CELLBUF_WIDTH" || return 2
  while IFS= read -r _cb_line; do
    test -z "$_cb_line" && continue
    _cb_id=${_cb_line%%|*}; _cb_line=${_cb_line#*|}
    _cb_r=${_cb_line%%|*}; _cb_line=${_cb_line#*|}
    _cb_c=${_cb_line%%|*}
    if test "$_cb_id" = "$_cb_name" && test "$_cb_r" = "$_cb_row" && test "$_cb_c" = "$_cb_col"; then continue; fi
    _cb_next="${_cb_next}${_cb_id}|$_cb_line
"
  done <<EOF
$TUISH_CELLBUF_CELLS
EOF
  TUISH_CELLBUF_CELLS="${_cb_next}${_cb_name}|$_cb_row|$_cb_col|$_cb_glyph|$_cb_fg|$_cb_bg|$_cb_attrs
"
}

tuish_cellbuf_get () {
  local _cb_name=$1 _cb_row=$2 _cb_col=$3 _cb_line _cb_id _cb_r _cb_c
  TUISH_CELL_GLYPH='' TUISH_CELL_FG='' TUISH_CELL_BG='' TUISH_CELL_ATTRS=''
  while IFS= read -r _cb_line; do
    test -z "$_cb_line" && continue
    _cb_id=${_cb_line%%|*}; _cb_line=${_cb_line#*|}
    _cb_r=${_cb_line%%|*}; _cb_line=${_cb_line#*|}
    _cb_c=${_cb_line%%|*}; _cb_line=${_cb_line#*|}
    if test "$_cb_id" = "$_cb_name" && test "$_cb_r" = "$_cb_row" && test "$_cb_c" = "$_cb_col"; then
      TUISH_CELL_GLYPH=${_cb_line%%|*}; _cb_line=${_cb_line#*|}
      TUISH_CELL_FG=${_cb_line%%|*}; _cb_line=${_cb_line#*|}
      TUISH_CELL_BG=${_cb_line%%|*}; TUISH_CELL_ATTRS=${_cb_line#*|}
      return 0
    fi
  done <<EOF
$TUISH_CELLBUF_CELLS
EOF
  return 1
}

tuish_cellbuf_fill () {
  local _cb_name=$1 _cb_glyph=$2 _cb_row _cb_col _cb_fg=${3:-} _cb_bg=${4:-}
  tuish_cellbuf_size "$_cb_name" || return 1
  _cb_row=1
  while test "$_cb_row" -le "$TUISH_CELLBUF_HEIGHT"; do
    _cb_col=1
    while test "$_cb_col" -le "$TUISH_CELLBUF_WIDTH"; do
      tuish_cellbuf_set "$_cb_name" "$_cb_row" "$_cb_col" "$_cb_glyph" "fg=$_cb_fg" "bg=$_cb_bg" || return
      _cb_col=$((_cb_col + 1))
    done
    _cb_row=$((_cb_row + 1))
  done
}
