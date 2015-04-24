#!/bin/sh
#
###################
# TL-WR841ND-V8.0
#####################

_flash_over_factory() {

	curl \
		--silent \
		--user-agent "${user_agent}" \
		--user "${user}":"${password}" \
		--include \
		--referer "http://${router_ip}/userRpm/SoftwareUpgradeRpm.htm" \
		--form upload=@"${firmware_dir}/${firmware}" \
		"http://${router_ip}/incoming/Firmware.htm" \
		> /dev/null \
		2> /dev/null
		#-o log-tl-wr841n-v8-flash.html
}

