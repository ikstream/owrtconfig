#!/bin/sh
#
# ${1}	:	${model}
# ${2}	:	${firmware}
#
############################################

__dirname="$( dirname ${0} )"
__basename="$( basename ${0} )"

. ${__dirname}/owrtflash-ng.sh

# If ${model} and ${firmware} are not given via argument 
# and are not set something is wrong
if [ -z "$*" -a -z "${model}" -a -z "${firmware}" ]; then
	_error '${model} and ${firmware} was not given or specified.'

else
	model="${1}"
	firmware="${2}"
fi


${__dirname}/${__basename%.sh}/${model}.sh ${firmware}
