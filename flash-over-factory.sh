#!/bin/sh
#
# ${1}	:	${model}
# ${2}	:	${firmware}
#

__pwd="$( pwd )"
__dirname="$( dirname ${0} )" 
__basename="$( basename ${0} )"

. ${__dirname}/_helper-functions.sh
. ${__dirname}/${__basename%.sh}/_helper-functions.sh

ME="${__basename}"
VER="0.01"

############################################

# If ${model} and ${firmware} are not given via argument 
# and are not set something is wrong
if [ -z "$*" -a -z "${model}" -a -z "${firmware}" ]; then
	_error '${model} and ${firmware} was not given or specified.'

else
	model="${1}"
	firmware="${2}"
fi

_set_defaults_for_model
${__dirname}/${__basename%.sh}/${model}.sh ${firmware}
