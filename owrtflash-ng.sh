#!/bin/sh
#set -x

# unix shell script find out which directory the script file resides?
# https://stackoverflow.com/a/1638397
__basename="$( basename "${0}" )"
__basedir="$( dirname "$( readlink -f "${0}" )" )"

_set_ME()
{
	ME="${__basename}"
}

_set_VER()
{
	VER="2.1.0"
}

#############################
## GENERAL HELPER FUNCTION ##
#############################
_date()
{
	echo -n "$( date "+%F %T" )"
}

# normal log function
_log()
{
	# ${1}	: type [log|info|error]
	# ${2}	: message

	case ${1} in
		log) echo "$( _date ) [${1}]   ${2}" ;;
		info) echo "$( _date ) [${1}]  ${2}" ;;
		error) echo "$( _date ) [${1}] ${2}" ;;
	esac

#	echo "$( _date ) [${1}] ${2}"
}

# log function without line break
__log()
{
	# ${1}	: type [log|info|error]
	# ${2}	: message
	echo -n "$( _date ) [${1}] ${2}"
}

_set_sudo_func()
{
	SUDO_FUNC="sudo"  # aka ALLWAYS ON
	if [ -n ${SUDO_FUNC} ]
	then
		_log "info" "Checking for \`sudo\`"
		${SUDO_FUNC} true || _log "error" "\`sudo\` not available."
	fi
}

_check_requirements()
{
	CMDS="arping
curl
ip
ping
pgrep
ssh
sshpass
telnet
cat
grep
sed
awk
sudo
nohup
terminator
journalctl"

	for cmd in ${CMDS}
	do
		if [ -z "$( ${SUDO_FUNC} -i which ${cmd} )" ]
		then
			_log "error" "\`${cmd}\` is not installed or available."
			ERROR=1
		fi
	done
	if [ ${ERROR} ]
	then
		_log "error" "Checking requirements failed. Abort."
		exit 2
	else
		_log "info" "Checking requirements passed."
	fi
}
########################################################################

##############################
## NETWORK HELPER FUNCTIONS ##
##############################
_reset_network()
{
	_log "info" "Resetting network"
	${SUDO_FUNC} ip neighbour flush dev ${INTERFACE}         >/dev/null 2>/dev/null
	${SUDO_FUNC} ip route flush table main dev ${INTERFACE}  >/dev/null 2>/dev/null
	${SUDO_FUNC} ip addr flush dev ${INTERFACE}              >/dev/null 2>/dev/null
}
#####################
_set_client_ip()
{
	_log "info" "*** ${node}: Setting client IP to ${client_ip}."
	${SUDO_FUNC} ip link set ${INTERFACE} up                   >/dev/null 2>/dev/null
	${SUDO_FUNC} ip addr add ${client_ip}/24 dev ${INTERFACE}  >/dev/null 2>/dev/null
	# TODO: Specify subnet, we may not allways want /24
}
############################
_set_router_arp_entry()
{
	_log "info" "*** ${node}: Setting arp table entry for ${router_ip} to ${macaddr}."
#	${SUDO_FUNC} arp -s ${router_ip} ${macaddr}         >/dev/null 2>/dev/null
	${SUDO_FUNC} ip neighbor add ${router_ip} lladdr ${macaddr} dev ${INTERFACE} \
		>/dev/null 2>/dev/null
}
##############################
_reset_router_arp_entry()
{
	_log "info" "*** ${node}: Deleting arp table entry for ${router_ip} to ${macaddr}."
#	${SUDO_FUNC} arp -d ${router_ip}
	${SUDO_FUNC} ip neighbor del ${router_ip} dev ${INTERFACE} \
		>/dev/null 2>/dev/null
}
###################
_ping_router()
{

	_set_state
	_reset_network
	_set_client_ip
	_set_router_arp_entry

	_log "info" "*** ${node}: Testing network connection to ${router_ip} via arping."
	${SUDO_FUNC} arping \
		-q \
		-c 1 \
		-I ${INTERFACE} \
		${router_ip}
}
#########################################################################

###################################
## SET DEFAULTS HELPER FUNCTIONS ##
###################################

_get_state()
{
	:
	# TODO
	# Using nmap to decide node is in factory or lede mode
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
_set_generic_defaults()
{
	_log "info" "*** ${node}: Load generic defaults."
	. "${__basedir}/defaults/generic"
}
##########################
_set_model_defaults()
{
	_log "info" "*** ${node}: Load hardware defaults for '${model}'."
	. "${__basedir}/defaults/models/${model}"
}
########################################################################
_set_state()
{
	_set_generic_defaults
	_set_model_defaults

	_set_${state}_defaults
}
########################################################################
_set_factory_defaults()
{
	if [ -f "${__basedir}/defaults/factory/${model}" ]
	then
		_log "info" "*** ${node}: Load factory defaults for '${model}'."
		. "${__basedir}/defaults/factory/${model}"
	else
		_log "error" "*** ${node}: No factory defaults for '${model}' found."
	fi
}

_set_lede_defaults()
{
	_log "info" "*** ${node}: Load LEDE defaults."
	. "${__basedir}/defaults/lede"
}

_set_custom_defaults()
{
	_set_node_config
}

_set_failsafe_defaults()
{
	if [ -f "${__basedir}/defaults/failsafe/${model}" ]
	then
		_log "info" "*** ${node}: Load failsafe defaults for '${model}'."
		. "${__basedir}/defaults/failsafe/${model}"
	else
		_log "error" "*** ${node}: No failsafe defaults for '${model}' found."
	fi
}


_set_node_config()
{
	_log "info" "*** ${node}: Load node config file."
	. "${node_file}"
}

##########################
_set_firmware_image()
{
	case ${OPT_FROM} in
		factory)
			case ${OPT_TO} in
				factory)  firmware="${FIRMWARE_DIR}"/factory/${model}.bin             ;;
				lede)  firmware="${FIRMWARE_DIR}"/lede/${model}-factory.bin     ;;
				custom)   . "${node_file}"                                            ;;
			esac
		;;
		lede|custom)
			case ${OPT_TO} in
				factory) firmware="${FIRMWARE_DIR}"/factory/${model}.bin.stripped     ;;
				lede) firmware="${FIRMWARE_DIR}"/lede/${model}-sysupgrade.bin   ;;
				custom)  . "${node_file}"                                             ;;
			esac
		;;
		failsafe)        . "${__basedir}/defaults/failsafe/${model}"                  ;;
	esac

	_test_firmware
}
########################################################################
########################################################################
# TODO
_get_lede_firmware_file_name()
{
	:
	# TODO
#	curl \
#		--insecure \
#		--silent \
#		"https://downloads.openwrt.org/${OPENWRT_RELEASE_NAME}/${OPENWRT_RELEASE_DATE}/${chipset}/generic/md5sums" \
#	| grep -E "${model}.*factory" | awk '{ print $2 }'
}

_get_lede_firmware_file_md5sum()
{
	:
	# TODO
#	curl \
#		--insecure \
#		--silent \
#		"https://downloads.openwrt.org/${OPENWRT_RELEASE_NAME}/${OPENWRT_RELEASE_DATE}/${chipset}/generic/md5sums" \
#	| grep -E "${model}.*factory" | awk '{ print $1 }'
}

_download_lede()
{
	:
	# TODO
#	firmware_file_name="$( _get_lede_firmware_file_name )"
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
_telnet()
{
	# TODO
	:
}

_copy_file_via_telnet()
{
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

_scp ()
{
	# $1 : local-file
	# $2 : remote-path
	_log "info" "*** ${node}: Copying \"${1}\" to \"${2}\"..."
	sshpass -p "${password}" \
		scp \
			${SSH_OPTS} \
			"${1}" \
			${user}@${router_ip}:"${2}" \
				>/dev/null 2>/dev/null \
	||	_log "error" "*** ${node}: Copying \"${1}\" to \"${2}\" failed."
}

_ssh()
{
	# Usage:
	#	_ssh "reboot && exit"
	sshpass -p "${password}" \
		ssh \
			${SSH_OPTS} \
			${user}@${router_ip} \
			$@ #\
				#2 >&1
				#>/dev/null 2>/dev/null
}

_install_nohup()
{
	_scp \
		"${__basedir}/helper_functions/nohup.sh" \
		"/tmp/nohup.sh"
}
########################################################################
## FLASHING ##
##############

_test_ssh()
{
	for i in $(seq 1 5)
	do
		sleep 5 # give dropbear time to restart
		_log "info" "*** ${node}: Checking \`ssh\` remote shell login (Try ${i}/${STOP})."
		_ssh "exit" \
			2>/dev/null
		if [ ${?} -eq 0 ]
		then
			_log "log" "*** ${node}: Checking \`ssh\` passed."
			break
		else
			if [ ${i} -eq 5 ]
			then
				SSH_ERROR=1
				_log "error" "*** ${node}: Skipping node. (\`ssh\` is NOT available.)"
			fi
		fi
	done
}

_test_firmware()
{
	if [ ! -e "${firmware}" ]
	then
		_log "error" "Firmware '${firmware}' not found!"
		exit 3
	fi
}

_set_password_via_telnet()
{
	_log "log" "*** ${node}: Setting password via \`telnet\`."
	"${__basedir}/helper_functions/set_passwd_via_telnet.exp" \
		${router_ip} \
		${password} \
			>/dev/null 2>/dev/null \
	||	_log "error" "*** ${node}: \`_set_password_via_telnet\` failed."

	_test_ssh
}

_flash()
{
	_set_generic_defaults
	_set_model_defaults
	_set_firmware_image

	_flash_over_${state}
}
##########################
## _flash_over_${state} ##
##########################
_flash_over_factory()
{
	_log "log" "*** ${node}: Trying to flash with '${firmware}'..."

	_set_factory_defaults

	# Overload and exec `_flash_over_factory_via_http`
	. "${__basedir}/flash-over-factory/${model}.sh"
	_flash_over_factory_via_http
}

_flash_over_lede()
{
	_set_lede_defaults
	case ${OPT_FROM} in
		lede) : ;;
		custom)  . "${node_file}" ;;
	esac
	_flash_over_lede_via_${protocol}
}

_flash_over_custom()
{
	_flash_over_lede
}

_flash_over_failsafe()
{
	model="${OPT_MODEL}"
	_log "info" "${state}: Flash via TFTP for \"${model}\""
	_set_generic_defaults
	_set_model_defaults
	_set_failsafe_defaults
	_set_firmware_image

	_reset_network
	_set_client_ip

	TFTP_DIR="/srv/tftp"
	_log "info" "${state}: Copying '${firmware}' to '${TFTP_DIR}/'"
	{
		${SUDO_FUNC} \
		cp "${firmware}" "${TFTP_DIR}/"
	}

	# TODO: Make it more generic
	_log "info" "${state}: Starting monitor log..."
	{
		nohup \
			${SUDO_FUNC} \
			terminator \
				--geometry=900x200-0-0 \
				--execute \
					"${__basedir}"/helper_functions/read_syslog.sh \
		>/dev/null \
		2>&1 \
		&
	}
	# journalctl --no-pager --follow since="$( date "+%F %T" )" /usr/sbin/in.tftpd \
	# Dafuq: List log for executable does not work
	# Cheating with grep...


	_log "log" "${state}: Starting TFTPd..."
	{
		${SUDO_FUNC} \
		/usr/sbin/in.tftpd \
			--listen \
			--user tftp \
			--address 0.0.0.0:69 \
			--secure \
			-v -v -v \
			"${TFTP_DIR}"
	}
	_TFTP_PID=${!}

	_log "info" "${state}: Press \"q\" to exit \`_flash_over_failsafe\`..."
	{
		# Magic
		test -t 0 \
			&& stty -echo -icanon -icrnl time 0 min 0

		keypress=
		while [ "${keypress}" != "q" ]
		do
			keypress="$( dd bs=1 count=1 status=none | cat -v  )"
		done

		# Reset magic
		test -t 0 \
			&& stty sane

		${SUDO_FUNC} \
		killall /usr/sbin/in.tftpd \
			&& _log "log" "${state}: TFTPd stopped." \
			|| _log "error" "${state}:"
	}

	_log "info" "${state}: Cleanup '${TFTP_DIR}/'"
	{
		${SUDO_FUNC} \
		rm "${TFTP_DIR}/$( basename ${firmware} )"
	}

	_reset_network

	_log "log" "${state}: Exiting \`_flash_over_failsafe\`."
	_log "log" "Exit."
	exit 0

	# NOTES
	# apt-get install tftpd-hpa
	# systemctl disable tftpd-hpa
	# /etc/default/tftpd-hpa
}

##########################################
## _flash_over_${state}_via_${protocol} ##
##########################################
_flash_over_factory_via_http()
{
	# Dummy function
	:
}

_flash_over_lede_via_telnet()
{
	# TODO
	# Install nohup.sh via telnet
	# _copy_file_via_telnet

	# Open socket on localhost
#	nc -l 1233 < ${__basedir}/helper_functions/nohup.sh &
#	nc -l 1234 < ${firmware} &

	# Start telnet session
#	${__basedir}/helper_functions/flash_over_lede_via_telnet.exp ${router_ip} ${client_ip}
	# FIXME
	# For a reason the expect script does not work properly and fails on
	# the nohup call for sysupgrade... to sad I have to go the other way
	# around.

	###########################
	####### Workaround ########
	###########################
	_set_password_via_telnet
	_flash_over_lede_via_ssh
	############################
}

_flash_over_lede_via_ssh()
{
	_log "log" "*** ${node}: Trying to flash with '${firmware}'..."

	_test_ssh
	if [ ! ${SSH_ERROR} ]
	then
		# install `nohup`s version of the poor on our router
		_install_nohup

		# copy firmware to router
		_scp ${firmware} /tmp/fw \

		# start `sysupgrade` with our nohup version
		{
		_ssh "sh /tmp/nohup.sh \
				sysupgrade -n /tmp/fw \
					> /dev/null \
					2> /dev/null \
					< /dev/null \
					&" \
						2> /dev/null
		} \
		&& _log "log" "*** ${node}: Starting \`sysupgrade\`..." \
		|| _log "error" "*** ${node}: Some error occured while flashing with \`sysupgrade\`."
	fi
	unset SSH_ERROR
}

_flash_over_custom_via_telnet()
{
	_flash_over_lede_via_telnet
}
_flash_over_custom_via_ssh()
{
	_flash_over_lede_via_ssh
}
########################################################################
_version()
{
	cat <<__END_OF_VERSION
${ME} v${VER}

__END_OF_VERSION
}

_usage()
{
	_version
	cat <<__END_OF_USAGE
Usage: $ME OPTIONS
Required:
    --nodes node1,node2,.. |    comma seperated list of node-names,
            /path/to/node/dir   or a directory containing all node-files
    --from STATE                factory | lede | custom
    --to   STATE                factory | lede | custom
    --interface                 network interface to use

Usefull:
    --sudo                      use sudo (if not running as root)
    --nm                        disable network-manager while running the script

Optional:
    --verbose INT               set verbosity (not implemented)

    --help                      display usage information and exit
    --version                   display version information and exit

    --ping-test                 just ping all nodes, do not flash or configure
                                (not implemented)

__END_OF_USAGE
}
#######
_parse_args()
{
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
					factory)  : ;;
					lede)  : ;;
					custom)   : ;;
					failsafe) FAILSAFE=1 ;;
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
					lede) : ;;
					custom)  : ;;
					*)
						_log "error" "\`--to\`: Unknown state '${1}'. EXIT."
						exit 2
					;;
				esac
				OPT_TO="${1}"
			;;

			# OPT_MODEL
			--model)
				shift
				if [ -z "${1}" ]
				then
					_log "error" "\`--model\` requires an argument. EXIT."
					exit 2
				else
					OPT_MODEL="${1}"
				fi
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
				if [ -z "${1}" ]
				then
					_log "error" "\`--verbosity\` requires an argument. EXIT."
					exit 2
				fi

				if [ ${1} -lt 0 ]
				then
					_log "error" "\`--verbosity\`: Value must be >= 0. EXIT."
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

			-I|--interface)
				shift
				if [ -z "${1}" ]
				then
					_log "error" "\`--interface\`: requires an network interface. EXIT."
					exit 2
				else
					INTERFACE="${1}"
				fi
			;;


			#Unknown Arguments
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
_loop_over_nodes()
{
	_log "log" "Loop over nodes '${OPT_NODES}'."
	for node in ${OPT_NODES}
	do
		_log "log" "Next device in list: '${node}'."

		node_file="${NODES_DIR}/${node}"
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
	_log "log" "Loop over nodes finished."
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

	# Special operation mode
	# Do not loop over nodes, just start tftp-server for ${model}
	# given as command line argument
	if [ ${FAILSAFE} ]
	then
		if [ ${OPT_MODEL} ]
		then
			_flash_over_failsafe
		else
			_log "error" "\`--model\` no specified. Abort."
			exit 2
		fi
	fi

	if [ ! ${OPT_FROM} ]
	then
		_log "error" "At least \`--from\` has to be specified!. Abort."
		exit 1
	fi

	if [ ${OPT_FROM} -a ! ${OPT_TO} ]
	then
		_log "error" "Not sure what to do. \`--to\` is missing. Abort."
		exit 1
	fi

########################################################################
	# Which nodes to flash/config
	# If nodes are _NOT_ given or specified, use all node files in NODES_DIR
	{
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
			ERROR=1
		fi
	done

	if [ ${ERROR} ]
	then
		_log "log" "Abort."
		exit 2
	fi

	unset node
	unset node_file
	}
########################################################################
	if [ ${NETWORK_MANAGER} ]; then
		__log "log" ""
		${SUDO_FUNC} service network-manager stop
	fi
########################################################################

	_loop_over_nodes

########################################################################
	if [ ${NETWORK_MANAGER} ]; then
		__log "log" ""
		${SUDO_FUNC} service network-manager start
	fi

	_log "info" "Exit"
	exit 0
}
########################################################################
## DEFAULT SETTINGS ##
######################
FIRMWARE_DIR="${__basedir}/firmware-images"
NODES_DIR="${__basedir}/nodes"

_main ${*}

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
#	- lede-custom / lede-customized
## 2.2.0
# * Flash via tftp
#	=> New state failsafe


# Just for the record
# "normal" nohup usage, which is sadly not available :-(
# * Redirecting stdout, stderr, and stdin, and running in the backgroud
# 	 `nohup sysupgrade -n /tmp/fw \
#		> /dev/null 2> /dev/null < /dev/null &`
#
########################################################################
# NOTES
## EXAMPLE USAGE
# ./owrtconfig-ng.sh --nodes 0142 --from factory --to lede --sudo
# ./owrtconfig-ng.sh --nodes 0142 --from lede --to lede --sudo
# ./owrtconfig-ng.sh --nodes 0142 --from lede --to factory --sudo
