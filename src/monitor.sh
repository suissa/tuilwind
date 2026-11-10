#!/bin/sh

# SPDX-License-Identifier: ISC
# src/monitor.sh - best-effort host/system metrics for live terminal dashboards.
# Reads procfs when available; portable fallbacks avoid hard dependencies.

if test -n "${_tuish_monitor_loaded:-}"; then return 0; fi
_tuish_monitor_loaded=1

tuish_monitor_snapshot () {
	TUISH_MON_HOST=${HOSTNAME:-${HOST:-unknown}}
	TUISH_MON_OS=${OSTYPE:-unknown}
	TUISH_MON_UPTIME='n/a'
	TUISH_MON_LOAD='n/a'
	TUISH_MON_MEM='n/a'
	TUISH_MON_PROCS='n/a'
	TUISH_MON_CPU='n/a'
	if test -r /proc/uptime; then read -r _tm_up _tm_rest </proc/uptime; TUISH_MON_UPTIME=${_tm_up%%.*}s; fi
	if test -r /proc/loadavg; then read -r TUISH_MON_LOAD _tm_rest </proc/loadavg; fi
	if test -r /proc/meminfo
	then
		_tm_total=0; _tm_avail=0
		while read -r _tm_key _tm_val _tm_unit
		do
			case "$_tm_key" in MemTotal:) _tm_total=$_tm_val;; MemAvailable:) _tm_avail=$_tm_val;; esac
		done </proc/meminfo
		if test "$_tm_total" -gt 0 2>/dev/null
		then TUISH_MON_MEM="$(( (_tm_total - _tm_avail) * 100 / _tm_total ))% used"; fi
	fi
	if test -d /proc; then TUISH_MON_PROCS=$(find /proc -maxdepth 1 -type d -name '[0-9]*' 2>/dev/null | wc -l | tr -d ' '); fi
	if command -v uptime >/dev/null 2>&1; then TUISH_MON_LOAD=$(uptime 2>/dev/null | sed 's/.*load average[s]*: *//'); fi
}
