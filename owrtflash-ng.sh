#!/bin/sh
#set -x

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

__dirname="$( dirname $( readlink -f "${0}" ) )"
__basename="$( basename ${0} )"

__basedir="${__dirname}"

_set_ME() {
	ME="${__basename}"
}

_set_VER() {
	VER="2.00"
}


#####################
## HELPER FUNCTION ##
#####################

_date() {
	echo -n "$( date "+%F %T")"
}
########

_log() {
	# ${1} 	: type [log|info|error]
	# ${2}	: message

	echo "$( _date ) [${1}] ${2}"
}
#######

__log() {
	echo -n "$( _date ) [${1}] ${2}"
}
#######

_error() {
	echo "[error] $( _date ) ${1}"
}
#######

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
		if [ -z "$( ${SUDO_FUNC} -i which ${cmd} )" ] ; then
			_error "'${cmd}' is not installed or available."
		fi
	done

}
#######

_set_sudo_func()
{
	if [ -n "$SUDO_FUNC" ]; then
		_log "info" "${ME} - Check for \`sudo\`"
		$SUDO_FUNC true || _error "\`sudo\` not available."
	fi
}

#######


##############################
## NETWORK HELPER FUNCTIONS ##
##############################

_flush_neigh(){
	_log "info" "Flush neighbour table"
	$SUDO_FUNC ip neighbour flush dev eth0            >/dev/null 2>/dev/null  # flushes all neighbors on link
}
#######

_reset_network() {
	_log "info" "Reset network" # TODO
	_flush_neigh
	$SUDO_FUNC ip route flush table main dev eth0     >/dev/null 2>/dev/null
	$SUDO_FUNC ip addr flush dev eth0                 >/dev/null 2>/dev/null
}
#######

_set_client_ip() {
	_reset_network

	_log "info" "${node}: Setting client IP to ${client_ip}"
	$SUDO_FUNC ip link set eth0 up                    >/dev/null 2>/dev/null
	$SUDO_FUNC ip addr add ${client_ip}/24 dev eth0   >/dev/null 2>/dev/null
}
#######

_set_arp_entry() {
	_log "info" "${node}: Setting arp table entry for '${router_ip}' on '${macaddr}'"
	$SUDO_FUNC arp -s ${router_ip} ${macaddr}         >/dev/null 2>/dev/null  # sets new address for ip in arp-cache
}
#######

_reset_arp_entry() {
	$SUDO_FUNC arp -d ${router_ip}                    >/dev/null 2>/dev/null  # delets ip from arp-cache
}
#######

_ping_router_ip() {
	_log "info" "${node}: Testing network connection to ${macaddr}"
	ping -c 1 -r -t 1 ${router_ip}                    >/dev/null 2>/dev/null
}
#######


###################################
## SET DEFAULTS HELPER FUNCTIONS ##
###################################

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
#######

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
		_log "info" "${node}: Load factory defaults for '${model}'."
	else
		_error "${node}: No factory defaults for '${model}' found."
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

_download_openwrt() {		# TODO
	firmware_file_name="$( _get_openwrt_firmware_file_name )"
	firmware_file_name="${firmware_file_name#"*"}"		# Cleanup file name
	
	if [ ! -e "${FIRMWARE_DIR}/${firmware_file_name}" ]; then
		firmware_file_url="https://downloads.openwrt.org/${OPENWRT_RELEASE_NAME}/${OPENWRT_RELEASE_DATE}/${chipset}/generic/${firmware_file_name}"
		curl \
			--insecure \
			--silent \
			--output ${FIRMWARE_DIR}/${firmware_file_name} \
			"${firmware_file_url}"
	fi
	firmware="${{FIRMWARE_DIR}/${firmware_file_name}"
}
#######

_set_openwrt_defaults() {
	. "${__basedir}/defaults/openwrt/generic"
	OPENWRT_RELEASE_NAME="barrier_breaker"		# TODO
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

_set_node() {		# TODO
	# serial_number
	:
}


###################
## MAIN FUNCTION ##
###################

_version() {
	cat <<__END_OF_VERSION
${ME} v${VER}
__END_OF_VERSION
}
#######

_usage() {
	_set_ME
	_set_VER
	cat <<__END_OF_USAGE
${ME} v${VER}

Usage: $ME OPTIONS

    --nodes NODES    comma seperated list of node-names,
                     or a directory containing all node-files
    --state STATE    factory | openwrt
    --verbose        be verbose # TODO
    
    --sudo           use sudo
    --nm             configure network-manager (means disable)
    --help           display usage information
    --version        display version information
    --ping-test      just ping all nodes
    
__END_OF_USAGE
}
#######

_parse_args() {

	if [ -z "${1}" ]; then
		_error "No arguemnts given."
		_usage
		exit 1
	fi

	VERBOSITY_LEVEL=0
	while [ -n "${1}" ]; do
		case ${1} in
			-h|--help)
				_usage && exit 0
				;;
			
			-V|--version)
				_version && exit 0
				;;

			-n|--nodes)
				shift
				if [ -z "${1}" ]; then
					_error "\`--nodes\` requires an argument."
				else
					# If it is not a directory, it is a comma seperated list
					if [ ! -d "${1}" ]; then
						OPT_NODES="$( echo ${1} | sed 's/,/ /g' )" 	# Translate to shell list
					else
						case ${1} in
							*/)
								OPT_NODES="${1}*"
								;;
							*)
								OPT_NODES="${1}/*"
								;;
						esac
					fi
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
			
			--nm)
				NETWORK_MANAGER=1
				;;
			
			-v|--verbose) 	# TODO
				VERBOSITY_LEVEL=$(( ${VERBOSITY_LEVEL} + 1 ))
				;;
			
			
			--download-openwrt)		# TODO
				for __model in $( ls ${__basedir}/defaults/factory ); do
					:
				done
				;;

			--ping-test)
				OPT_PING_TEST=1
				;;
			
			*)
				_error "Unexpected argument '${1}'"
				;;
		esac
		shift
	done
}

##########
## MAIN ##
##########

# DEFAULT SETTINGS
NETWORK_MANGER=0
FIRMWARE_DIR="${__basedir}/firmware-images"

_set_ME
_set_VER

_parse_args ${*}
_check_requirements

if [ "${NETWORK_MANAGER}" = "1" ]; then
	__log "log" "${ME} - "
	$SUDO_FUNC /etc/init.d/network-manager stop
fi

if [ -z "${OPT_NODES}" ]; then
	NODES_DIR="${__dirname}/nodes"
	OPT_NODES="$( ls ${NODES_DIR} )"
	_log "info" "${ME} - Start looping over nodes in '${NODES_DIR}'..."
else
	_log "info" "${ME} - Start looping over '${OPT_NODES}'..."
fi

# Loop over nodes
for node_file in ${OPT_NODES}; do

	node="${node_file}"
	
	if [ ! -f "${NODES_DIR}/${node_file}" ]; then
		_error "${node}: Could not load config '${node_file}'"
		_log "log" "${node}: Skipping node"

	else
		_log "log" "*** Next device in list: '${node}' - '${model}' - '${macaddr}' ***"
		. "${NODES_DIR}/${node_file}"		# Load node config
		
		# _get_state # TODO
		_set_generic_defaults
		_set_model_defaults
		
		case ${state} in 
			factory)
				_set_factory_defaults
				;;
			openwrt)
				_set_openwrt_defaults
				;;
		esac
		
		. "${NODES_DIR}/${node_file}"		# Load node config, again ...
	
		_set_client_ip
		_set_arp_entry
		
		_ping_router_ip
		case ${?} in
			0)
				_log "log" "${node}: Network status: OK"
	
				if [ ! ${OPT_PING_TEST} ]; then
	
					case ${state} in
						factory)
							
							if [ -z ${firmware} ]; then
								_download_openwrt		# TODO
							fi
							
							_log "info" "${node} - Flashing with '${firmware}'..."
								. ${__basedir}/flash-over-factory/${model}.sh  # TODO # but works atm
							_flash_over_factory                                # TODO # but works atm
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
							esac # END of PROTOCOL
							;;
						esac # END of STATE
					fi # END of OPT_PING_TEST
				;;
			
			*)
				_log "error" "${node}: Network status: FAILED - Not responsing."
				_log "log" "$node}: Skipping node"
				;;
		esac	# END of _ping_router_ip
			
		_reset_arp_entry
	fi

done
_log "log" "${ME} - Finished."


# Clean up
_reset_network
if [ "${NETWORK_MANAGER}" = "1" ]; then
	__log "log" ""
	$SUDO_FUNC /etc/init.d/network-manager start; 
fi

_log "info" "${ME} - Exit"

exit 0

