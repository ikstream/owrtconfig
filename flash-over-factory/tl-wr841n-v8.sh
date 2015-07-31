#!/bin/sh
#
###################
# TL-WR841ND-V8.0
#####################

_flash_over_factory_via_http()
{
	curl \
		--silent \
		--user-agent "${user_agent}" \
		--user "${user}":"${password}" \
		--include \
		--referer "http://${router_ip}/userRpm/SoftwareUpgradeRpm.htm" \
		--form "Filename=@${firmware}" -F "Upgrade=Upgrade" \
		"http://${router_ip}/incoming/Firmware.htm" \
		> /dev/null \
		2> /dev/null
	#	-o "${__basedir}/log-${node}.html"
}

