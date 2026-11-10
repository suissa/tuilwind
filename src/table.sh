#!/bin/sh

# SPDX-License-Identifier: ISC
# src/table.sh - interactive data-table Actor adapter.
# Source after actor.sh; str.sh is optional and used for Unicode display widths.

if test -n "${_tuish_table_loaded:-}"; then return 0; fi
_tuish_table_loaded=1

_tuish_table_uint () {
	_tuish_actor_is_uint "$1" || return 1
	case "$1" in 0|[1-9]*) ;; *) return 1;; esac
}

_tuish_table_bounds () {
	local _id=$1 _row=$2 _col=$3 _rows _cols
	_tuish_table_uint "$_row" && _tuish_table_uint "$_col" || return 2
	tuish_actor_get "$_id" row_count || return; _rows=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" column_count || return; _cols=$TUISH_ACTOR_VALUE
	test "$_row" -ge 1 && test "$_row" -le "$_rows" || return 2
	test "$_col" -ge 1 && test "$_col" -le "$_cols" || return 2
}

tuish_table_create () {
	local _id=$1 _rows=$2 _cols=$3 _visible=${4:-10} _i
	_tuish_table_uint "$_rows" && test "$_rows" -le 100000 || return 2
	_tuish_table_uint "$_cols" && test "$_cols" -ge 1 && test "$_cols" -le 64 || return 2
	_tuish_table_uint "$_visible" && test "$_visible" -ge 1 && test "$_visible" -le 10000 || return 2
	tuish_actor_create "$_id" table || return
	tuish_actor_set "$_id" row_count "$_rows" || return
	tuish_actor_set "$_id" column_count "$_cols" || return
	tuish_actor_set "$_id" visible_rows "$_visible" || return
	tuish_actor_set "$_id" cursor 1 || return
	tuish_actor_set "$_id" viewport_offset 1 || return
	tuish_actor_set "$_id" selected_key '' || return
	tuish_actor_set "$_id" border_style single || return
	tuish_actor_set "$_id" padding 1 || return
	tuish_actor_set "$_id" empty_label '(no rows)' || return
	tuish_actor_set "$_id" selection_enabled 1 || return
	_i=1
	while test "$_i" -le "$_cols"; do tuish_actor_set "$_id" "width_$_i" 12 || return; _i=$((_i + 1)); done
}

tuish_table_set_header () {
	local _id=$1 _col=$2 _value=$3 _cols
	_tuish_table_uint "$_col" || return 2
	tuish_actor_get "$_id" column_count || return; _cols=$TUISH_ACTOR_VALUE
	test "$_col" -ge 1 && test "$_col" -le "$_cols" || return 2
	_tuish_actor_valid_value "$_value" || return 2
	tuish_actor_set "$_id" "header_$_col" "$_value" || return
	_tuish_actor_emit "$_id" data_change "header:$_col"
}

tuish_table_set_padding () {
	local _id=$1 _padding=$2
	_tuish_table_uint "$_padding" && test "$_padding" -le 4 || return 2
	tuish_actor_set "$_id" padding "$_padding"
}

tuish_table_set_border_style () {
	local _id=$1 _style=$2
	case "$_style" in ascii|single|double|rounded|none) ;; *) return 2;; esac
	tuish_actor_set "$_id" border_style "$_style"
}

tuish_table_set_width () {
	local _id=$1 _col=$2 _width=$3
	_tuish_table_uint "$_col" && _tuish_table_uint "$_width" || return 2
	tuish_actor_get "$_id" column_count || return
	test "$_col" -ge 1 && test "$_col" -le "$TUISH_ACTOR_VALUE" || return 2
	test "$_width" -ge 1 && test "$_width" -le 200 || return 2
	tuish_actor_set "$_id" "width_$_col" "$_width"
}

# Set a complete row using one stable key and one value per column:
# tuish_table_set_row ID ROW STABLE_KEY CELL_1 ... CELL_N
tuish_table_set_row () {
	local _id=$1 _row=$2 _key=$3 _cols _col=1 _value _selected
	_tuish_table_uint "$_row" || return 2
	_tuish_actor_valid_value "$_key" || return 2
	tuish_actor_get "$_id" column_count || return; _cols=$TUISH_ACTOR_VALUE
	test "$#" -eq $((_cols + 3)) || return 2
	_tuish_table_bounds "$_id" "$_row" 1 || return
	tuish_actor_get "$_id" selected_key || :; _selected=$TUISH_ACTOR_VALUE
	tuish_actor_set "$_id" "row_key_$_row" "$_key" || return
	shift 3
	while test "$_col" -le "$_cols"
	do
		_value=$1
		_tuish_actor_valid_value "$_value" || return 2
		tuish_actor_set "$_id" "cell_${_row}_${_col}" "$_value" || return
		shift
		_col=$((_col + 1))
	done
	if test -n "$_selected" && test "$_selected" = "$_key"; then
		tuish_actor_set "$_id" cursor "$_row" || return
	fi
	_tuish_actor_emit "$_id" data_change "$_key"
}

tuish_table_set_cell () {
	local _id=$1 _row=$2 _col=$3 _value=$4
	_tuish_table_bounds "$_id" "$_row" "$_col" || return
	_tuish_actor_valid_value "$_value" || return 2
	tuish_actor_set "$_id" "cell_${_row}_${_col}" "$_value" || return
	_tuish_actor_emit "$_id" data_change "$_row:$_col"
}

tuish_table_set_rows () {
	local _id=$1 _rows=$2 _cursor _selected _i _found=0 _old _cols _col
	_tuish_table_uint "$_rows" && test "$_rows" -le 100000 || return 2
	tuish_actor_get "$_id" row_count || return; _old=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" column_count || return; _cols=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" cursor || return; _cursor=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" selected_key || :; _selected=$TUISH_ACTOR_VALUE
	if test "$_rows" -lt "$_old"; then
		_i=$((_rows + 1))
		while test "$_i" -le "$_old"; do
			tuish_actor_set "$_id" "row_key_$_i" '' || return
			_col=1
			while test "$_col" -le "$_cols"; do tuish_actor_set "$_id" "cell_${_i}_${_col}" '' || return; _col=$((_col + 1)); done
			_i=$((_i + 1))
		done
	fi
	tuish_actor_set "$_id" row_count "$_rows" || return
	if test "$_rows" -eq 0; then
		_cursor=0
		tuish_actor_set "$_id" selected_key '' || return
		tuish_actor_set "$_id" viewport_offset 1 || return
	else
		test "$_cursor" -le "$_rows" || _cursor=$_rows
		if test -n "$_selected"; then
			_i=1
			while test "$_i" -le "$_rows"; do
				tuish_actor_get "$_id" "row_key_$_i" || : 
				if test "$TUISH_ACTOR_VALUE" = "$_selected"; then _cursor=$_i; _found=1; break; fi
				_i=$((_i + 1))
			done
		fi
		if test -n "$_selected" && test "$_found" -eq 0; then tuish_actor_set "$_id" selected_key '' || return; fi
	fi
	tuish_actor_set "$_id" cursor "$_cursor" || return
	_tuish_table_sync_view "$_id"
	_tuish_actor_emit "$_id" data_change "rows:$_rows"
}

_tuish_table_sync_view () {
	local _id=$1 _cursor _offset _visible _rows
	tuish_actor_get "$_id" cursor || return; _cursor=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" viewport_offset || return; _offset=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" visible_rows || return; _visible=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" row_count || return; _rows=$TUISH_ACTOR_VALUE
	test "$_rows" -eq 0 && return 0
	test "$_cursor" -ge 1 || { _cursor=1; tuish_actor_set "$_id" cursor 1; }
	test "$_cursor" -le "$_rows" || { _cursor=$_rows; tuish_actor_set "$_id" cursor "$_cursor"; }
	if test "$_cursor" -lt "$_offset"; then _offset=$_cursor; fi
	if test "$_cursor" -ge $((_offset + _visible)); then _offset=$((_cursor - _visible + 1)); fi
	test "$_offset" -ge 1 || _offset=1
	tuish_actor_set "$_id" viewport_offset "$_offset"
}

tuish_table_select () {
	local _id=$1 _row=$2 _rows _key
	_tuish_table_uint "$_row" || return 2
	tuish_actor_get "$_id" row_count || return; _rows=$TUISH_ACTOR_VALUE
	test "$_row" -ge 1 && test "$_row" -le "$_rows" || return 2
	tuish_actor_get "$_id" "row_key_$_row" || :; _key=$TUISH_ACTOR_VALUE
	tuish_actor_set "$_id" cursor "$_row" || return
	tuish_actor_set "$_id" selected_key "$_key" || return
	_tuish_table_sync_view "$_id" || return
	_tuish_actor_emit "$_id" select "$_key"
}

tuish_table_move () {
	local _id=$1 _delta=$2 _cursor _rows _next
	case "$_delta" in -*) _tuish_table_uint "${_delta#-}" || return 2;; *) _tuish_table_uint "$_delta" || return 2;; esac
	tuish_actor_get "$_id" cursor || return; _cursor=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" row_count || return; _rows=$TUISH_ACTOR_VALUE
	test "$_rows" -gt 0 || return 2
	_next=$((_cursor + _delta))
	test "$_next" -ge 1 || _next=1
	test "$_next" -le "$_rows" || _next=$_rows
	tuish_table_select "$_id" "$_next"
}

tuish_table_scroll () {
	local _id=$1 _delta=$2 _offset _visible _rows _next _max _cursor _target _key
	case "$_delta" in -*) _tuish_table_uint "${_delta#-}" || return 2;; *) _tuish_table_uint "$_delta" || return 2;; esac
	tuish_actor_get "$_id" viewport_offset || return; _offset=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" visible_rows || return; _visible=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" row_count || return; _rows=$TUISH_ACTOR_VALUE
	_next=$((_offset + _delta))
	test "$_next" -ge 1 || _next=1
	test "$_rows" -gt "$_visible" && _max=$((_rows - _visible + 1)) || _max=1
	test "$_next" -le "$_max" || _next=$_max
	test "$_next" -ge 1 || _next=1
	tuish_actor_set "$_id" viewport_offset "$_next" || return
	tuish_actor_get "$_id" cursor || return; _cursor=$TUISH_ACTOR_VALUE
	if test "$_rows" -gt 0; then
		_target=$_cursor
		test "$_target" -ge "$_next" || _target=$_next
		test "$_target" -lt $((_next + _visible)) || _target=$((_next + _visible - 1))
		test "$_target" -le "$_rows" || _target=$_rows
		if test "$_target" != "$_cursor"; then
			tuish_actor_get "$_id" "row_key_$_target" || :; _key=$TUISH_ACTOR_VALUE
			tuish_actor_set "$_id" cursor "$_target" || return
			tuish_actor_set "$_id" selected_key "$_key" || return
			_tuish_actor_emit "$_id" select "$_key"
		fi
	fi
	_tuish_actor_emit "$_id" scroll "$_next"
}

tuish_table_resize () {
	local _id=$1 _visible=$2
	_tuish_table_uint "$_visible" && test "$_visible" -ge 1 && test "$_visible" -le 10000 || return 2
	tuish_actor_set "$_id" visible_rows "$_visible" || return
	_tuish_table_sync_view "$_id" || return
	_tuish_actor_emit "$_id" resize "$_visible"
}

_tuish_table_fit () {
	local _value=$1 _width=$2
	if command -v tuish_str_window >/dev/null 2>&1; then
		tuish_str_window _value 0 "$_width"
		_value=$TUISH_SWINDOW
		tuish_str_width _value
		_width=$(( _width - TUISH_SWIDTH ))
		while test "$_width" -gt 0; do _value="${_value} "; _width=$((_width - 1)); done
	else
		local _rest=$_value _piece=''
		_value=''
		while test "$_width" -gt 0 && test -n "$_rest"
		do
			_piece=${_rest%%"${_rest#?}"}
			_rest=${_rest#?}
			_value="${_value}${_piece}"
			_width=$((_width - 1))
		done
		while test "$_width" -gt 0; do _value="${_value} "; _width=$((_width - 1)); done
	fi
	TUISH_TABLE_FIT=$_value
}

tuish_table_render () {
	local _id=$1 _rows _cols _offset _visible _cursor _empty _r _c _w _value _line _border _pad _total _top=''
	tuish_actor_get "$_id" row_count || return; _rows=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" column_count || return; _cols=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" viewport_offset || return; _offset=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" visible_rows || return; _visible=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" cursor || return; _cursor=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" empty_label || :; _empty=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" padding || :; _pad=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_id" border_style || :; _border=$TUISH_ACTOR_VALUE
	_tuish_table_uint "$_pad" && test "$_pad" -le 4 || _pad=1
	case "$_border" in
		none) _border='';;
		double) _border='║';;
		rounded|single) _border='│';;
		*) _border='|';;
	esac
	_line=''
	_c=1
	while test "$_c" -le "$_cols"; do
		tuish_actor_get "$_id" "width_$_c" || return; _w=$TUISH_ACTOR_VALUE
		_total=$((_w + _pad * 2))
		_tuish_table_fit '' "$_pad"; _value=$TUISH_TABLE_FIT
		_line="${_line}${_border}${_value}"
		tuish_actor_get "$_id" "header_$_c" || :; _value=$TUISH_ACTOR_VALUE
		_tuish_table_fit "$_value" "$_w"; _line="${_line}${_value}"
		_tuish_table_fit '' "$_pad"; _value=$TUISH_TABLE_FIT; _line="${_line}${_value}"
		_c=$((_c + 1))
	done
	_line="${_line}${_border}"
	printf '%s\n' "$_line"
	if test "$_rows" -eq 0; then printf '%s\n' "$_empty"; _tuish_actor_emit "$_id" render "$_empty"; return; fi
	_r=$_offset
	_total=$((_offset + _visible - 1))
	test "$_total" -le "$_rows" || _total=$_rows
	while test "$_r" -le "$_total"; do
		_line=''
		_c=1
		while test "$_c" -le "$_cols"; do
			tuish_actor_get "$_id" "width_$_c" || return; _w=$TUISH_ACTOR_VALUE
			tuish_actor_get "$_id" "cell_${_r}_${_c}" || :; _value=$TUISH_ACTOR_VALUE
			_tuish_table_fit "$_value" "$_w"; _value=$TUISH_TABLE_FIT
			_tuish_table_fit '' "$_pad"; _line="${_line}${_border}${TUISH_TABLE_FIT}${_value}"
			_tuish_table_fit '' "$_pad"; _line="${_line}${TUISH_TABLE_FIT}"
			_c=$((_c + 1))
		done
		_line="${_line}${_border}"
		if test "$_r" -eq "$_cursor"; then printf '> %s\n' "$_line"; else printf '  %s\n' "$_line"; fi
		_r=$((_r + 1))
	done
	_tuish_actor_emit "$_id" render "$_cursor"
}
