#!/bin/sh
#  DEBUG MODE ON
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
	SUDO_FUNC="sudo"  # aka ALLWAYS ON
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
			ERROR=1
		fi
	done
	if [ ${ERROR} ]
	then
		log "error" "Check requirements failed. EXIT."
		exit 2
	else
		log "info" "Check requirements passed."
	fi
}
########################################################################

##############################
## NETWORK HELPER FUNCTIONS ##
##############################
_reset_network() {
	_log "info" "Reset network"
	${SUDO_FUNC} ip neighbour flush dev eth0         >/dev/null 2>/dev/null
	${SUDO_FUNC} ip route flush table main dev eth0  >/dev/null 2>/dev/null
	${SUDO_FUNC} ip addr flush dev eth0              >/dev/null 2>/dev/null
}
#####################
_set_client_ip() {
	_log "info" "*** ${node}: Setting client IP to ${client_ip}"
	${SUDO_FUNC} ip link set eth0 up                   >/dev/null 2>/dev/null
	${SUDO_FUNC} ip addr add ${client_ip}/24 dev eth0  >/dev/null 2>/dev/null
	# TODO: Specify subnet, we may not allways want /24
}
############################
_set_router_arp_entry() {
	_log "info" "*** ${node}: Setting arp table entry for '${router_ip}' on '${macaddr}'"
#	${SUDO_FUNC} arp -s ${router_ip} ${macaddr}         >/dev/null 2>/dev/null
	${SUDO_FUNC} ip neighbor add ${router_ip} lladdr ${macaddr} dev eth0 \
		>/dev/null 2>/dev/null
}
##############################
_reset_router_arp_entry() {
	_log "info" "*** ${node}: Deleting arp table entry for '${router_ip}' on '${macaddr}'"
#	${SUDO_FUNC} arp -d ${router_ip}
	${SUDO_FUNC} ip neighbor del ${router_ip} dev eth0 \
		>/dev/null 2>/dev/null
}
###################
_ping_router() {

	_set_state
	_reset_network
	_set_client_ip
	_set_router_arp_entry

	_log "info" "${node}: Testing network connection to ${router_ip} via arping"
	${SUDO_FUNC} arping \
		-q \
		-c 1 \
		${router_ip}
}
#########################################################################

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
##########################
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
	. "${node_file}"
}

##########################
_set_firmware_image() {
	case ${OPT_FROM} in
		factory)
			case ${OPT_TO} in
				factory) firmware="${FIRMWARE_DIR}/factory/${model}/*/factory.bin"  ;;
				openwrt) firmware="${FIRMWARE_DIR}s/openwrt/${model}-factory.bin"   ;;
				custom)  . "${NODES_DIR}/${node_file}"                              ;;
			esac
		;;
		openwrt|custom)
			case ${OPT_TO} in
				factory) firmware="${FIRMWARE_DIR}/factory/${model}/*/factory.bin.stripped"  ;;
				openwrt) firmware="${FIRMWARE_DIR}/openwrt/${model}-sysupgrade.bin"          ;;
				custom)  . "${NODES_DIR}/${node_file}"                                       ;;
			esac
		;;
	esac
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

###################
## MAIN FUNCTION ##
###################
_telnet() {
	# TODO
	:
}

_copy_file_via_telnet() {
	# TODO
	:
}
########################################################################
## SSH ##
#########
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

_ssh() {
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
########################################################################
## FLASHING ##
##############
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
	## Overloads and exec `_flash_over_factory`
	# Load `_flash_over_factory_via_http`
	. "${__basedir}/flash-over-factory/${model}.sh"
	_flash_over_factory_via_http
}

_flash_over_openwrt() {
	_set_openwrt_defaults
	_flash_over_openwrt_via_${protocol} #\
		#|| _log "error" "in \`_flash_over_openwrt_via_${protocol}\`"
}

_flash_over_custom() {
	_set_custom_defaults
	_flash_over_custom_via_${protocol}
}
########################################################################
_flash_over_openwrt_via_telnet() {
	:
#	TODO

	# Install nohup.sh via telnet
#	_copy_file_via_telnet

	# Open socket on localhost
#	nc -l 1233 < ${__basedir}/helper_functions/nohup.sh &
#	nc -l 1234 < ${firmware} &

	# Start telnet session
#	${__basedir}/helper_functions/flash_over_openwrt_via_telnet.exp ${router_ip} ${client_ip}

	# TODO
	# just enable ssh
	# ${__basedir}/helper_functions/set_passwd_via_telnet.exp ${password}
	# copy files via ssh
	# _scp .. ..
	# executre sysuptrade via ssh
	# _ssh "..."
	_flash_over_openwrt_via_ssh
}

_flash_over_openwrt_via_ssh() {
	# TODO - what to improve?

	# _set_password_via_telnet()
	{
		"${__basedir}/helper_functions/set_passwd_via_telnet.exp" \
			${router_ip} \
			admin
	}
	sleep 2 # give dropbear time to restart

	# install 'nohup's version for poor men on router
	_install_nohup_script

	# copy firmware to router
	_scp "${firmware}" /tmp/fw

	# start `sysupgrade` with our nohup version
	#_ssh "sh /tmp/nohup.sh sysupgrade -n /tmp/fw && exit"
	_ssh "sh /tmp/nohup.sh sysupgrade -n /tmp/fw \
		> /dev/null \
		2> /dev/null \
		< /dev/null \
		&"
}

_flash_over_custom_via_telnet() {
	_flash_over_openwrt_via_telnet
}
_flash_over_custom_via_ssh() {
	_flash_over_openwrt_via_ssh
}
########################################################################
_version() {
	cat <<__END_OF_VERSION
${ME} v${VER}

__END_OF_VERSION
}

_usage() {
	_version
	cat <<__END_OF_USAGE
Usage: $ME OPTIONS

    --nodes node1,node2,.. |    comma seperated list of node-names,
            /path/to/node/dir   or a directory containing all node-files
    --from STATE                factory | openwrt | custom
    --to   STATE                factory | openwrt | custom
    --verbose INT               set verbosity (not implemented)

    --sudo                      use sudo (if not running as root)
    --nm                        disable network-manager while running the script

    --help                      display usage information and exit
    --version                   display version information and exit

    --ping-test                 just ping all nodes, do not flash or configure

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
	while [ -n ${1} ]
	do
		case ${1} in
			-h|--help)
				_usage && exit 0
			;;

			-V|--version)
				_version && exit 0
			;;

			# OPT_NODES
			-n|--nodes)
				shift
				if [ -z "${1}" ]
				then
					_log "error" "\`--nodes\` requires an argument. EXIT."
					exit 2
				else
					# If it is not a directory,
					#   it is a comma seperated list of nodes
					if [ -d "${1}" ]
					then
						case ${1} in
							# To get something like '/path/*'
							*/)
								OPT_NODES="${1}*"
							;;
							*)
								OPT_NODES="${1}/*"
							;;
						esac
					else
						# Translate list to shell list
						OPT_NODES="$( echo ${1} | sed 's/,/ /g' )"
					fi
				fi
			;;

			# OPT_FROM
			--from)
				shift
				case ${1} in
					factory) : ;;
					openwrt) : ;;
					custom)  : ;;
					*)
						_log "error" "\`--from\`: Unknown state '${1}'. EXIT."
						exit 2
					;;
				esac
				OPT_FROM="${1}"
				state="${OPT_FROM}"
			;;

			# OPT_TO
			--to)
				# TODO
				shift
				case ${1} in
					factory) : ;;
					openwrt) : ;;
					custom)  : ;;
					*)
						_log "error" "\`--to\`: Unknown state '${1}'. EXIT."
						exit 2
					;;
				esac
				OPT_TO="${1}"
			;;

			-s|--sudo)
				_set_sudo_func
			;;

			--nm|--network-manager)
				# manage `network-manger` during run-time
				NETWORK_MANAGER=1
			;;

			-v|--verbosity)
				shift
				if [ ${1} -lt 0 ]
				then
					_log "error" "\`--verbosity\`: Valua must be >= 0. EXIT."
					exit 2
				else
					VERBOSITY_LEVEL=${1}
				fi
			;;

			--ping-test)
				# TODO
				# Needs implementation again.
				OPT_PING_TEST=1
			;;

			*)
				_log "error" "Unexpected argument '${1}'"
				exit 1
			;;
		esac # case $1 in

		# Remaining arguments
		{
		if [ ${#} -eq 1 ]
		then
			break
		else
			shift
		fi
		}
	done # while [ -n $1 ]
}

########################################################################
_loop_over_nodes() {
	for node_file in ${OPT_NODES}
	do
		node="${node_file}"
		node_file="${NODES_DIR}/${node_file}"
		_log "log" "### Next device in list: '${node}' ###"

		_set_node_config

		_ping_router
		if [ ${?} -eq 0 ]
		then
			_log "info" "*** ${node}: Network status: OK"

			_flash

		else
			_log "error" "*** ${node}: Network status: FAILED (Not responsing)"
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

	_set_sudo_func
	_check_requirements
	_parse_args ${*}

########################################################################
	# Which nodes to flash/config
	# If nodes are _NOT_ given or specified, use all node files in NODES_DIR
	if [ -z "${OPT_NODES}" ]
	then
		OPT_NODES="$( ls "${NODES_DIR}" )"
	fi

	for node in ${OPT_NODES}
	do
		node_file="${NODES_DIR}/${node}"

		if [ ! -f "${node_file}" ]
		then
			_log "error" "Node file '${node_file}' not found."
			EXIT=1
		fi
	done

	if [ ${EXIT} ]
	then
		_log "log" "EXIT."
		exit 2
	fi

	unset node_file
########################################################################
	if [ ${NETWORK_MANAGER} ]; then
		__log "log" "${ME} - "
		${SUDO_FUNC} service network-manager stop
	fi
########################################################################

	_loop_over_nodes

########################################################################
	if [ ${NETWORK_MANAGER} ]; then
		__log "log" ""
		${SUDO_FUNC} service network-manager start
	fi
}
########################################################################
## DEFAULT SETTINGS ##
######################
FIRMWARE_DIR="${__basedir}/firmware-images"
NODES_DIR="${__basedir}/nodes"

_main ${*}
_log "info" "${ME} - Exit"
exit 0
########################################################################
########################################################################
########################################################################
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
## EXAMPLE USAGE
# ./owrtconfig-ng.sh
