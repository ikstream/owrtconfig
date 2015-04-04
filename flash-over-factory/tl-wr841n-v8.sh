#!/bin/sh
#
# 	${1}	: 	firmware file path
#
#############
# 	Caution	:	Use at your own risk!
#
############################################

__pwd="$( pwd )"
__dirname="$( dirname ${0} )" 
__basename="$( basename ${0} )"

. ${__dirname}/../_helper-functions.sh
. ${__dirname}/_helper-functions.sh

ME="${__basename}"

############################################

_check_firmware_path "${1}" # sets ${firmware}

# if ${model} does not exists we have had called this script directly, so we 
# have to find out what we want to flash
if [ ! ${model} ]; then
	model=$(basename ${0}) 	# the name of this script
	model=${model%.sh}		# strip file extention
	_set_defaults_for_model
fi

###################
# TL-WR841ND-V8.0
#####################

curl \
	--silent \
	--user-agent "${user_agent}" \
	--user ${user}:${password} \
	--include \
	--referer "http://${router_ip}/userRpm/SoftwareUpgradeRpm.htm" \
	--form upload=@"${firmware}" \
	"http://${router_ip}/incoming/Firmware.htm" \
	> /dev/null \
	2> /dev/null
	#-o log-tl-wr841n-v8-flash.html

