#!/bin/sh

_check_firmware_path() {
	if [ ! -f "${1}" ]; then
		_error "firmware not found"
		exit 1
	else
		firmware="${1}"
	fi
}

_reset_network() {
	$SUDO_FUNC ip route flush table main  >/dev/null 2>/dev/null
	$SUDO_FUNC ip addr flush dev eth0     >/dev/null 2>/dev/null
}

_apply_network() {
	_reset_network
	$SUDO_FUNC ip addr add ${client_ip}/24 dev eth0  >/dev/null 2>/dev/null
}


_set_defaults_for_model() {

	user_agent="Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:12.0) Gecko/20100101 Firefox/12.0"

	case "${model}" in
		tl-wr84*)
			router_ip="192.168.0.1"
			client_ip="192.168.0.100"
			user="admin"
			password="admin"
			#referer_url="http://${router_ip}/userRpm/SoftwareUpgradeRpm.htm"
			#url="http://${router_ip}/incoming/Firmware.htm"
		;;
		tl-wr841*-v8)
			::
		;;
		tl-wr842*-v1)
			::
			#
		;;
		*)
			_error "mode '${model}' is not supported. please add default ip for this device."
		;;

	esac

}

