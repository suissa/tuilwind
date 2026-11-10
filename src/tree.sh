#!/bin/sh

# SPDX-License-Identifier: ISC
# src/tree.sh - expandable, keyed Tree Actor adapter.
# Source after actor.sh. Node IDs are stable shell-safe identifiers.

if test -n "${_tuish_tree_loaded:-}"; then return 0; fi
_tuish_tree_loaded=1

_tuish_tree_uint () {
	tuish_actor_is_uint "$1" || return 1
	case "$1" in 0|[1-9]*) ;; *) return 1;; esac
}

_tuish_tree_has_node () {
	local _tree=$1 _node=$2 _ids
	tuish_actor_get "$_tree" node_ids || return 1
	_ids=$TUISH_ACTOR_VALUE
	case " $_ids " in *" $_node "*) return 0;; *) return 1;; esac
}

tuish_tree_create () {
	local _tree=$1 _label=${2:-Root} _visible=${3:-10}
	_tuish_tree_uint "$_visible" && test "$_visible" -ge 1 && test "$_visible" -le 10000 || return 2
	tuish_actor_create "$_tree" tree || return
	tuish_actor_set "$_tree" root_node "$_tree" || return
	tuish_actor_set "$_tree" node_ids "$_tree" || return
	tuish_actor_set "$_tree" "node_label_$_tree" "$_label" || return
	tuish_actor_set "$_tree" "node_parent_$_tree" '' || return
	tuish_actor_set "$_tree" "node_expanded_$_tree" 1 || return
	tuish_actor_set "$_tree" selected_id "$_tree" || return
	tuish_actor_set "$_tree" cursor 1 || return
	tuish_actor_set "$_tree" viewport_offset 1 || return
	tuish_actor_set "$_tree" visible_rows "$_visible" || return
	tuish_actor_set "$_tree" indent_width 2 || return
	tuish_actor_set "$_tree" max_depth 64 || return
	tuish_actor_set "$_tree" max_nodes 10000 || return
	_tuish_tree_rebuild_visible "$_tree"
}

tuish_tree_add_node () {
	local _tree=$1 _node=$2 _parent=$3 _label=$4 _ids _count=0 _item _walk _depth=0 _max
	tuish_actor_valid_name "$_node" && tuish_actor_valid_value "$_label" || return 2
	_tuish_tree_has_node "$_tree" "$_parent" || return 4
	_tuish_tree_has_node "$_tree" "$_node" && return 3
	_walk=$_parent
	tuish_actor_get "$_tree" max_depth || return; _max=$TUISH_ACTOR_VALUE
	while test -n "$_walk"; do
		tuish_actor_get "$_tree" "node_parent_$_walk" || return 2
		_walk=$TUISH_ACTOR_VALUE
		_depth=$((_depth + 1))
	done
	test "$_depth" -le "$_max" || return 2
	tuish_actor_get "$_tree" node_ids || return; _ids=$TUISH_ACTOR_VALUE
	for _item in $_ids; do _count=$((_count + 1)); done
	tuish_actor_get "$_tree" max_nodes || return
	test "$_count" -lt "$TUISH_ACTOR_VALUE" || return 2
	tuish_actor_set "$_tree" "node_label_$_node" "$_label" || return
	tuish_actor_set "$_tree" "node_parent_$_node" "$_parent" || return
	tuish_actor_set "$_tree" "node_expanded_$_node" 0 || return
	tuish_actor_set "$_tree" node_ids "$_ids $_node" || return
	_tuish_tree_rebuild_visible "$_tree" || return
	_tuish_actor_emit "$_tree" data_change "$_node"
}

tuish_tree_set_label () {
	local _tree=$1 _node=$2 _label=$3
	_tuish_tree_has_node "$_tree" "$_node" || return 4
	tuish_actor_valid_value "$_label" || return 2
	tuish_actor_set "$_tree" "node_label_$_node" "$_label" || return
	_tuish_actor_emit "$_tree" data_change "$_node"
}

# Reparenting checks ancestry before committing, preventing self-links and cycles.
tuish_tree_set_parent () {
	local _tree=$1 _node=$2 _parent=$3 _walk=$_parent _depth=0 _root
	_tuish_tree_has_node "$_tree" "$_node" && _tuish_tree_has_node "$_tree" "$_parent" || return 4
	tuish_actor_get "$_tree" root_node || return; _root=$TUISH_ACTOR_VALUE
	test "$_node" != "$_root" || return 2
	while test -n "$_walk"
	do
		test "$_walk" != "$_node" || return 2
		test "$_walk" = "$_root" && break
		tuish_actor_get "$_tree" "node_parent_$_walk" || return 2
		_walk=$TUISH_ACTOR_VALUE
		_depth=$((_depth + 1))
		test "$_depth" -le 64 || return 2
	done
	tuish_actor_set "$_tree" "node_parent_$_node" "$_parent" || return
	_tuish_tree_rebuild_visible "$_tree"
}

_tuish_tree_walk () {
	local _tree=$1 _node=$2 _depth=$3 _prefix=$4 _ids _child _expanded _label _marker _indent _max
	tuish_actor_get "$_tree" max_depth || return; _max=$TUISH_ACTOR_VALUE
	test "$_depth" -le "$_max" || return 0
	tuish_actor_get "$_tree" node_ids || return; _ids=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" "node_label_$_node" || return; _label=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" "node_expanded_$_node" || :; _expanded=${TUISH_ACTOR_VALUE:-0}
	_marker=' '
	for _child in $_ids
	do
		tuish_actor_get "$_tree" "node_parent_$_child" || continue
		if test "$TUISH_ACTOR_VALUE" = "$_node"; then _marker='+'; break; fi
	done
	test "$_expanded" = 1 && _marker='-'
	_indent=''
	# Depth is bounded; no external seq/cut dependency.
	_child=0
	while test "$_child" -lt "$_depth"; do _indent="${_indent} "; _child=$((_child + 1)); done
	_tuish_tree_visible_ids="${_tuish_tree_visible_ids:+$_tuish_tree_visible_ids }$_node"
	_tuish_tree_rendered="${_tuish_tree_rendered}${_indent}${_marker} ${_label}
"
	if test "$_expanded" = 1
	then
		for _child in $_ids
		do
			tuish_actor_get "$_tree" "node_parent_$_child" || continue
			test "$TUISH_ACTOR_VALUE" = "$_node" || continue
			_tuish_tree_walk "$_tree" "$_child" "$((_depth + 1))" "$_prefix" || return
		done
	fi
}

_tuish_tree_rebuild_visible () {
	local _tree=$1 _root _all _selected _found=0 _i=1 _visible _offset _node
	tuish_actor_get "$_tree" root_node || return; _root=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" selected_id || :; _selected=$TUISH_ACTOR_VALUE
	_tuish_tree_visible_ids=''
	_tuish_tree_rendered=''
	_tuish_tree_walk "$_tree" "$_root" 0 '' || return
	_all=$_tuish_tree_visible_ids
	for _node in $_all
	do
		if test "$_node" = "$_selected"; then _found=$_i; fi
		_i=$((_i + 1))
	done
	if test "$_found" -eq 0; then
		_selected=$_root
		_found=1
		tuish_actor_set "$_tree" selected_id "$_root" || return
	fi
	tuish_actor_set "$_tree" visible_ids "$_all" || return
	tuish_actor_set "$_tree" item_count "$((_i - 1))" || return
	tuish_actor_set "$_tree" cursor "$_found" || return
	_tuish_tree_sync_view "$_tree"
}

_tuish_tree_sync_view () {
	local _tree=$1 _cursor _offset _visible _count
	tuish_actor_get "$_tree" cursor || return; _cursor=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" viewport_offset || return; _offset=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" visible_rows || return; _visible=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" item_count || return; _count=$TUISH_ACTOR_VALUE
	test "$_cursor" -ge "$_offset" || _offset=$_cursor
	test "$_cursor" -lt "$((_offset + _visible))" || _offset=$((_cursor - _visible + 1))
	test "$_offset" -ge 1 || _offset=1
	test "$_count" -ge "$_visible" || _offset=1
	tuish_actor_set "$_tree" viewport_offset "$_offset"
}

tuish_tree_select () {
	local _tree=$1 _node=$2 _ids _index=1 _item
	_tuish_tree_has_node "$_tree" "$_node" || return 4
	tuish_actor_get "$_tree" visible_ids || return; _ids=$TUISH_ACTOR_VALUE
	for _item in $_ids
	do
		if test "$_item" = "$_node"; then
			tuish_actor_set "$_tree" selected_id "$_node" || return
			tuish_actor_set "$_tree" cursor "$_index" || return
			_tuish_tree_sync_view "$_tree"
			_tuish_actor_emit "$_tree" select "$_node"
			return 0
		fi
		_index=$((_index + 1))
	done
	return 2
}

tuish_tree_move () {
	local _tree=$1 _delta=$2 _ids _count _cursor _node
	case "$_delta" in -*) _tuish_tree_uint "${_delta#-}" || return 2;; *) _tuish_tree_uint "$_delta" || return 2;; esac
	tuish_actor_get "$_tree" item_count || return; _count=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" cursor || return; _cursor=$TUISH_ACTOR_VALUE
	_cursor=$((_cursor + _delta))
	test "$_cursor" -ge 1 || _cursor=1
	test "$_cursor" -le "$_count" || _cursor=$_count
	tuish_actor_get "$_tree" visible_ids || return; _ids=$TUISH_ACTOR_VALUE
	set -- $_ids
	_node=''
	while test "$_cursor" -gt 1; do shift; _cursor=$((_cursor - 1)); done
	_node=$1
	_tuish_tree_select "$_tree" "$_node"
	_tuish_tree_sync_view "$_tree"
	_tuish_actor_emit "$_tree" navigate "$_node"
}

tuish_tree_toggle () {
	local _tree=$1 _node=${2:-} _expanded
	if test -z "$_node"; then tuish_actor_get "$_tree" selected_id || return; _node=$TUISH_ACTOR_VALUE; fi
	_tuish_tree_has_node "$_tree" "$_node" || return 4
	tuish_actor_get "$_tree" "node_expanded_$_node" || :; _expanded=${TUISH_ACTOR_VALUE:-0}
	if test "$_expanded" = 1; then
		tuish_actor_set "$_tree" "node_expanded_$_node" 0 || return
		_tuish_tree_rebuild_visible "$_tree" || return
		_tuish_actor_emit "$_tree" collapse "$_node"
	else
		tuish_actor_set "$_tree" "node_expanded_$_node" 1 || return
		_tuish_tree_rebuild_visible "$_tree" || return
		_tuish_actor_emit "$_tree" expand "$_node"
	fi
	_tuish_actor_emit "$_tree" toggle "$_node"
}

tuish_tree_resize () {
	local _tree=$1 _rows=$2
	_tuish_tree_uint "$_rows" && test "$_rows" -ge 1 && test "$_rows" -le 10000 || return 2
	tuish_actor_set "$_tree" visible_rows "$_rows" || return
	_tuish_tree_sync_view "$_tree" || return
	_tuish_actor_emit "$_tree" resize "$_rows"
}

tuish_tree_render () {
	local _tree=$1 _all _offset _visible _line=1 _item _selected _indent _width _out='' _ids _parent _node _spaces _label _expanded _marker _prefix
	_tuish_tree_rebuild_visible "$_tree" || return
	tuish_actor_get "$_tree" visible_ids || return; _all=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" viewport_offset || return; _offset=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" visible_rows || return; _visible=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" selected_id || return; _selected=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" indent_width || return; _width=$TUISH_ACTOR_VALUE
	tuish_actor_get "$_tree" node_ids || return; _ids=$TUISH_ACTOR_VALUE
	for _item in $_all
	do
		if test "$_line" -ge "$_offset" && test "$_line" -lt "$((_offset + _visible))"
		then
			tuish_actor_get "$_tree" "node_parent_$_item" || :; _parent=$TUISH_ACTOR_VALUE
			_indent=0
			while test -n "$_parent"; do _indent=$((_indent + 1)); _node=$_parent; tuish_actor_get "$_tree" "node_parent_$_parent" || break; _parent=$TUISH_ACTOR_VALUE; done
			_indent=$((_indent * _width))
			_spaces=''
			while test "${#_spaces}" -lt "$_indent"; do _spaces="${_spaces} "; done
			tuish_actor_get "$_tree" "node_label_$_item" || :; _label=$TUISH_ACTOR_VALUE
			tuish_actor_get "$_tree" "node_expanded_$_item" || :; _expanded=$TUISH_ACTOR_VALUE
			_marker=' '
			for _node in $_ids; do tuish_actor_get "$_tree" "node_parent_$_node" || continue; if test "$TUISH_ACTOR_VALUE" = "$_item"; then _marker='+'; break; fi; done
			test "$_expanded" = 1 && _marker='-'
			_prefix='  '; test "$_item" = "$_selected" && _prefix='> '
			_out="${_out}${_prefix}${_spaces}${_marker} ${_label}
"
		fi
		_line=$((_line + 1))
	done
	printf '%s' "$_out"
	_tuish_actor_emit "$_tree" render "$_selected"
}

tuish_tree_expand () {
	local _tree=$1 _node=${2:-}
	if test -z "$_node"; then tuish_actor_get "$_tree" selected_id || return; _node=$TUISH_ACTOR_VALUE; fi
	_tuish_tree_has_node "$_tree" "$_node" || return 4
	tuish_actor_set "$_tree" "node_expanded_$_node" 1 || return
	_tuish_tree_rebuild_visible "$_tree" || return
	_tuish_actor_emit "$_tree" expand "$_node"
}

tuish_tree_collapse () {
	local _tree=$1 _node=${2:-}
	if test -z "$_node"; then tuish_actor_get "$_tree" selected_id || return; _node=$TUISH_ACTOR_VALUE; fi
	_tuish_tree_has_node "$_tree" "$_node" || return 4
	tuish_actor_set "$_tree" "node_expanded_$_node" 0 || return
	_tuish_tree_rebuild_visible "$_tree" || return
	_tuish_actor_emit "$_tree" collapse "$_node"
}
