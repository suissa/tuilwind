#!/bin/sh

# SPDX-License-Identifier: ISC
# src/split_view.sh - bounded two-pane layout Actor.
# Source after actor.sh. Geometry is logical, 1-based and independent of terminal I/O.

if test -n "${_tuish_split_view_loaded:-}"; then return 0; fi
_tuish_split_view_loaded=1

_tuish_split_uint () {
  tuish_actor_is_uint "$1" || return 1
  case "$1" in 0|[1-9]*) return 0;; *) return 1;; esac
}

_tuish_split_has_pane () {
  local _view=$1 _pane=$2 _ids
  tuish_actor_get "$_view" pane_ids || return 1
  _ids=$TUISH_ACTOR_VALUE
  case " $_ids " in *" $_pane "*) return 0;; *) return 1;; esac
}

tuish_split_view_create () {
  local _id=$1 _direction=$2 _width=$3 _height=$4 _ratio=${5:-50} _gap=${6:-1}
  _tuish_split_uint "$_width" && test "$_width" -ge 1 || return 2
  _tuish_split_uint "$_height" && test "$_height" -ge 1 || return 2
  _tuish_split_uint "$_ratio" && test "$_ratio" -ge 1 && test "$_ratio" -le 99 || return 2
  _tuish_split_uint "$_gap" && test "$_gap" -le 20 || return 2
  case "$_direction" in horizontal|vertical) ;; *) return 2;; esac
  tuish_actor_create "$_id" split-view || return
  tuish_actor_set "$_id" direction "$_direction" || return
  tuish_actor_set "$_id" width "$_width" || return
  tuish_actor_set "$_id" height "$_height" || return
  tuish_actor_set "$_id" split_ratio "$_ratio" || return
  tuish_actor_set "$_id" gap "$_gap" || return
  tuish_actor_set "$_id" min_first 1 || return
  tuish_actor_set "$_id" min_second 1 || return
  tuish_actor_set "$_id" pane_ids '' || return
  tuish_actor_set "$_id" active_pane '' || return
  tuish_actor_set "$_id" pane_count 0 || return
  tuish_actor_set "$_id" geometry '' || return
  _tuish_actor_emit "$_id" layout "$_direction"
}

tuish_split_view_add_pane () {
  local _view=$1 _pane=$2 _label=${3:-$_pane} _ids _count
  _tuish_actor_valid_name "$_pane" && tuish_actor_valid_value "$_label" || return 2
  _tuish_tree_status=0
  tuish_actor_get "$_view" direction || return 1
  _tuish_split_has_pane "$_view" "$_pane" && return 3
  tuish_actor_get "$_view" pane_ids || return
  _ids=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" pane_count || return
  _count=$TUISH_ACTOR_VALUE
  test "$_count" -lt 2 || return 2
  tuish_actor_set "$_view" "pane_label_$_pane" "$_label" || return
  tuish_actor_set "$_view" "pane_active_$_pane" 1 || return
  tuish_actor_set "$_view" pane_ids "${_ids:+$_ids }$_pane" || return
  _count=$((_count + 1))
  tuish_actor_set "$_view" pane_count "$_count" || return
  if test "$_count" -eq 1; then tuish_actor_set "$_view" active_pane "$_pane" || return; fi
  _tuish_actor_emit "$_view" data_change "$_pane"
}

tuish_split_view_set_ratio () {
  local _view=$1 _ratio=$2
  _tuish_split_uint "$_ratio" && test "$_ratio" -ge 1 && test "$_ratio" -le 99 || return 2
  tuish_actor_get "$_view" pane_count || return
  test "$TUISH_ACTOR_VALUE" -eq 2 || return 2
  tuish_actor_set "$_view" split_ratio "$_ratio" || return
  _tuish_actor_emit "$_view" layout "$_ratio"
}

tuish_split_view_set_gap () {
  local _view=$1 _gap=$2
  _tuish_split_uint "$_gap" && test "$_gap" -le 20 || return 2
  tuish_actor_set "$_view" gap "$_gap" || return
  _tuish_actor_emit "$_view" layout "$_gap"
}

tuish_split_view_set_constraints () {
  local _view=$1 _first=$2 _second=$3
  _tuish_split_uint "$_first" && test "$_first" -ge 1 || return 2
  _tuish_split_uint "$_second" && test "$_second" -ge 1 || return 2
  tuish_actor_set "$_view" min_first "$_first" || return
  tuish_actor_set "$_view" min_second "$_second" || return
  tuish_split_view_layout "$_view" >/dev/null
}

tuish_split_view_resize () {
  local _view=$1 _width=$2 _height=$3
  _tuish_split_uint "$_width" && test "$_width" -ge 1 || return 2
  _tuish_split_uint "$_height" && test "$_height" -ge 1 || return 2
  tuish_actor_set "$_view" width "$_width" || return
  tuish_actor_set "$_view" height "$_height" || return
  tuish_split_view_layout "$_view" >/dev/null || return
  _tuish_actor_emit "$_view" resize "${_width}x${_height}"
}

tuish_split_view_focus () {
  local _view=$1 _pane=$2
  _tuish_split_has_pane "$_view" "$_pane" || return 4
  tuish_actor_set "$_view" active_pane "$_pane" || return
  _tuish_actor_emit "$_view" focus "$_pane"
}

tuish_split_view_pointer () {
  local _view=$1 _x=$2 _y=$3 _geometry _line _pane _r _c _w _h
  _tuish_split_uint "$_x" && test "$_x" -ge 1 || return 2
  _tuish_split_uint "$_y" && test "$_y" -ge 1 || return 2
  tuish_split_view_layout "$_view" >/dev/null || return
  tuish_actor_get "$_view" geometry || return
  _geometry=$TUISH_ACTOR_VALUE
  while IFS='|' read -r _pane _r _c _w _h
  do
    test -n "$_pane" || continue
    if test "$_x" -ge "$_c" && test "$_x" -lt "$((_c + _w))" &&
       test "$_y" -ge "$_r" && test "$_y" -lt "$((_r + _h))"
    then
      tuish_split_view_focus "$_view" "$_pane" || return
      _tuish_actor_emit "$_view" pointer "$_pane"
      TUISH_SPLIT_VIEW_HIT=$_pane
      return 0
    fi
  done <<EOF
$_geometry
EOF
  TUISH_SPLIT_VIEW_HIT=''
  return 1
}

tuish_split_view_child_exit () {
  local _view=$1 _pane=$2 _ids _next='' _item _active
  _tuish_split_has_pane "$_view" "$_pane" || return 4
  tuish_actor_get "$_view" pane_ids || return
  _ids=$TUISH_ACTOR_VALUE
  for _item in $_ids; do test "$_item" = "$_pane" || _next="${_next:+$_next }$_item"; done
  tuish_actor_set "$_view" pane_ids "$_next" || return
  tuish_actor_set "$_view" "pane_active_$_pane" 0 || return
  set -- $_next
  tuish_actor_set "$_view" pane_count "$#" || return
  tuish_actor_get "$_view" active_pane || :; _active=$TUISH_ACTOR_VALUE
  if test "$_active" = "$_pane"; then tuish_actor_set "$_view" active_pane "${1:-}" || return; fi
  tuish_split_view_layout "$_view" >/dev/null || :
  _tuish_actor_emit "$_view" child_exit "$_pane"
}

# Geometry format is one record per pane: id|row|column|width|height.
# Horizontal means side-by-side; vertical means stacked.
tuish_split_view_layout () {
  local _view=$1 _direction _width _height _ratio _gap _first_min _second_min
  local _ids _count _first _second _available _total _row2=1 _col2=1 _w1 _h1 _w2 _h2 _geom='' _pane1 _pane2
  tuish_actor_get "$_view" direction || return 1; _direction=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" width || return; _width=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" height || return; _height=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" split_ratio || return; _ratio=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" gap || return; _gap=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" min_first || return; _first_min=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" min_second || return; _second_min=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" pane_ids || return; _ids=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" pane_count || return; _count=$TUISH_ACTOR_VALUE
  test "$_count" -gt 0 || { tuish_actor_set "$_view" geometry ''; TUISH_SPLIT_VIEW_GEOMETRY=''; return 0; }
  set -- $_ids
  _pane1=$1
  if test "$_count" -eq 1
  then
    _geom="$_pane1|1|1|$_width|$_height"
  else
    _pane2=$2
    if test "$_direction" = horizontal; then _total=$_width; else _total=$_height; fi
    _available=$((_total - _gap))
    test "$_available" -ge "$((_first_min + _second_min))" || return 2
    _first=$((_available * _ratio / 100))
    test "$_first" -ge "$_first_min" || _first=$_first_min
    test "$((_available - _first))" -ge "$_second_min" || _first=$((_available - _second_min))
    _second=$((_available - _first))
    if test "$_direction" = horizontal
    then
      _w1=$_first; _h1=$_height; _w2=$_second; _h2=$_height; _col2=$((_first + _gap + 1))
    else
      _w1=$_width; _h1=$_first; _w2=$_width; _h2=$_second; _row2=$((_first + _gap + 1))
    fi
    _geom="$_pane1|1|1|$_w1|$_h1
$_pane2|$_row2|$_col2|$_w2|$_h2"
  fi
  tuish_actor_set "$_view" geometry "$_geom" || return
  TUISH_SPLIT_VIEW_GEOMETRY=$_geom
  _tuish_actor_emit "$_view" render "$_geom"
  printf '%s\n' "$_geom"
}

tuish_split_view_render () {
  local _view=$1 _geometry _line _pane _row _col _width _height _active _label _out=''
  tuish_split_view_layout "$_view" >/dev/null || return
  tuish_actor_get "$_view" geometry || return; _geometry=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_view" active_pane || :; _active=$TUISH_ACTOR_VALUE
  while IFS='|' read -r _pane _row _col _width _height
  do
    test -n "$_pane" || continue
    tuish_actor_get "$_view" "pane_label_$_pane" || :; _label=$TUISH_ACTOR_VALUE
    _out="${_out}${_pane} ${_row},${_col} ${_width}x${_height}${_pane:+}"
    test "$_pane" = "$_active" && _out="${_out} [active]"
    _out="${_out}\n"
    test -n "$_label" && :
  done <<EOF
$_geometry
EOF
  printf '%s' "$_out"
}

