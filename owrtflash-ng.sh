#!/bin/sh
set -x

# unix shell script find out which directory the script file resides?
# https://stackoverflow.com/a/1638397
__basename="$( basename "${0}" )"
__basedir="$( dirname "$( readlink -f "${0}" )" )"

_set_ME() {
	ME="${__basename}"
}

_set_VER() {
	VER="2.1.0"
}


#############################
## GENERAL HELPER FUNCTION ##
#############################

_date() {
	echo -n "$( date "+%F %T")"
}

# normal log function
_log() {
	# ${1}	: type [log|info|error]
	# ${2}	: message
	echo "$( _date ) [${1}] ${2}"
}

# log function without line break
__log() {
	# ${1}	: type [log|info|error]
	# ${2}	: message
	echo -n "$( _date ) [${1}] ${2}"
}

_set_sudo_func() {
	if [ -n ${SUDO_FUNC} ]
	then
		_log "info" "${ME} - Check for \`sudo\`"
		${SUDO_FUNC} true || _log "error" "\`sudo\` not available."
	fi
}

_check_requirements() {
	CMDS="arp
arping
cat
curl
grep
ip
ping
pgrep
ssh
sshpass
telnet"

	for cmd in ${CMDS}
	do
		if [ -z "$( ${SUDO_FUNC} -i which ${cmd} )" ]
		then
			_log "error" "'${cmd}' is not installed or available."
		fi
	done
}
#######


##############################
## NETWORK HELPER FUNCTIONS ##
##############################

_reset_network() {
	_log "info" "Reset network"
	${SUDO_FUNC} ip neighbour flush dev eth0         >/dev/null 2>/dev/null
	${SUDO_FUNC} ip route flush table main dev eth0  >/dev/null 2>/dev/null
	${SUDO_FUNC} ip addr flush dev eth0              >/dev/null 2>/dev/null
}
#######

_set_client_ip() {
	_log "info" "*** ${node}: Setting client IP to ${client_ip}"
	${SUDO_FUNC} ip link set eth0 up                   >/dev/null 2>/dev/null
	${SUDO_FUNC} ip addr add ${client_ip}/24 dev eth0  >/dev/null 2>/dev/null
	# TODO: Specify subnet, we may not allways want /24
}
#######

_set_router_arp_entry() {
	_log "info" "*** ${node}: Setting arp table entry for '${router_ip}' on '${macaddr}'"
#	${SUDO_FUNC} arp -s ${router_ip} ${macaddr}         >/dev/null 2>/dev/null
	${SUDO_FUNC} ip neighbor add ${router_ip} lladdr ${macaddr} dev eth0 \
		>/dev/null 2>/dev/null
}
#######

_reset_router_arp_entry() {
	_log "info" "*** ${node}: Deleting arp table entry for '${router_ip}' on '${macaddr}'"
#	${SUDO_FUNC} arp -d ${router_ip}
	${SUDO_FUNC} ip neighbor del ${router_ip} dev eth0 \
		>/dev/null 2>/dev/null
}
#######

_ping_router() {

	_set_state
	_reset_network
	_set_client_ip
	_set_router_arp_entry

	_log "info" "${node}: Testing network connection to ${router_ip} via arping"
	arping \
		-q \
		-c 1 \
		${router_ip}
}
#######


###################################
## SET DEFAULTS HELPER FUNCTIONS ##
###################################

_get_state() {
	:
	# TODO
	# Using nmap to decide node is in factory or openwrt mode
	# Can not get model version exactly so far...

#	LEASE_FILE="/var/lib/dhcp/dhclient.leases"
#
#	$SUDO_FUNC rm -f "${LEASE_FILE}"
#
#	$SUDO_FUNC dhclient -v eth0
#
#	router_ip=$( grep 'option routers' "${LEASE_FILE}" | awk '{print $3}' | sed 's/;//' )
#	client_ip=$( grep 'fixed-address' "${LEASE_FILE}" | awk '{print $2}' | sed 's/;//' )
#
#	nmap -A -T5 -n --open -p1-1024 -sV -oG - "${router_ip}"
#
#	false
}
#######

########################################################################
_set_generic_defaults() {
	. "${__basedir}/defaults/generic"
}

_set_model_defaults() {
	. "${__basedir}/defaults/models/${model}"
}
########################################################################
_set_state() {
	_set_generic_defaults
	_set_model_defaults

	_set_${state}_defaults
}
########################################################################
# _set_state
_set_state_defaults() {
	_set_${state}_defaults
}

_set_factory_defaults() {
	if [ -f "${__basedir}/defaults/factory/${model}" ]
	then
		_log "info" "${node}: Load factory defaults for '${model}'."
		. "${__basedir}/defaults/factory/${model}"
	else
		_log "error" "${node}: No factory defaults for '${model}' found."
	fi
}

_set_openwrt_defaults() {
	. "${__basedir}/defaults/openwrt"
}

_set_custom_defaults() {
	_set_node_config
}

_set_node_config() {
	. "${NODES_DIR}/${node_file}"
}
########################################################################

########################################################################
# TODO
_get_openwrt_firmware_file_name() {
	:
	# TODO
#	curl \
#		--insecure \
#		--silent \
#		"https://downloads.openwrt.org/${OPENWRT_RELEASE_NAME}/${OPENWRT_RELEASE_DATE}/${chipset}/generic/md5sums" \
#	| grep -E "${model}.*factory" | awk '{ print $2 }'
}

_get_openwrt_firmware_file_md5sum() {
	:
	# TODO
#	curl \
#		--insecure \
#		--silent \
#		"https://downloads.openwrt.org/${OPENWRT_RELEASE_NAME}/${OPENWRT_RELEASE_DATE}/${chipset}/generic/md5sums" \
#	| grep -E "${model}.*factory" | awk '{ print $1 }'
}

_download_openwrt() {
	:
	# TODO
#	firmware_file_name="$( _get_openwrt_firmware_file_name )"
#	# Cleanup file name
#	# Removes "*" from var
#	firmware_file_name="${firmware_file_name#"*"}"
#
#	if [ ! -e "${FIRMWARE_DIR}/${firmware_file_name}" ];
#	then
#		firmware_file_url="https://downloads.openwrt.org/${OPENWRT_RELEASE_NAME}/${OPENWRT_RELEASE_DATE}/${chipset}/generic/${firmware_file_name}"
#		curl \
#			--insecure \
#			--silent \
#			--output "${FIRMWARE_DIR}/${firmware_file_name}" \
#			"${firmware_file_url}"
#	fi
#	firmware="${{FIRMWARE_DIR}/${firmware_file_name}"
}
########################################################################

#########################
_set_firmware_image() {
	case ${OPT_FROM} in
		factory)
			case ${OPT_TO} in
				factory) firmware="firmware-images/factory/${model}/*/factory.bin" ;;
				openwrt) firmware="firmware-images/openwrt/${model}-factory.bin" ;;
				custom)  . "${NODES_DIR}/${node_file}" ;;
			esac
		;;
		openwrt|custom)
			case ${OPT_TO} in
				factory) firmware="firmware-images/factory/${model}/*/factory.bin.stripped" ;;
				openwrt) firmware="firmware-images/openwrt/${model}-sysupgrade.bin" ;;
				custom)  . "${NODES_DIR}/${node_file}" ;;
			esac
		;;
	esac
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

_exec_telnet() {
	# TODO
	:
}

SSH_OPTS="\
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
"

_scp () {
	# $1 : local-file
	# $2 : remote-path
	sshpass -p "${password}" \
		scp \
			${SSH_OPTS} \
			"${1}" \
			${user}@${router_ip}:"${2}"
}

_ssh_exec() {
	# Usage:
	#	_exec_ssh "reboot && exit"
	sshpass -p "${password}" \
		ssh \
			${SSH_OPTS} \
			${user}@${router_ip} \
			$@
}

_install_nohup_script() {
	_scp \
		"${__basedir}/helper_functions/nohup.sh" \
		"/tmp/nohup.sh"
}

###########
## FLASH ##
###########
_flash() {
	_set_generic_defaults
	_set_model_defaults
	_set_firmware_image

	_log "log" "*** ${node}: Start flashing with '${firmware}'..."
	_flash_over_${state}
}
##########################
## _flash_over_${state} ##
##########################
_flash_over_factory() {
	_set_factory_defaults
	# Overloads and exec `_flash_over_factory`
	. "${__basedir}/flash-over-factory/${model}.sh"

	_flash_over_factory_via_http
}

_flash_over_openwrt() {
	_set_openwrt_defaults
	_flash_over_openwrt_via_${protocol} \
		|| _log "error" "Config: protocol=${protocol} unknown."

}

_flash_over_custom() {
	_set_custom_defaults
	_flash_over_custom_via_${protocol}
}

_flash_over_openwrt_via_telnet() {
	:
#	TODO

# Open socket on localhost
#	nc -l 1234 < ${firmware}

# Execute `expect` script, to execute commands on the remote router
	# Use seperate `expect` script
	#
	#!/usr/bin/expect
	#
	#spawn telnet 192.168.1.1
	#expect "'^]'." sleep .1;
	#send "\r";
	#expect "#"
	#
	##send "echo 'hello'\r"
	#send "nc ${client_ip} 1234 > /tmp/fw\r"
	#expect "#"
	#
	## TODO: nohup...
	#send "sysupgrade -n /tmp/fw\r"
	#expect "#"
	#
	##send "exit\r"
	##expect eof

#	${__basedir}/helper_functions/flash-over-openwrt-via-telnet.exp
}

_flash_over_openwrt_via_ssh() {
	# TODO - what to improve?

	# copy firmware to router
	_scp "${firmware}" /tmp/fw

	# install 'nohup's version for poor men on router
	_install_nohup_script

	# start `sysupgrade` with our nohup version
	_ssh_exec "sh /tmp/nohup.sh sysupgrade -n /tmp/fw && exit"
}

_flash_over_custom_via_telnet() {
	_flash_over_openwrt_via_telnet
}
_flash_over_custom_via_ssh() {
	_flash_over_openwrt_via_ssh
}

#######

_usage() {
	cat <<__END_OF_USAGE
${ME} v${VER}

Usage: $ME OPTIONS

    --nodes NODES    comma seperated list of node-names,
                     or a directory containing all node-files
    --from STATE     factory | openwrt | custom
    --to STATE       factory | openwrt | custom
    --verbose        be verbose (not implemented)

    --sudo           use sudo (if not running as root)
    --nm             disable network-manager while running the script

    --help           display usage information and exit
    --version        display version information and exit

    --ping-test      just ping all nodes, do not flash or configure

__END_OF_USAGE
}
#######
_parse_args() {

	if [ ${#} -eq 0 ]
	then
		_log "error" "No arguemnts given."
		_usage
		exit 1
	fi

	VERBOSITY_LEVEL=0
	while [ -n "${1}" ]
	do
		case "${1}" in
			-h|--help)
				_usage && exit 0
			;;

			-V|--version)
				_version && exit 0
			;;

			-n|--nodes)
				shift
				if [ -z "${1}" ]
				then
					_log "error" "\`--nodes\` requires an argument."
					exit 2
				else
					# If it is not a directory,
					#   it is a comma seperated list of nodes
					if [ ! -d "${1}" ]
					then
						# Translate list to shell list
						OPT_NODES="$( echo ${1} | sed 's/,/ /g' )"
					else
						case ${1} in
							# To get something like '/path/*'
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

			--from)
				shift
				case ${1} in
					factory) : ;;
					openwrt) : ;;
					custom)  : ;;
					*)
						_log "error" "--from: Unknown state '${1}'"
						exit 2
					;;
				esac
				state="${1}"
				OPT_FROM="${state}"
			;;

			--to)
				# TODO
				shift
				case ${1} in
					factory) : ;;
					openwrt) : ;;
					custom)  : ;;
					*)
						_log "error" "--to: Unknown state '${1}'"
						exit 2
					;;
				esac
				OPT_TO="${1}"
			;;

			-s|--sudo)
				SUDO_FUNC="sudo"
				_set_sudo_func
			;;

			--nm|--network-manager)
				NETWORK_MANAGER=1
			;;

			-v|--verbosity)
				shift
				if [ ${1} -lt 0 ]
				then
					exit
				else
					VERBOSITY_LEVEL=${1}
				fi
			;;


		#	--download-openwrt)
		#		# TODO
		#		for __model in $( ls "${__basedir}/defaults/factory" );
		#		do
		#			:
		#		done
		#	;;

			--ping-test)
				OPT_PING_TEST=1
			;;

			*)
				_log "error" "Unexpected argument '${1}'"
			;;
		esac # case $1 in
		shift
	done # while [ -n $1 ]
}
#######

_loop_over_nodes() {
	for node_file in ${OPT_NODES}
	do
		node="${node_file}"
		_log "log" "### Next device in list: '${node}' ###"

		_ping_router
		if [ ${?} -eq 0 ]
		then
			_log "info" "*** ${node}: Network status: OK"
			_flash
		else
			_log "error" "*** ${node}: Network status: FAILED (Not responsing.)"
			_log "log" "*** ${node}: Flashing skipped."
		fi

	done

	_reset_network
	_log "log" "### Loop over nodes finished. ###"
}

##########
## MAIN ##
##########

_main()
{
	_set_ME
	_set_VER

	_check_requirements
	_parse_args ${*}

	{
	# Which nodes to flash/config
	# If nodes are _NOT_ given or specified, use all node files in NODES_DIR
	if [ -z "${OPT_NODES}" ]
	then
		OPT_NODES="$( ls "${NODES_DIR}" )"
	fi

	for node_file in ${OPT_NODES}
	do
		node="${node_file}"

		if [ ! -f "${NODES_DIR}/${node_file}" ]
		then
			_log "error" "Node file '${node_file}' not found."
			EXIT=1
		fi
	done

	if [ ${EXIT} ]
	then
		exit 2
	fi

	unset node
	unset node_file
	}
###########
	if [ ${NETWORK_MANAGER} ]; then
		__log "log" "${ME} - "
		${SUDO_FUNC} service network-manager stop
	fi
###########

	_loop_over_nodes

###########
	if [ ${NETWORK_MANAGER} ]; then
		__log "log" ""
		${SUDO_FUNC} service network-manager start
	fi
} # main


# DEFAULT SETTINGS
FIRMWARE_DIR="${__basedir}/firmware-images"
NODES_DIR="${__basedir}/nodes"

_main ${*}
_log "info" "${ME} - Exit"
exit 0


#
# TODO
# Feature request
#	tftp-server for model tl-wr841n-v9, tl-wdr4300v1
#		use dnsmasq and static ip configuration
#


# WORKING ON
## 2.1.0
# * New state
#	- openwrt-custom / openwrt-customized


# Just for the record
# "normal" nohup usage, which is sadly not available :-(
# * Redirecting stdout, stderr, and stdin, and running in the backgroud
# 	 `nohup sysupgrade -n /tmp/fw \
#		> /dev/null 2> /dev/null < /dev/null &`
#
########################################################################
# NOTES
## Usecases
# * setup node files with at least 'model' and 'macaddr'
# * `_flash_over_factory_with_openwrt`
# * `_flash_over_openwrt_with_factory`
