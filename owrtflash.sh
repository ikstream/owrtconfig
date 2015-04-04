#!/bin/sh

# ${0} is used to flash openwrt sequentially on one or more devices.

__pwd="$( pwd )"
__dirname="$( dirname ${0} )" 
__basename="$( basename ${0} )"

. ${__dirname}/_helper-functions.sh

ME="${__basename}"
VER="0.02"


_usage() {
	cat <<__END_OF_USAGE
${ME} v${VAR}

	Usage: $ME OPTIONS -H HOSTS

		-H HOSTS        file containing hosts list (hwaddr)
		--factory       flashing for the first time (using curl)
		--sysupgrade    flashing with sysupgrade (# TODO)
		-v              be verbose (not implemented)
		
		-s              use sudo
		-h              display usage information
		-V              display version information
		
__END_OF_USAGE
}

_version() {
	cat <<__END_OF_VERSION
${ME} v${VER}
__END_OF_VERSION
}

_parse_args() {
	if [ -z "${1}" ]; then
		_error "[error] No arguemnts given."
	fi
	VERBOSITY_LEVEL=0
	while [ -n "${1}" ]; do
		case ${1} in
			-H|--hosts)
				shift
				if [ -z "${1}" ]; then
					_error "missing \`-H HOSTS\` argument"
				else
					HOSTS_FILE="${1}"
				fi
			;;
			--factory) 
				# TODO
				FACTORY=1
				. ${__dirname}/flash-over-factory/_helper-functions.sh
			;;
			--sysupgrade)
				# TODO
				SYSUPGRADE=1
			;;
			-s|--sudo)
				SUDO_FUNC="sudo"
			;;
			-v|--verbose) 
				VERBOSITY_LEVEL=$(( ${VERBOSITY_LEVEL} + 1 ))
			;;
			-h|--help)
				_usage
				exit 0
			;;
			-V|--version)
				_version
				exit 0
				;;
			*)
				_error "unexpected argument '${1}'"
			;;
		esac
		shift
	done
}


_parse_args $*


if [ -n "$SUDO_FUNC" ]; then
	_log "info" "${ME} - checking sudo..."
	$SUDO_FUNC true || _error "no \`sudo\` available"
fi


#################################

IFS_OLD="$IFS"
IFS_NEW=","
IFS="$IFS_NEW"

__log "log" "${ME} - "
$SUDO_FUNC /etc/init.d/network-manager stop

_log "info" "${ME} - looping over nodes (${HOSTS_FILE})..."
# I did not found a proper way. `grep [] ${HOSTS_FILE} | while []` did not worked
# So do not blame me for the useless use of cat and send me a fix 8-)
cat ${HOSTS_FILE} | grep -v '^#' | while read mac model firmware; 
do
	IFS="$IFS_OLD"
	_log "info" "${ME} - next device: '${model}' (${mac})"

	
	if [ ${FACTORY} ]; then
		_set_defaults_for_model
		_apply_network
	fi
	
	{	
		_log "info" "${mac} - testing network connection..."
		# TEST NETWORK CONNECTION TO ROUTER
		$SUDO_FUNC ip -s -s neigh flush all > /dev/null	2>/dev/null     # flushes neighbor arp-cache
		$SUDO_FUNC arp -s ${router_ip} ${mac} > /dev/null 2>/dev/null   # sets new address for ip in arp-cache
		ping -c 1 -q -r -t 1 ${router_ip} > /dev/null 2>/dev/null
	}

	# was `ping` successfull?
	if [ ${?} -eq 0 ]; then
		_log "log" "${mac} - network status: OK"
		
		if [ ${FACTORY} ]; then
			
			_log "info" "${mac} - flashing '${model}' with '${firmware}'"
			# TODO: If no firmwarefile is specified, get openwrt-*-generic-squashfs-factory.bin
			./flash-over-factory.sh "${model}" "${firmware}"
			_log "log" "${mac} - flashed firmware on ${model}: (hopefully) OK"
		
		elif [ ${SYSUPGRADE} ]; then
			
			# TODO
			:

		else
			
			_log "error" "neither '--factory' or '--sysupgrade' was specified."
			#_error "neither '--factory' or '--sysupgrade' was specified."
		fi
		
	else
		_log "error" "${mac} is not responsing."
		_log "log" "${mac} - network status: FAILED"
	fi

	# clear arp entry
	$SUDO_FUNC arp -d ${router_ip} > /dev/null 2>/dev/null
	IFS="$IFS_NEW"
done


__log "log" "${ME} - "
$SUDO_FUNC /etc/init.d/network-manager start; 
_log "info" "${ME} - wait 7 seconds..."
sleep 7

IFS="$IFS_OLD"

_log "info" "${ME} - exit"
exit 0
