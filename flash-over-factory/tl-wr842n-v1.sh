#!/bin/sh
#
# 	${1}	: 	firmware file path
#

. $(pwd)/_helper_functions.sh

_check_arguments "${1}" && _check_firmware_path "${1}" # sets ${firmware}

model=$(basename ${0}) 	# the name of this script
model=${model%.sh}		# strip file extention

###################
# TL-WR842ND-V1.0
#####################

_set_defaults_for "${model}"

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

