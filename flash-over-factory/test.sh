#!/bin/sh
set -x
set -e

__dirname="$( dirname ${0} )"
__pwd="$( pwd )"

FULL_PATH="${__pwd}${__dirname#.}"

#echo ${FULL_PATH}

. ${FULL_PATH}/_helper-functions.sh

_check_arguments
