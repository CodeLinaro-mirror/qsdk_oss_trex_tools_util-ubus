#!/bin/sh

# parameter:
# pre_del	- delete old network setting
# interface	- network section name
# disabled	- disable network
# auto		- bring up on boot
# defaultroute	- use nexthop as system defaultroute
# ifname	- network device name
# mtu		- mtu
# 
# example:
# pre_del=1 interface=wan ifname=eth0 ./net_dhcp.sh

if [ -z "$1" ]; then
	echo $0 [openwrt_inf_to_del]
	ubus call network.interface dump |  jsonfilter -e '@.interface[@].interface'
	exit 1
fi

interface=$1
tmpfile=/var/run/net_del.$interface.$$

## del interface
echo del network.$interface > $tmpfile

## del dhcp server config for interface
echo del dhcp.$interface >> $tmpfile

## del interface from firewall zone wan
iflist=$(util_uci get firewall.@zone[1].network|cut -d= -f2)
iflist2=""
for ifname in $iflist; do
	if [ "$ifname" != "$interface" ]; then
		iflist2="$iflist2 $ifname"
	fi
	echo "set_list firewall.@zone[1].network=${iflist2# }" >> $tmpfile
	echo commit firewall >> $tmpfile
done

echo commit network >> $tmpfile
echo commit dhcp >> $tmpfile
#echo restart >> $tmpfile
/usr/bin/util_uci -f $tmpfile
rm $tmpfile
