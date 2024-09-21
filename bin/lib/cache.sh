#!/usr/bin/env bash

CACHE_UPDATE_INTERVAL=300 # a.k.a 5 minutes
PATH_DIR="$(dirname "$0")/.cache/"

function write_cache() {
	local name data
	name="$1"
	data="$2"
	mkdir -p "$PATH_DIR"
	echo -n "$data" >"${PATH_DIR}/${name}" 2>/dev/null
}

function read_cache() {
	local name
	local -n value
	name="$1"
	value="$2"

	local cache_file
	cache_file="${PATH_DIR}/${name}"
	if [ ! -f "$cache_file" ]; then
		return 1
	fi

	local -i current_time last_update
	current_time="$(date +%s)"
	last_update="$(stat --format=%Y "$cache_file" 2>/dev/null)"
	if [ $((current_time - last_update)) -lt $CACHE_UPDATE_INTERVAL ]; then
		value="$(cat "$cache_file")"
		return 0
	fi
	return 1
}
