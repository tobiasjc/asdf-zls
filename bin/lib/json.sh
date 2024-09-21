#!/usr/bin/env bash

# DEFINITIONS
TOKEN_OBJECT_OPEN='{'
TOKEN_ARRAY_OPEN='['
TOKEN_OBJECT_CLOSE='}'
TOKEN_ARRAY_CLOSE=']'
TOKEN_KEY_SEPARATOR=':'
TOKEN_QUOTE=$'\"'
TOKEN_COMMA=','
TOKEN_SPACE=' '
TOKEN_HTAB=$'\t'
TOKEN_VTAB=$'\v'
TOKEN_CARRIAGE_RETURN=$'\r'
TOKEN_NEWLINE=$'\n'
TOKEN_BACKSLASH=$"\\"
TOKEN_DOT="."

declare -A TOKEN_TO_CODE=(
	["$TOKEN_OBJECT_OPEN"]=0
	["$TOKEN_ARRAY_OPEN"]=1
	["$TOKEN_OBJECT_CLOSE"]=2
	["$TOKEN_ARRAY_CLOSE"]=3
	["$TOKEN_KEY_SEPARATOR"]=4
	["$TOKEN_QUOTE"]=5
	["$TOKEN_COMMA"]=6
	["$TOKEN_SPACE"]=7
	["$TOKEN_HTAB"]=8
	["$TOKEN_VTAB"]=9
	["$TOKEN_CARRIAGE_RETURN"]=10
	["$TOKEN_NEWLINE"]=11
	["$TOKEN_BACKSLASH"]=12
	["$TOKEN_DOT"]=12
)

declare -A CODES_TO_TOKEN=(
	[${TOKEN_TO_CODE["$TOKEN_OBJECT_OPEN"]}]="$TOKEN_OBJECT_OPEN"
	[${TOKEN_TO_CODE["$TOKEN_ARRAY_OPEN"]}]="$TOKEN_ARRAY_OPEN"
	[${TOKEN_TO_CODE["$TOKEN_OBJECT_CLOSE"]}]="$TOKEN_OBJECT_CLOSE"
	[${TOKEN_TO_CODE["$TOKEN_ARRAY_CLOSE"]}]="$TOKEN_ARRAY_CLOSE"
	[${TOKEN_TO_CODE["$TOKEN_KEY_SEPARATOR"]}]="$TOKEN_KEY_SEPARATOR"
	[${TOKEN_TO_CODE["$TOKEN_QUOTE"]}]="$TOKEN_QUOTE"
	[${TOKEN_TO_CODE["$TOKEN_COMMA"]}]="$TOKEN_COMMA"
	[${TOKEN_TO_CODE["$TOKEN_SPACE"]}]="$TOKEN_SPACE"
	[${TOKEN_TO_CODE["$TOKEN_HTAB"]}]="$TOKEN_HTAB"
	[${TOKEN_TO_CODE["$TOKEN_VTAB"]}]="$TOKEN_VTAB"
	[${TOKEN_TO_CODE["$TOKEN_CARRIAGE_RETURN"]}]="$TOKEN_CARRIAGE_RETURN"
	[${TOKEN_TO_CODE["$TOKEN_NEWLINE"]}]="$TOKEN_NEWLINE"
	[${TOKEN_TO_CODE["$TOKEN_BACKSLASH"]}]="$TOKEN_BACKSLASH"
	[${TOKEN_TO_CODE["$TOKEN_DOT"]}]="$TOKEN_DOT"
)

declare -A ___OPEN_CONTEXT_TOKENS_TO_CODE=(
	["$TOKEN_ARRAY_OPEN"]="${TOKEN_TO_CODE["$TOKEN_ARRAY_OPEN"]}"
	["$TOKEN_OBJECT_OPEN"]="${TOKEN_TO_CODE["$TOKEN_OBJECT_OPEN"]}"
)

declare -A ___CLOSE_CONTEXT_TOKENS_TO_CODE=(
	["$TOKEN_ARRAY_CLOSE"]="${TOKEN_TO_CODE["$TOKEN_ARRAY_CLOSE"]}"
	["$TOKEN_OBJECT_CLOSE"]="${TOKEN_TO_CODE["$TOKEN_OBJECT_CLOSE"]}"
)

declare -A ___OPEN_CONTEXT_TOKENS_TO_CLOSE=(
	["$TOKEN_ARRAY_OPEN"]="$TOKEN_ARRAY_CLOSE"
	["$TOKEN_OBJECT_OPEN"]="$TOKEN_OBJECT_CLOSE"
)

declare -A ___CLOSE_CONTEXT_TOKENS_TO_OPEN=(
	["$TOKEN_ARRAY_CLOSE"]="$TOKEN_ARRAY_OPEN"
	["$TOKEN_OBJECT_CLOSE"]="$TOKEN_OBJECT_OPEN"
)

declare -A ___VOID_TOKENS_TO_CODE=(
	["$TOKEN_SPACE"]="${TOKEN_TO_CODE["$TOKEN_SPACE"]}"
	["$TOKEN_HTAB"]="${TOKEN_TO_CODE["$TOKEN_HTAB"]}"
	["$TOKEN_VTAB"]="${TOKEN_TO_CODE["$TOKEN_VTAB"]}"
	["$TOKEN_CARRIAGE_RETURN"]="${TOKEN_TO_CODE["$TOKEN_CARRIAGE_RETURN"]}"
	["$TOKEN_NEWLINE"]="${TOKEN_TO_CODE["$TOKEN_NEWLINE"]}"
	["$TOKEN_DOT"]="${TOKEN_TO_CODE["$TOKEN_DOT"]}"
	["$TOKEN_COMMA"]="${TOKEN_TO_CODE["$TOKEN_COMMA"]}"
)

declare -A ___NAN_TOKENS_TO_CODE=(
	["$TOKEN_SPACE"]="${TOKEN_TO_CODE["$TOKEN_SPACE"]}"
	["$TOKEN_HTAB"]="${TOKEN_TO_CODE["$TOKEN_HTAB"]}"
	["$TOKEN_VTAB"]="${TOKEN_TO_CODE["$TOKEN_VTAB"]}"
	["$TOKEN_CARRIAGE_RETURN"]="${TOKEN_TO_CODE["$TOKEN_CARRIAGE_RETURN"]}"
	["$TOKEN_NEWLINE"]="${TOKEN_TO_CODE["$TOKEN_NEWLINE"]}"
	["$TOKEN_COMMA"]="${TOKEN_TO_CODE["$TOKEN_COMMA"]}"
	["$TOKEN_OBJECT_CLOSE"]="${TOKEN_TO_CODE["$TOKEN_OBJECT_CLOSE"]}"
	["$TOKEN_ARRAY_CLOSE"]="${TOKEN_TO_CODE["$TOKEN_ARRAY_CLOSE"]}"
)

declare -A ___VOID_SIDE_TOKENS_TO_CODE=(
	["$TOKEN_COMMA"]="${TOKEN_TO_CODE["$TOKEN_COMMA"]}"
	["$TOKEN_KEY_SEPARATOR"]="${TOKEN_TO_CODE["$TOKEN_KEY_SEPARATOR"]}"
)

# PUBLIC API
declare ___JSON_TEXT=""
declare -i ___JSON_POSITION=0
declare -i ___JSON_CONTEXT_LEVEL=0
declare ___JSON_SIDE="key"

function json_init() {
	___JSON_TEXT="$1"
	___JSON_POSITION=0
	___JSON_CONTEXT_LEVEL=0
	___JSON_SIDE="key"
}

function json_next_key_value() {
	local -n ___key="$1"
	local -n ___value="$2"

	while :; do
		# 0. ending condition
		if [ $___JSON_POSITION -ge ${#___JSON_TEXT} ]; then
			return 1
		fi

		char="${___JSON_TEXT:$___JSON_POSITION:1}"
		# 1. escapes and out of value context following
		if [ -n "${___VOID_TOKENS_TO_CODE["$char"]}" ]; then
			___JSON_POSITION=$((___JSON_POSITION + 1))
			continue
		fi

		if [ "$___JSON_SIDE" = "key" ]; then
			if [ -n "${___OPEN_CONTEXT_TOKENS_TO_CODE["$char"]}" ]; then
				___JSON_CONTEXT_LEVEL=$((___JSON_CONTEXT_LEVEL + 1))
				___JSON_POSITION=$((___JSON_POSITION + 1))
				continue
			elif [ -n "${___CLOSE_CONTEXT_TOKENS_TO_CODE["$char"]}" ]; then
				___JSON_CONTEXT_LEVEL=$((___JSON_CONTEXT_LEVEL - 1))
				___JSON_POSITION=$((___JSON_POSITION + 1))
				if [ $___JSON_CONTEXT_LEVEL -eq 0 ]; then
					break
				fi

				continue
			fi
		fi

		# 2. quoted keys and values
		if [ "$char" = "$TOKEN_QUOTE" ]; then
			___JSON_POSITION=$((___JSON_POSITION + 1))
			start=$___JSON_POSITION

			last_char="$char"
			char="${___JSON_TEXT:$___JSON_POSITION:1}"
			while [ "$last_char" = "$TOKEN_BACKSLASH" ] || [ "$char" != "$TOKEN_QUOTE" ]; do
				last_char="$char"
				char="${___JSON_TEXT:$___JSON_POSITION:1}"
				___JSON_POSITION=$((___JSON_POSITION + 1))
			done

			end=$((___JSON_POSITION - 1))
			value="${___JSON_TEXT:$start:$((end - start))}"
			if [ "$___JSON_SIDE" = "key" ]; then
				___key="$value"
				___JSON_SIDE="value"
				___JSON_POSITION=$((___JSON_POSITION + 1))
				continue
			else
				___value="$value"
				___JSON_SIDE="key"
				return 0
			fi
		fi

		# only values
		if [ "$___JSON_SIDE" = "value" ]; then
			if [ -n "${___OPEN_CONTEXT_TOKENS_TO_CODE["$char"]}" ]; then
				start=$___JSON_POSITION
				context_level=1
				while [ $context_level -gt 0 ]; do
					___JSON_POSITION=$((___JSON_POSITION + 1))
					char="${___JSON_TEXT:$___JSON_POSITION:1}"

					# skips quote contexts
					if [ "$char" = "$TOKEN_QUOTE" ]; then
						last_char="$char"
						___JSON_POSITION=$((___JSON_POSITION + 1))
						char="${___JSON_TEXT:$___JSON_POSITION:1}"
						while [ "$last_char" = "$TOKEN_BACKSLASH" ] || [ "$char" != "$TOKEN_QUOTE" ]; do
							last_char="$char"
							char="${___JSON_TEXT:$___JSON_POSITION:1}"
							___JSON_POSITION=$((___JSON_POSITION + 1))
						done
						char="${___JSON_TEXT:$___JSON_POSITION:1}"
					fi

					if [ -n "${___OPEN_CONTEXT_TOKENS_TO_CODE["$char"]}" ]; then
						context_level=$((context_level + 1))
					elif [ -n "${___CLOSE_CONTEXT_TOKENS_TO_CODE["$char"]}" ]; then
						context_level=$((context_level - 1))
					fi
				done
				___JSON_POSITION=$((___JSON_POSITION + 1))
				end=$((___JSON_POSITION))
				___value="${___JSON_TEXT:$start:$((end - start))}"
				___JSON_SIDE="key"
				return 0
			else # this gotta be a number... right? yeah, this gotta be a number...
				start=$___JSON_POSITION
				char="${___JSON_TEXT:$___JSON_POSITION:1}"
				while [ "$char" != "$TOKEN_COMMA" ] && [ "$char" != "$TOKEN_ARRAY_CLOSE" ] && [ "$char" != "$TOKEN_OBJECT_CLOSE" ]; do
					___JSON_POSITION=$((___JSON_POSITION + 1))
					char="${___JSON_TEXT:$___JSON_POSITION:1}"
				done
				___value="${___JSON_TEXT:$start:$((___JSON_POSITION - start))}"
				___JSON_SIDE="key"
				___JSON_POSITION=$((___JSON_POSITION + 1))
				return 0
			fi
		fi
		___JSON_POSITION=$((___JSON_POSITION + 1))
	done

	return 0
}

# txt="$(cat 'input.txt')"
# json_init "${txt}"
# while json_next_key_value key value; do
# 	echo "$key = $value"
# done
