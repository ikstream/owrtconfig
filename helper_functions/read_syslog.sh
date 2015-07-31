#!/bin/sh

echo "*** Follow syslog and show only in.tftpd messages..."
echo "*** Quit with CTRL+C"
echo

tail \
	--follow \
	/var/log/syslog \
	--lines=0 \
| grep "tftpd"
