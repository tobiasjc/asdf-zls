#!/usr/bin/env bash

declare -ia MIN_VERSION=(0 12 0)

function is_min_version() {
	local version="$1"
	declare -ia parts

	local oldifs="$IFS"
	IFS='.'
	read -r -a parts <<<"$version"
	IFS="$oldifs"

	for ((i = 0; i < ${#MIN_VERSION[@]}; i++)); do
		if [ ${parts[$i]} -lt ${MIN_VERSION[$i]} ]; then
			return 1
		fi
	done

	return 0
}
