#!/bin/sh
# FIXME / TODO: Works currently for dev-porpuse on devices which listen for 192.168.0.1

__pwd="$( pwd )"
__dirname="$( dirname ${0} )" 
__basename="$( basename ${0} )"

. ${__dirname}/_helper-functions.sh
. ${__dirname}/flash-over-factory/_helper-functions.sh

ME="${__basename}"

if [ -z "${*}" ]; then
	_error "no host file specified."
	exit 1
fi

SUDO_FUNC="sudo"
if [ -n "$SUDO_FUNC" ]; then
	_log "info" "** checking sudo.."
	$SUDO_FUNC true || _error "no \`sudo\` available"
fi

router_ip="192.168.0.1"


__log "info" ""
$SUDO_FUNC /etc/init.d/network-manager stop; sleep 2
_reset_network
$SUDO_FUNC ip addr add 192.168.0.2/24 dev eth0 >/dev/null 2>/dev/null

# while loop till key pressed got from http://stackoverflow.com/a/5297780
if [ -t 0 ]; then
	stty -echo -icanon -icrnl time 0 min 0
fi

while [ -z ${keypress} ]; do
	for mac in $(grep -v '^#' ${1} | cut -d ',' -f 1 | awk '{print $1}'); do
		
		{
			$SUDO_FUNC ip -s -s neigh flush all  >/dev/null 2>/dev/null
			$SUDO_FUNC arp -s $router_ip $mac    >/dev/null 2>/dev/null
			ping -q -c 1 -W 1 $router_ip         >/dev/null 2>/dev/null
		}

		if [ ${?} -eq 0 ]; then
			_log "info" "${mac} is reachable"
		else
			_log "warning" "${mac} is not reachable"
		fi
		$SUDO_FUNC arp -d $router_ip             >/dev/null 2>/dev/null
	done
	keypress="$( cat -v )"
	sleep 1
done

if [ -t 0 ]; then
	stty sane
fi
_log "info" "keypressed."
_log "log" "quit ${__basename}"
__log "log" ""
$SUDO_FUNC /etc/init.d/network-manager start 
exit 0

