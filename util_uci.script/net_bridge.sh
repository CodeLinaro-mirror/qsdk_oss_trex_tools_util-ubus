#!/bin/sh

# parameter:
# pre_del	- delete old network setting
# interface	- network section name
# disabled	- disable network
# auto		- bring up on boot
# ifname	- network device name
# ipaddr	- network ip address
# netmask	- network netmask
# gateway	- network gateway
#
# example:
# pre_del=1 interface=lan0 ifname='eth0.2.0 eth0.3.0 eth0.4.0 eth0.5.0' ipaddr=192.168.1.1 netmask=255.255.255.0 gateway=192.168.1.254 ./net_bridge.sh

if [ -n "$interface" ]; then
	section=$interface
else
	section="lan"
fi
tmpfile=/var/run/net_bridge.$section.$$

if [ $cleanall -eq 1 ]; then
	echo del network.lan > $tmpfile
	echo del network.lan0 >> $tmpfile
	echo del network.lan1 >> $tmpfile
	echo del network.lan2 >> $tmpfile
else
	if [ -n "$pre_del" ]; then
		echo del network.$section > $tmpfile
		echo set network.$section=interface >> $tmpfile
	else
		echo set network.$section=interface > $tmpfile
	fi
	if [ -n "$disabled" ]; then
		echo set network.$section.disable=$disabled >> $tmpfile
	fi
	# whether to bring up interface on boot
	if [ -n "$auto" ]; then
		echo set network.$section.auto=$auto >> $tmpfile
	fi

	echo set network.$section.type=bridge >> $tmpfile
	if [ -n "$ifname" ]; then
		echo set network.$section.ifname=$ifname >> $tmpfile
	fi
	if [ -n "$ipaddr" ]; then
		echo set network.$section.proto=static >> $tmpfile
		echo set network.$section.ipaddr=$ipaddr >> $tmpfile
	fi
	if [ -n "$netmask" ]; then
		echo set network.$section.netmask=$netmask >> $tmpfile
	fi
	if [ -n "$gateway" ]; then
		echo set network.$section.gateway=$gateway >> $tmpfile
	fi
fi

echo commit network >> $tmpfile
#echo restart >> $tmpfile
/usr/bin/util_uci -f $tmpfile
rm -f $tmpfile
