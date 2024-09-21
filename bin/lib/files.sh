#!/usr/bin/env bash

declare -A PLATFORM_TO_EXTENSION=(
	["macos"]="tar.xz"
	["linux"]="tar.xz"
	["wasi"]="tar.xz"
	["windows"]="zip"
)

function output_filename() {
	version="$1"
	platform="$2"
	arch="$3"

	echo -n "zls-${version}-${arch}-${platform}.${PLATFORM_TO_EXTENSION["$platform"]}"
}

function input_filename() {
	platform="$1"
	arch="$2"

	echo -n "zls-${arch}-${platform}.${PLATFORM_TO_EXTENSION["$platform"]}"
}

function executable_filename() {
	platform="$1"

	# chose the extraction method based on the platform
	case "$platform" in
	"windows")
		echo -n "zls.exe"
		;;
	"macos" | "linux" | "wasi")
		echo -n "zls"
		;;
	*)
		echo "Platform '$platform' is not yet supported!" >&2
		exit 1
		;;
	esac
}
