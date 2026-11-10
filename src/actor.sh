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
	_tuish_actor_valid_name "$_parent" || test -z "$_parent" || return 2
	TUISH_ACTORS="${TUISH_ACTORS:+$TUISH_ACTORS }$_id"
	_tuish_actor_put "$_id" kind "$_kind" || return
	_tuish_actor_put "$_id" parent "$_parent" || return
	_tuish_actor_put "$_id" lifecycle created || return
	_tuish_actor_put "$_id" selected_index 0 || return
	_tuish_actor_put "$_id" value '' || return
	_tuish_actor_emit "$_id" init ''
}

tuish_actor_set () {
	local _id=$1 _key=$2 _value=$3
	_tuish_actor_valid_name "$_id" && _tuish_actor_valid_key "$_key" || return 2
	case " $TUISH_ACTORS " in *" $_id "*) ;; *) return 1;; esac
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
	tuish_actor_get "$_id" item_count || :
	_count=${TUISH_ACTOR_VALUE:-0}
	case "$_action" in
		next) test "$_count" -gt 0 && _index=$(( (_index + 1) % _count ));;
		previous) test "$_count" -gt 0 && _index=$(( (_index + _count - 1) % _count ));;
		select) _index=$_value; test "$_index" -ge 0 && test "$_index" -lt "$_count" || return 2;;
		set-value) tuish_actor_set "$_id" value "$_value";;
		progress) test "$_value" -ge 0 && test "$_value" -le 100 || return 2; tuish_actor_set "$_id" percent "$_value";;
		toggle) tuish_actor_get "$_id" expanded || :; if test "$TUISH_ACTOR_VALUE" = 1; then _value=0; else _value=1; fi; tuish_actor_set "$_id" expanded "$_value";;
		scroll) tuish_actor_get "$_id" offset || :; _index=${TUISH_ACTOR_VALUE:-0}; _index=$((_index + _value)); test "$_index" -ge 0 || _index=0; tuish_actor_set "$_id" offset "$_index";;
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
