DESCRIPTION
===========

Owrtconfig is a script that configure multiple Openwrt routers all connected to
the same switch.
It is used at the Wireless Battle Mesh events  (http://battlemesh.org) in order to
configure multiple foneras running Openwrt, and freshly flashed with the
default firmware (all default openwrt devices default IP 192.168.1.1).

It loads a list of nodes (nodes.csv) and a list of commands to execute on each
router (commands.sh), and it can also upload files (scp) by changing the ARP cache 
to communicate with each router, one by one.



DEPENDENCIES
============

Please check that your system has the following commands (beware that
stripped-down versions of those provided by busybox might not work):

cat echo sudo arp ping ssh nc tail ssh

TESTED ON
=========

Ubuntu Karmic (9.10)
Ubuntu Maverick (10.10)

USAGE
=====

./owrtconfig -P telnet -H nodes.csv -C commands.sh
./owrtconfig -P ssh -H nodes.csv -C commands.sh
./scp-loop.sh -H nodes.csv file1 file2 .. 

NODES.CSV
=========

The input hosts file format (nodes.csv) is:

MAC,PARAM1,PARAM2,PARAM3,PARAM4,PARAM5,PARAM6,PARAM7,PARAM8,PARAM9

where:

* MAC: MAC address (ex: 00:18:84:29:b0:0c)
other values depend on your config script -- these are recomended uses
* PARAM1: hostname (ex: node01)
* PARAM2: wired IP address (ex: 192.168.20.1)
* PARAM3: wireless IP address (ex: 192.168.50.1)
* PARAM4: Not Used
* PARAM5: channel (ex: 11)
* PARAM6: adhoc cell (ex: 02:02:02:02:aa:aa) (adhoc cells needs to start with 02: ?)
* PARAM7: return-routes (ex: route add -net 192.168.20.0/24 gw 192.168.20.1)
* PARAM8: forward-routes (ex: route add -net 192.168.6.0/24 gw 192.168.4.2  && route add -net 192.168.15.0/24 gw 192.168.4.2  && route add -net 192.168.5.0/24 gw 192.168.4.2)
* PARAM9: Not Used

SSH KEYS
========

Look on this website howto setup ssh keys for automatic login:
http://telscom.ch/?p=217

TODO
====

* Make a check on dependencies
* include a config script to initialize ssh on opwnert-devices
* --Document howto generate ssh keys--
* Add support for first flash over stock firmware (i.e. with usage of `curl`)

AUTHORS
=======

Nicolas Thill <nico@openwrt.org>
Pieter Heremans <pieter@l45.be>
Benjamin Henrion <bh@udev.org>

LICENCE
=======

GPLv2

LINKS
=====

* http://battlemesh.org/BattleMeshV3/NodeConfigScript
* http://hackerspace.be/Wbm2009v2/NodeConfigurationFactory
* http://hackerspace.be/Wbm2009v2/NodeConfig
* http://hackerspace.be/Wbm2009v2/ConfigExpectScript
* http://www.zoobab.com/fonera
