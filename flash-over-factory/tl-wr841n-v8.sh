#!/bin/sh
#
###################
# TL-WR841ND-V8.0
#####################

_flash_over_factory() {

	fw="${FIRMWARE_DIR}/${firmware}"
	if [ ! -e "${fw}" ]; then
		_log "error" "Firmware '${fw}' not found!"
		exit 1
	fi

	#	-o "${__basedir}/log-${node}.html" \
	curl \
		--silent \
		--user-agent "${user_agent}" \
		--user "${user}":"${password}" \
		--include \
		--referer "http://${router_ip}/userRpm/SoftwareUpgradeRpm.htm" \
		--form "Filename=@${fw}" -F "Upgrade=Upgrade" \
		"http://${router_ip}/incoming/Firmware.htm" \
		> /dev/null 2> /dev/null
}

