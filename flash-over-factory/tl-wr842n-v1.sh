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
# TL-WR842ND-V1.0
#####################

SESSTION_FILE=".${model}-session.temp.html"

curl \
	--silent \
	--user-agent "${user_agent}" \
	--user ${user}:${password} \
	--referer "http://${router_ip}/userRpm/SoftwareUpgradeRpm.htm" \
	--form "Filename=@${firmware}" -F 'Upgrade=Upgrade' \
	"http://${router_ip}/incoming/Firmware.htm" \
	> ${SESSION_FILE}
 	2> /dev/null

session_id=$(sed -n 's/var session_id = \"\(.*\)\".*/\1/p' ${SESSION_FILE})

curl \
	--user-agent "${user_agent}" \
	--silent \
	--max-time 2 \
	--user ${user}:${password} \
	--referer "http://${router_ip}/incoming/Firmware.htm" \
	"http://${router_ip}/userRpm/FirmwareUpdateTemp.htm?session_id=${session_id}" \
	> /dev/null \
	2> /dev/null

rm "${SESSION_FILE}"

# Reference:
#	http://wiki.openwrt.org/toh/tp-link/tl-mr3020

