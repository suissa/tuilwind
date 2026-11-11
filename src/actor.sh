#!/bin/sh

# SPDX-FileCopyrightText: 2026
# SPDX-License-Identifier: ISC
# src/actor.sh - portable Actor runtime and TUI widget behavior primitives.
# Source after compat.sh and tui.sh. No subprocesses are started by this module.

if test -n "${_tuish_actor_loaded:-}"; then return 0; fi
_tuish_actor_loaded=1

TUISH_ACTORS=''
_tuish_actor_records=''

_tuish_actor_valid_name () { case "$1" in ''|*[!A-Za-z0-9_-]*) return 1;; esac; }
_tuish_actor_valid_key () { case "$1" in ''|*[!A-Za-z0-9_]*) return 1;; esac; }
_tuish_actor_is_uint () { case "$1" in ''|*[!0-9]*) return 1;; esac; }
_tuish_actor_exists () { case " $TUISH_ACTORS " in *" $1 "*) return 0;; *) return 1;; esac; }
_tuish_actor_valid_value () { case "$1" in *'|'*|*'
'*) return 1;; esac; }

tuish_actor_supported () {
	case "$1" in
		progress|slide-motion|table|tree|split-view|text-input|text-area|viewport|spinner|tabs|mouse-adapter|fullscreen|command-launcher|list|help|keymap|cursor|confirm-dialog|file-picker|timer|paginator|markdown|code-editor|bics-plugin|bics-plugin-cli) return 0;;
		*) return 1;;
	esac
}

# Records are newline-separated triples: actor-id|property|value. Newlines and
# the separator are rejected in values, keeping storage parseable in POSIX sh.
_tuish_actor_put () {
	local _id=$1 _key=$2 _value=$3 _next='' _line _rid _rkey
	_tuish_actor_valid_value "$_value" || return 2
	while IFS= read -r _line
	do
		test -z "$_line" && continue
		_rid=${_line%%|*}; _line=${_line#*|}
		_rkey=${_line%%|*}
		if test "$_rid" = "$_id" && test "$_rkey" = "$_key"; then continue; fi
		_next="${_next}${_rid}|${_rkey}|${_line}
"
	done <<EOF
$_tuish_actor_records
EOF
	_tuish_actor_records="${_next}${_id}|${_key}|${_value}
"
}

tuish_actor_get () {
	local _id=$1 _key=$2 _line _rid _rkey
	TUISH_ACTOR_VALUE=''
	while IFS= read -r _line
	do
		test -z "$_line" && continue
		_rid=${_line%%|*}; _line=${_line#*|}
		_rkey=${_line%%|*}; _line=${_line#*|}
		if test "$_rid" = "$_id" && test "$_rkey" = "$_key"; then TUISH_ACTOR_VALUE=$_line; return 0; fi
	done <<EOF
$_tuish_actor_records
EOF
	return 1
}

tuish_actor_create () {
	local _id=$1 _kind=$2 _parent=${3:-}
	_tuish_actor_valid_name "$_id" && tuish_actor_supported "$_kind" || return 2
	case " $TUISH_ACTORS " in *" $_id "*) return 3;; esac
	if test -n "$_parent"; then
		_tuish_actor_valid_name "$_parent" || return 2
		_tuish_actor_exists "$_parent" || return 4
		test "$_parent" != "$_id" || return 2
	fi
	TUISH_ACTORS="${TUISH_ACTORS:+$TUISH_ACTORS }$_id"
	_tuish_actor_put "$_id" actor_id "$_id" || return
	_tuish_actor_put "$_id" kind "$_kind" || return
	_tuish_actor_put "$_id" parent "$_parent" || return
	_tuish_actor_put "$_id" parent_id "$_parent" || return
	_tuish_actor_put "$_id" state '' || return
	_tuish_actor_put "$_id" subscriptions '' || return
	_tuish_actor_put "$_id" render_region '' || return
	_tuish_actor_put "$_id" mailbox_count 0 || return
	_tuish_actor_put "$_id" lifecycle created || return
	_tuish_actor_put "$_id" selected_index 0 || return
	_tuish_actor_put "$_id" value '' || return
	_tuish_actor_emit "$_id" init ''
}

tuish_actor_set () {
	local _id=$1 _key=$2 _value=$3
	_tuish_actor_valid_name "$_id" && _tuish_actor_valid_key "$_key" || return 2
	_tuish_actor_exists "$_id" || return 1
	_tuish_actor_put "$_id" "$_key" "$_value"
}

tuish_actor_on () {
	local _id=$1 _event=$2 _fn=$3
	_tuish_actor_valid_name "$_id" && _tuish_actor_valid_key "$_event" && _tuish_actor_valid_name "$_fn" || return 2
	command -v "$_fn" >/dev/null 2>&1 || return 3
	tuish_actor_set "$_id" "on_$_event" "$_fn"
}

_tuish_actor_emit () {
	local _id=$1 _event=$2 _payload=${3:-} _fn
	tuish_actor_get "$_id" "on_$_event" || return 0
	_fn=$TUISH_ACTOR_VALUE
	test -n "$_fn" || return 0
	"$_fn" "$_id" "$_payload"
}

tuish_actor_send () {
	local _id=$1 _message=${2:-}
	case " $TUISH_ACTORS " in *" $_id "*) ;; *) return 1;; esac
	tuish_actor_get "$_id" lifecycle
	test "$TUISH_ACTOR_VALUE" = destroyed && return 1
	_tuish_actor_emit "$_id" message "$_message"
}

# Dispatch a named Actor event with its payload. Keep tuish_actor_send as the
# message-channel API; component lifecycle/state events use this dispatcher.
tuish_actor_emit () {
	local _id=$1 _event=$2 _payload=${3:-}
	case " $TUISH_ACTORS " in *" $_id "*) ;; *) return 1;; esac
	tuish_actor_get "$_id" lifecycle || return
	test "$TUISH_ACTOR_VALUE" = destroyed && return 1
	_tuish_actor_emit "$_id" "$_event" "$_payload"
}

tuish_actor_start () {
	tuish_actor_get "$1" lifecycle || return
	test "$TUISH_ACTOR_VALUE" = destroyed && return 1
	tuish_actor_set "$1" lifecycle running
	_tuish_actor_emit "$1" start ''
}

tuish_actor_stop () {
	tuish_actor_get "$1" lifecycle || return
	test "$TUISH_ACTOR_VALUE" = destroyed && return 1
	tuish_actor_set "$1" lifecycle stopped
	_tuish_actor_emit "$1" stop ''
}

tuish_actor_destroy () {
	local _id=$1 _next='' _line _rid
	_tuish_actor_valid_name "$_id" || return 2
	case " $TUISH_ACTORS " in *" $_id "*) ;; *) return 1;; esac
	_tuish_actor_emit "$_id" shutdown ''
	while IFS= read -r _line
	do
		test -z "$_line" && continue
		_rid=${_line%%|*}
		test "$_rid" = "$_id" || _next="${_next}${_line}
"
	done <<EOF
$_tuish_actor_records
EOF
	_tuish_actor_records=$_next
	_next=''
	for _rid in $TUISH_ACTORS; do test "$_rid" = "$_id" || _next="${_next:+$_next }$_rid"; done
	TUISH_ACTORS=$_next
}

tuish_actor_kind () { tuish_actor_get "$1" kind; TUISH_ACTOR_KIND=$TUISH_ACTOR_VALUE; }
tuish_actor_count () { set -- $TUISH_ACTORS; TUISH_ACTOR_COUNT=$#; }

# Shared, deterministic widget state transitions. Components keep their
# domain-specific properties but share navigation and selection semantics.
tuish_actor_step () {
	local _id=$1 _action=$2 _value=${3:-0} _index=0 _count=0
	tuish_actor_get "$_id" selected_index || return
	_index=${TUISH_ACTOR_VALUE:-0}
	_tuish_actor_is_uint "$_index" || return 2
	tuish_actor_get "$_id" item_count || :
	_count=${TUISH_ACTOR_VALUE:-0}
	_tuish_actor_is_uint "$_count" || return 2
	case "$_action" in
		next) test "$_count" -gt 0 && _index=$(( (_index + 1) % _count ));;
		previous) test "$_count" -gt 0 && _index=$(( (_index + _count - 1) % _count ));;
		select) _tuish_actor_is_uint "$_value" || return 2; _index=$_value; test "$_index" -lt "$_count" || return 2;;
		set-value) tuish_actor_set "$_id" value "$_value";;
		progress) _tuish_actor_is_uint "$_value" && test "$_value" -le 100 || return 2; tuish_actor_set "$_id" percent "$_value";;
		toggle) tuish_actor_get "$_id" expanded || :; if test "$TUISH_ACTOR_VALUE" = 1; then _value=0; else _value=1; fi; tuish_actor_set "$_id" expanded "$_value";;
		scroll) case "$_value" in -*) _tuish_actor_is_uint "${_value#-}" || return 2;; *) _tuish_actor_is_uint "$_value" || return 2;; esac; tuish_actor_get "$_id" offset || :; _index=${TUISH_ACTOR_VALUE:-0}; _tuish_actor_is_uint "$_index" || return 2; _index=$((_index + _value)); test "$_index" -ge 0 || _index=0; tuish_actor_set "$_id" offset "$_index";;
		confirm) tuish_actor_set "$_id" result confirmed;;
		cancel) tuish_actor_set "$_id" result cancelled;;
		*) return 2;;
	esac
	case "$_action" in next|previous|select) tuish_actor_set "$_id" selected_index "$_index";; esac
	_tuish_actor_emit "$_id" update "$_action"
}

tuish_actor_render_text () {
	local _id=$1 _label=${2:-} _kind _value
	tuish_actor_kind "$_id" || return
	_kind=$TUISH_ACTOR_KIND
	tuish_actor_get "$_id" value || :; _value=$TUISH_ACTOR_VALUE
	case "$_kind" in
		progress) tuish_actor_get "$_id" percent || :; _value="${TUISH_ACTOR_VALUE:-0}%";;
		spinner) _value='⠋';;
		confirm-dialog) tuish_actor_get "$_id" result || :; _value=${TUISH_ACTOR_VALUE:-pending};;
	esac
	printf '%s%s%s' "$_label" "${_label:+: }" "$_value"
}

# Domain actions give every registered component a meaningful state transition.
# Rendering and device integration continue to use the existing tuilwind modules.
tuish_actor_action () {
	local _id=$1 _action=$2 _value=${3:-} _kind
	tuish_actor_kind "$_id" || return 1
	_kind=$TUISH_ACTOR_KIND
	case "$_kind" in
		progress) test "$_action" = set || return 2; tuish_actor_step "$_id" progress "$_value";;
		slide-motion)
			case "$_action" in
				seek) if command -v tuish_motion_scrub >/dev/null 2>&1; then tuish_motion_scrub "$_id" "$_value"; else _tuish_actor_is_uint "$_value" || return 2; tuish_actor_set "$_id" current_frame "$_value"; fi;;
				advance) command -v tuish_motion_advance >/dev/null 2>&1 || return 2; tuish_motion_advance "$_id" "$_value";;
				enter) command -v tuish_motion_enter >/dev/null 2>&1 || return 2; tuish_motion_enter "$_id";;
				wait) command -v tuish_motion_wait >/dev/null 2>&1 || return 2; tuish_motion_wait "$_id";;
				resume) command -v tuish_motion_resume >/dev/null 2>&1 || return 2; tuish_motion_resume "$_id";;
				exit) command -v tuish_motion_exit >/dev/null 2>&1 || return 2; tuish_motion_exit "$_id";;
				finish) command -v tuish_motion_finish >/dev/null 2>&1 || return 2; tuish_motion_finish "$_id";;
				cancel) command -v tuish_motion_cancel >/dev/null 2>&1 || return 2; tuish_motion_cancel "$_id";;
				*) return 2;;
			esac;;
		table)
			case "$_action" in
				select) command -v tuish_table_select >/dev/null 2>&1 || return 2; tuish_table_select "$_id" "$_value";;
				next) command -v tuish_table_move >/dev/null 2>&1 || return 2; tuish_table_move "$_id" 1;;
				previous) command -v tuish_table_move >/dev/null 2>&1 || return 2; tuish_table_move "$_id" -1;;
				scroll) command -v tuish_table_scroll >/dev/null 2>&1 || return 2; tuish_table_scroll "$_id" "$_value";;
				resize) command -v tuish_table_resize >/dev/null 2>&1 || return 2; tuish_table_resize "$_id" "$_value";;
				render) command -v tuish_table_render >/dev/null 2>&1 || return 2; tuish_table_render "$_id";;
				filter) tuish_actor_set "$_id" filter "$_value";;
				*) return 2;;
			esac;;
		list|tabs|command-launcher) case "$_action" in select) tuish_actor_step "$_id" select "$_value";; filter) tuish_actor_set "$_id" filter "$_value";; *) return 2;; esac;;
		tree)
			case "$_action" in
				toggle) if command -v tuish_tree_toggle >/dev/null 2>&1; then tuish_tree_toggle "$_id" "$_value"; else tuish_actor_step "$_id" toggle; fi;;
				expand) command -v tuish_tree_expand >/dev/null 2>&1 && tuish_tree_expand "$_id" "$_value" || return 2;;
				collapse) command -v tuish_tree_collapse >/dev/null 2>&1 && tuish_tree_collapse "$_id" "$_value" || return 2;;
				select) command -v tuish_tree_select >/dev/null 2>&1 && tuish_tree_select "$_id" "$_value" || return 2;;
				next) command -v tuish_tree_move >/dev/null 2>&1 && tuish_tree_move "$_id" 1 || return 2;;
				previous) command -v tuish_tree_move >/dev/null 2>&1 && tuish_tree_move "$_id" -1 || return 2;;
				resize) command -v tuish_tree_resize >/dev/null 2>&1 && tuish_tree_resize "$_id" "$_value" || return 2;;
				render) command -v tuish_tree_render >/dev/null 2>&1 && tuish_tree_render "$_id" || return 2;;
				*) return 2;;
			esac;;
		split-view) test "$_action" = ratio || return 2; command -v tuish_split_view_set_ratio >/dev/null 2>&1 || return 2; tuish_split_view_set_ratio "$_id" "$_value";;
		text-input) case "$_action" in input|replace) if command -v tuish_text_input_set >/dev/null 2>&1; then tuish_text_input_set "$_id" "$_value"; else tuish_actor_set "$_id" value "$_value"; fi;; insert) command -v tuish_text_input_insert >/dev/null 2>&1 || return 2; tuish_text_input_insert "$_id" "$_value";; backspace) command -v tuish_text_input_backspace >/dev/null 2>&1 || return 2; tuish_text_input_backspace "$_id";; delete) command -v tuish_text_input_delete >/dev/null 2>&1 || return 2; tuish_text_input_delete "$_id";; *) return 2;; esac;;
		text-area|code-editor) case "$_action" in input|replace) tuish_actor_set "$_id" value "$_value";; *) return 2;; esac;;
		viewport) test "$_action" = scroll || return 2; tuish_actor_step "$_id" scroll "$_value";;
		spinner) test "$_action" = tick || return 2; tuish_actor_get "$_id" frame_index || :; _value=$(( ${TUISH_ACTOR_VALUE:-0} + 1 )); tuish_actor_set "$_id" frame_index "$_value";;
		mouse-adapter) test "$_action" = position || return 2; tuish_actor_set "$_id" pointer "$_value";;
		fullscreen) case "$_action" in enter) tuish_actor_start "$_id"; tuish_actor_set "$_id" active 1;; exit) tuish_actor_stop "$_id"; tuish_actor_set "$_id" active 0;; *) return 2;; esac;;
		help) test "$_action" = toggle || return 2; tuish_actor_step "$_id" toggle;;
		keymap) test "$_action" = bind || return 2; tuish_actor_set "$_id" binding "$_value";;
		cursor) test "$_action" = move || return 2; tuish_actor_set "$_id" position "$_value";;
		confirm-dialog) case "$_action" in confirm|cancel) tuish_actor_step "$_id" "$_action";; *) return 2;; esac;;
		file-picker) case "$_action" in navigate) tuish_actor_set "$_id" path "$_value";; filter) tuish_actor_set "$_id" filter "$_value";; *) return 2;; esac;;
		timer) test "$_action" = tick && _tuish_actor_is_uint "$_value" || return 2; tuish_actor_get "$_id" remaining_ms || :; _value=$(( ${TUISH_ACTOR_VALUE:-0} - _value )); test "$_value" -ge 0 || _value=0; tuish_actor_set "$_id" remaining_ms "$_value";;
		paginator) case "$_action" in next|previous) tuish_actor_get "$_id" page || :; _value=${TUISH_ACTOR_VALUE:-0}; test "$_action" = next && _value=$((_value + 1)); test "$_action" = previous && _value=$((_value - 1)); test "$_value" -ge 0 || _value=0; tuish_actor_set "$_id" page "$_value";; *) return 2;; esac;;
		markdown) test "$_action" = source || return 2; tuish_actor_set "$_id" source "$_value";;
		bics-plugin) case "$_action" in register) tuish_actor_set "$_id" plugin_state registered;; reload) tuish_actor_set "$_id" plugin_state reloaded;; *) return 2;; esac;;
		bics-plugin-cli) case "$_action" in scaffold|validate|reload|remove) tuish_actor_set "$_id" cli_action "$_action";; *) return 2;; esac;;
		*) return 2;;
	esac
}


# Elm/MVU broker. One process-local FIFO is shared by all Actors so messages
# retain a total, deterministic order. A callback may enqueue more work, but
# nested dispatch is suppressed; the outer drain owns the queue.
_tuish_actor_mailbox=''
_tuish_actor_effects=''
_tuish_actor_sequence=0
_tuish_actor_dispatching=0
TUISH_ACTOR_DISPATCH_LIMIT=${TUISH_ACTOR_DISPATCH_LIMIT:-256}
TUISH_ACTOR_SEQUENCE=0
TUISH_ACTOR_MESSAGE=''

_tuish_actor_enqueue () {
	local _id=$1 _message=$2 _count
	_tuish_actor_valid_name "$_id" || return 2
	_tuish_actor_valid_value "$_message" || return 2
	_tuish_actor_exists "$_id" || return 1
	tuish_actor_get "$_id" lifecycle || return 1
	test "$TUISH_ACTOR_VALUE" != destroyed || return 1
	tuish_actor_get "$_id" mailbox_count || :
	_count=${TUISH_ACTOR_VALUE:-0}
	_tuish_actor_is_uint "$_count" || return 2
	_tuish_actor_sequence=$((_tuish_actor_sequence + 1))
	TUISH_ACTOR_SEQUENCE=$_tuish_actor_sequence
	tuish_actor_set "$_id" mailbox_count "$((_count + 1))" || return
	_tuish_actor_mailbox="${_tuish_actor_mailbox}${_tuish_actor_sequence}|$_id|$_message
"
}

tuish_actor_post () {
	_tuish_actor_enqueue "$1" "${2-}"
}

tuish_actor_send () {
	_tuish_actor_enqueue "$1" "${2-}" || return
	tuish_actor_dispatch
}

# Effects are commands/data, not shell source. The registered on_effect
# function decides how to interpret them; the pure update callback never does I/O.
tuish_actor_cmd () {
	local _id=$1 _effect=${2-}
	_tuish_actor_valid_value "$_effect" || return 2
	_tuish_actor_exists "$_id" || return 1
	_tuish_actor_effects="${_tuish_actor_effects}$_id|$_effect
"
}

_tuish_actor_run_effects () {
	local _line _id _effect _batch _round=0
	while test -n "$_tuish_actor_effects" && test "$_round" -lt "$TUISH_ACTOR_DISPATCH_LIMIT"
	do
		_batch=$_tuish_actor_effects
		_tuish_actor_effects=''
		while IFS= read -r _line
		do
			test -n "$_line" || continue
			_id=${_line%%|*}; _effect=${_line#*|}
			if _tuish_actor_exists "$_id"; then
				tuish_actor_get "$_id" lifecycle || :
				if test "$TUISH_ACTOR_VALUE" != destroyed; then
					_tuish_actor_emit "$_id" effect "$_effect" || return
				fi
			fi
		done <<EOF
$_batch
EOF
		_round=$((_round + 1))
	done
	test -z "$_tuish_actor_effects" || return 75
}

tuish_actor_dispatch () {
	local _line _sequence _id _message _child _payload _processed=0 _status=0
	test "$_tuish_actor_dispatching" -eq 0 || return 0
	case "$TUISH_ACTOR_DISPATCH_LIMIT" in ''|*[!0-9]*|0) return 2;; esac
	_tuish_actor_dispatching=1
	while test -n "$_tuish_actor_mailbox" && test "$_processed" -lt "$TUISH_ACTOR_DISPATCH_LIMIT"
	do
		_line=${_tuish_actor_mailbox%%'
'*}
		if test "$_line" = "$_tuish_actor_mailbox"; then _tuish_actor_mailbox=''; else _tuish_actor_mailbox=${_tuish_actor_mailbox#*'
'}; fi
		_sequence=${_line%%|*}; _line=${_line#*|}
		_id=${_line%%|*}; _message=${_line#*|}
		TUISH_ACTOR_SEQUENCE=$_sequence
		TUISH_ACTOR_MESSAGE=$_message
		_processed=$((_processed + 1))
		if _tuish_actor_exists "$_id"; then
			tuish_actor_get "$_id" mailbox_count || :
			_line=${TUISH_ACTOR_VALUE:-0}
			_tuish_actor_is_uint "$_line" && test "$_line" -gt 0 && tuish_actor_set "$_id" mailbox_count "$((_line - 1))"
			tuish_actor_get "$_id" lifecycle || :
			if test "$TUISH_ACTOR_VALUE" != destroyed; then
				case "$_message" in
					child:*)
						_line=${_message#child:}
						_child=${_line%%:*}; _payload=${_line#*:}
						_tuish_actor_emit "$_id" child_message "$_child|$_payload" || { _status=$?; break; }
						_tuish_actor_emit "$_id" update "child:$_child|$_payload" || { _status=$?; break; } ;;
					*)
						_tuish_actor_emit "$_id" message "$_message" || { _status=$?; break; }
						_tuish_actor_emit "$_id" update "$_message" || { _status=$?; break; } ;;
				esac
			fi
		fi
		tuish_actor_dispatch_effects || { _status=$?; break; }
	done
	_tuish_actor_dispatching=0
	test "$_status" -eq 0 || return "$_status"
	if test -n "$_tuish_actor_mailbox"; then return 75; fi
	return 0
}

tuish_actor_dispatch_effects () { _tuish_actor_run_effects; }

tuish_actor_send_child () {
	local _child=$1 _message=${2-} _parent
	tuish_actor_get "$_child" parent || return
	_parent=$TUISH_ACTOR_VALUE
	test -n "$_parent" || return 1
	_tuish_actor_valid_value "$_message" || return 2
	_tuish_actor_enqueue "$_parent" "child:$_child:$_message" || return
	tuish_actor_dispatch
}

# View is explicitly separate from message/update processing. The renderer can
# be called by the existing event loop or host after state has settled.
tuish_actor_render () {
	local _id=$1
	_tuish_actor_exists "$_id" || return 1
	_tuish_actor_emit "$_id" render "${2-}"
}

tuish_actor_update () {
	local _id=$1 _message=${2-}
	_tuish_actor_exists "$_id" || return 1
	_tuish_actor_emit "$_id" update "$_message"
}

# Register a complete Elm-style program using function names only:
# tuish_actor_program ID MESSAGE UPDATE VIEW EFFECT [CHILD_MESSAGE] [INIT] [SHUTDOWN]
tuish_actor_program () {
	local _id=$1 _message=$2 _update=$3 _view=$4 _effect=$5
	local _child=${6:-} _init=${7:-} _shutdown=${8:-}
	_tuish_actor_on_optional "$_id" message "$_message" || return
	_tuish_actor_on_optional "$_id" update "$_update" || return
	_tuish_actor_on_optional "$_id" render "$_view" || return
	_tuish_actor_on_optional "$_id" effect "$_effect" || return
	test -z "$_child" || _tuish_actor_on_optional "$_id" child_message "$_child" || return
	test -z "$_init" || { _tuish_actor_on_optional "$_id" init "$_init" || return; _tuish_actor_emit "$_id" init ''; }
	test -z "$_shutdown" || _tuish_actor_on_optional "$_id" shutdown "$_shutdown"
}

_tuish_actor_on_optional () {
	local _id=$1 _event=$2 _fn=$3
	test -n "$_fn" || return 0
	tuish_actor_on "$_id" "$_event" "$_fn"
}
