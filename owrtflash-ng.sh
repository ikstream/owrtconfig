#
# TODO
# * Give 'nodes' instat of 'hosts' file as agument
#
# * if ipaddr and/or other variable are set in the node state is custom
#		then the first atempt are to ping ip via routing table
#	otherwise state have to be factory or openwrt or have to detect via auto detect.
#
#
# Feature request
#	tftp-server for model tl-wr841n-v9, tl-wdr4300v1
#		use dnsmasq and static ip configuration
#

#!/bin/sh
#set -x

__dirname="$( dirname ${0} )"
__basename="$( basename ${0} )"

__basedir="${__dirname}"

_set_ME() {
	ME="${__basename}"
}

_set_VER() {
	VER="2.00"
}

#######################
_date() {
	echo -n "$( date "+%F %T")"
}

_log() {
	# ${1} 	: type [log|info|error]
	# ${2}	: message

	echo "$( _date ) [${1}] ${2}"
}

__log() {
	echo -n "$( _date ) [${1}] ${2}"
}

_error() {
	echo "$( _date ) ${*}"
	exit 1
}


_check_requirements() {

CMD="arp
cat
curl
grep
ip
ping
pgrep
ssh
telnet"

	for cmd in ${CMD}; do
		if [ ! $( $SUDO_FUNC which ${cmd} ) ]; then
			_error "'${cmd}' is not installed or available."
		fi
	done

}

########################################
_usage() {
	cat <<__END_OF_USAGE
${ME} v${VAR}

Usage: $ME OPTIONS -H HOSTS

	--nodes NODES    comma seperated list of node-names
	--state STATE    factory | openwrt
	--verbose        be verbose # TODO
	
	--sudo           use sudo
	--help           display usage information
	--version        display version information
	
__END_OF_USAGE
}

_version() {
	cat <<__END_OF_VERSION
${ME} v${VER}
__END_OF_VERSION
}

_set_sudo_func()
{
	if [ -n "$SUDO_FUNC" ]; then
		_log "info" "${ME} - checking sudo..."
		$SUDO_FUNC true || _error "no \`sudo\` available"
	fi
}


_reset_network() {
	$SUDO_FUNC ip route flush table main dev eth0     >/dev/null 2>/dev/null
	$SUDO_FUNC ip addr flush dev eth0                 >/dev/null 2>/dev/null
}
_set_client_ip() {
	_reset_network
	if [ $( cat /sys/class/net/eth0/operstate ) = "down" ]; then
		$SUDO_FUNC ip link set eth0 up                >/dev/null 2>/dev/null
	fi
	$SUDO_FUNC ip addr add ${client_ip}/24 dev eth0   >/dev/null 2>/dev/null
}

_flush_arp_cache(){
	$SUDO_FUNC ip -s -s neigh flush all dev eth0      >/dev/null 2>/dev/null  # flushes neighbor arp-cache
}
_set_arp_entry() {
	$SUDO_FUNC arp -s ${router_ip} ${macaddr}         >/dev/null 2>/dev/null  # sets new address for ip in arp-cache
}

_reset_arp_router_ip() {
	$SUDO_FUNC arp -d ${router_ip}                    >/dev/null 2>/dev/null  # delets ip from arp-cache
}

_ping_router_ip() {
	ping -c 1 -r -t 1 ${router_ip}                    >/dev/null 2>/dev/null
}

########################################

_get_state() {
	# TODO
	# Using nmap to decide node is in factory or openwrt mode
	# Can not get model version exactly so far...

	LEASE_FILE="/var/lib/dhcp/dhclient.leases"

	$SUDO_FUNC rm -f "${LEASE_FILE}"
	
	$SUDO_FUNC dhclient -v eth0

	router_ip=$( grep 'option routers' "${LEASE_FILE}" | awk '{print $3}' | sed 's/;//' )
	client_ip=$( grep 'fixed-address' "${LEASE_FILE}" | awk '{print $2}' | sed 's/;//' )

	nmap -A -T5 -n --open -p1-1024 -sV -oG - "${router_ip}"

	false

}


_set_generic_defaults() {
	. "${__basedir}/defaults/generic"
}

_set_model_defaults() {
	. "${__basedir}/defaults/models/${model}"
}

_set_factory_defaults() {

	protocol="http"
	
	# TODO
	# Instead of writing all configs in this we can source defaults
	# Find a generic way

	if [ -f "${__basedir}/defaults/factory/${model}" ]; then
		. "${__basedir}/defaults/factory/${model}"
		_log "info" "Loaded factory defaults for '${model}'."
	else
		_error "error" "No factory defaults for '${model}' were found."
	fi
	
}

_get_openwrt_firmware_file_name() {
	curl \
		--insecure \
		--silent \
		"https://downloads.openwrt.org/${OPENWRT_RELEASE_NAME}/${OPENWRT_RELEASE_DATE}/${chipset}/generic/md5sums" \
	| grep -E "${model}.*factory" | awk '{ print $2 }' 

}

_get_openwrt_firmware_file_md5sum() {
	curl \
		--insecure \
		--silent \
		"https://downloads.openwrt.org/${OPENWRT_RELEASE_NAME}/${OPENWRT_RELEASE_DATE}/${chipset}/generic/md5sums" \
	| grep -E "${model}.*factory" | awk '{ print $1 }' 

}

_download_openwrt() {
	# TODO

	# get firmware_file_name
	firmware_file_name="$( _get_openwrt_firmware_file_name )"

	# cleanup file name
	firmware_file_name="${firmware_file_name#"*"}"
	
	
	if [ ! -e "${firmware_dir}/${firmware_file_name}" ]; then
		
		firmware_file_url="https://downloads.openwrt.org/${OPENWRT_RELEASE_NAME}/${OPENWRT_RELEASE_DATE}/${chipset}/generic/${firmware_file_name}"
		curl \
			--insecure \
			--silent \
			--output ${firmware_dir}/${firmware_file_name} \
			"${firmware_file_url}"
	fi

	firmware="${{firmware_dir}/${firmware_file_name}"

}

_set_openwrt_defaults() {

	. "${__basedir}/defaults/openwrt/generic"

	# TODO
	OPENWRT_RELEASE_NAME="barrier_breaker"
	case ${OPENWRT_RELEASE_NAME} in
		a*_a*)
			OPENWRT_RELEASE_DATE="12.07"
			;;
		b*_b*)
			OPENWRT_RELEASE_DATE="14.07"
			;;
		*)
			_error "Unknown OPENWRT_RELEASE_NAME '${OPENWRT_RELEASE_NAME}'."
			;;
	esac
	
	if [ -z ${firmware} ]; then
		_download_openwrt
	fi

}


########################################

_set_node() {
	# TODO
	# serial_number
	:
}


########################################
##################################
###########################
############### MAIN

_parse_args() {

	if [ -z "${1}" ]; then
		:
		#_error "[error] No arguemnts given."
		#exit 0
	fi

	VERBOSITY_LEVEL=0
	while [ -n "${1}" ]; do
		case ${1} in
			-n|--nodes)
				shift
				if [ -z "${1}" ]; then
					_error "missing \`-n NODES\` argument"
				else
					NODES="${1}"
				fi
			;;
			--state)
				shift
				case ${1} in
					factory)
						state="factory"
						;;
					openwrt)
						state="openwrt"
						;;
					*)
						_error "Unknown state '${1}'"
						;;
				esac
			;;
			-s|--sudo)
				SUDO_FUNC="sudo"
				_set_sudo_func
			;;
			-v|--verbose) 
				# TODO
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
			--download-openwrt)
				for __model in $( ls ${__basedir}/defaults/factory ); do
					#
					:
				done
			;;
			*)
				_error "unexpected argument '${1}'"
			;;
		esac
		shift
	done

}

########################################
####################

_parse_args ${*}

if [ ! -z "${1}" ]; then
	
	_set_ME
	_set_VER
	
	_check_requirements
	
	if [ $( pgrep --count "NetworkManager" ) -ge 1 ]; then
		NetworkManager=1
		__log "log" "${ME} - "
		$SUDO_FUNC /etc/init.d/network-manager stop
	fi
	
	nodes_dir="${__dirname}/nodes"
	
	if [ -z ${NODES} ]; then
		NODES="$( ls ${nodes_dir} )"
		_log "info" "${ME} - Start looping over nodes in '${nodes_dir}'..."
	else
		_log "info" "${ME} - Start looping over '${NODES}'..."
	fi
	
	
	for node_file in ${NODES}; do
	
		if [ ! -f "${nodes_dir}/${node_file}" ]; then
			_error "Could not load '${node_file}'"
		fi
	
		. "${nodes_dir}/${node_file}"
		node="${node_file}"
		
		_log "log" "${ME} - Next device in list: '${node}' - '${model}' - '${macaddr}'"
		
		# TODO
		# _get_state
		
		_set_generic_defaults
		_set_model_defaults
		
		case ${state} in 
			factory)
				_set_factory_defaults
				;;
			openwrt)
				_set_openwrt_defaults
				;;
			"")
				_get_state || _error "No state was given and autodetect failed."
				;;
			*)
				_get_state || _error "Your state ('${state}') is unknown, and autodetect failed, too."
				;;
		esac
		
		_log "info" "${node} - Setting client IP to ${client_ip}"
		_set_client_ip
		_log "info" "Flushing arp table..."
		_flush_arp_cache
		_log "info" "Setting arp table entry for '${router_ip}' on '${macaddr}'..."
		_set_arp_entry
		_log "info" "Testing network connection"
		_ping_router_ip
		
		. "${nodes_dir}/${node_file}"
		
		if [ ${?} -eq 0 ]; then
			_log "log" "${node} - Network status: OK"
			
			case ${state} in
				factory)
					
					if [ -z ${firmware} ]; then
						_download_openwrt
					fi
					
					_log "info" "${node} - Flashing with '${firmware}'..."
						. ${__basedir}/flash-over-factory/${model}.sh  # TODO
					_flash_over_factory                                # TODO
				;;
	
				openwrt)
					# TODO
					case ${protocol} in 
						telnet)
							# TODO
							nc -l 1234 < ${firmware}
							{ 
								nc ${client_ip} 1234 > /tmp/fw
								sleep 1
								sysupgrade -n /tmp/fw
							} \
							  | telnet ${router_ip}
						;;
						ssh)
							# TODO
							scp ${firmware} ${user}@${router_ip}:/tmp/fw
							ssh ${user}@${router_ip} "nohup sysupgrade -n /tmp/fw > /dev/null 2> /dev/null < /dev/null &"
						;;
					esac
					
				;;
	
				*)
					_error "Unknown state."
				;;
			esac
	
		else
			_log "error" "${node} is not responsing."
			_log "log" "${node} - Network status: FAILED"
			_log "log" "${ME} - Skipping '${node}'..."
		fi
		
		_reset_network
		_reset_arp_router_ip
	
	done
	
	_log "log" "${ME} - Finished."

	if [ ${NetworkManager} ]; then
		__log "log" "${ME} - "
		$SUDO_FUNC /etc/init.d/network-manager start; 
		_log "info" "${ME} - wait 7 seconds..."
		sleep 7
	fi
	
	_log "info" "${ME} - exit"
	exit 0
fi

