#!/usr/bin/env bash

function system_platform() {
	uname="$(uname | tr '[:upper:]' '[:lower:]')"
	case "$uname" in
	"linux" | "freebsd")
		platform="linux"
		;;
	"darwin")
		platform="macos"
		;;
	*)
		echo "Platform '$uname' is not yet supported!" >&2
		exit 1
		;;
	esac

	echo -n "$platform"
}

function system_arch() {
	uname=$(uname -m)
	case "$uname" in
	"x86_64" | "amd64")
		arch="x86_64"
		;;
	"aarch64" | "arm64")
		arch="aarch64"
		;;
	"wasm32")
		arch="wasm32"
		;;
	*)
		echo "Arch '$uname' is not yet supported!" >&2
		exit 1
		;;
	esac

	echo -n "$arch"
}
