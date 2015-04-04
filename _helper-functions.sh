#!/bin/sh

_log() {
	# ${1} 	: type [log|info|error]
	# ${2}	: message

	echo "$(date "+%F %T") [${1}] ${2}"
}

__log() {
	echo -n "$(date "+%F %T") [${1}] ${2}"
}

_error() {
	echo "${ME}: ${*}"
	exit 1
}

