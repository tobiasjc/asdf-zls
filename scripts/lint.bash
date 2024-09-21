#!/usr/bin/env bash

# lint this repo
shellcheck --shell=bash --external-sources \
	bin/**

shfmt --language-dialect bash --diff \
	bin/**
