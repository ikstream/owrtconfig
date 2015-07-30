#!/bin/sh
# Poor mens version of `nohup` if on system not available.
#
# Thanks to bittorf/kalua.git who got this magic somewhere else.
nohup(){
	# Close stdin, and make any read attempt an error
		if [ -t 0 ]
		then
			exec 0>/dev/null
		fi

	# Redirect stdout to a file if it's a TTY
		if [ -t 1 ]
		then
			exec 1>/tmp/nohup.out
			if [ $? -ne 0 ]
			then
				exec 1>/tmp/nohup.out
			fi
		fi

	# Redirect stderr to stdout if it's a TTY
		if [ -t 2 ]
		then
			exec 2>&1
		fi

	# Trap the HUP signal to ignore it
		trap : HUP
}

nohup
exec $@

# Usage:
#	 sh /tmp/nohup.sh sysupgrade -n /tmp/fw
#
