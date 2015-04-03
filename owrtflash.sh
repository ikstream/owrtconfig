#!/bin/sh

# ${0} is used to flash openwrt sequentially on one or more router(s).
# There are two main operations modes: factory2openwrt and openwrt2openwrt 
# (Maybe in the future a third mode --openwrt2factory-- will be implemented.)

ME="owrtflash.sh"
VER="0.02"

. ./_helper-functions.sh


_usage() {
	cat <<__END_OF_USAGE
${ME} v${VAR}

Usage: $ME OPTIONS -H HOSTS

	-H HOSTS        file containing hosts list (hwaddr)
	--factory       flashing for the first time (using curl)
	--sysupgrade    flashing with sysupgrade (# TODO)
	-v              be verbose
    
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
			*)
				_error "unexpected argument '${1}'"
			;;
		esac
		shift
	done
}


_parse_args $*


if [ -n "$SUDO_FUNC" ]; then
	echo "** checking sudo.."
	$SUDO_FUNC true || _error "no \`sudo\` available"
fi


#################################

IFS_OLD="$IFS"
IFS_NEW=","
IFS="$IFS_NEW"

_log "info" "looping over nodes..."
# I did not found a proper way. `grep [] ${HOSTS_FILE} | while []` did not worked
cat ${HOSTS_FILE} | grep -v '^#' | while read mac model firmware; 
do
	IFS="$IFS_OLD"
	echo "-----"
	_log "info" "next device in list: ${mac} (${model})"

	
	if [ ${FACTORY} ]; then
		. flash-over-factory/_helper-functions.sh
		_set_defaults_for_model
		_apply_network
	fi
	
	{	# TEST NETWORK CONNECTION TO ROUTER
		$SUDO_FUNC ip -s -s neigh flush all					# flushes neighbor arp-cache
		$SUDO_FUNC arp -s ${router_ip} ${mac} > /dev/null	# sets new address for ip in arp-cache
		ping -c 1 -q -r -t 1 ${router_ip} ip > /dev/null
	}

	# was `ping` successfull?
	if [ $? -eq 0 ]; then
		
		if [ ${FACTORY} ]; then
			
			_log "log" "flasing '${model}' (${mac}) with '${firmware}'"
			# TODO: If no firmwarefile is specified, get openwrt-*-generic-squashfs-factory.bin
			./flash-over-factory/"${model}".sh "${firmware}"
		
		elif [ ${SYSUPGRADE} ]; then

			# TODO
			:

		else

			_error "neither '--factory' or '--sysupgrade' was specified."
		fi

	else
		_log "error" "${model} (${mac}) is not responsing."
	fi

	# clear arp entry
	$SUDO_FUNC arp -d ${router_ip} > /dev/null
	IFS="$IFS_NEW"
done


IFS="$IFS_OLD"

exit 0
