#!/bin/sh

# parameter:
# pre_del 	- delete old network setting
# interface   	- network section name
# disabled	- disable network
# auto		- bring up on boot
# ifname	- network device name
# ipaddr	- network ip address
# netmask	- network netmask
# mtu		- mtu
# gateway	- network gateway
# dns1		- dns1
# dns2		- dns2
#
# example:
# pre_del=1 interface=wan ifname=eth0 ipaddr=192.168.33.200 netmask=255.255.255.0 gateway=192.168.33.1 mtu=1500 dns1=8.8.8.8 dns2=0.0.0.0 ./net_static.sh

if [ -n "$interface" ]; then
	section=$interface
else
	section="wan"
fi
tmpfile=/var/run/net_static.$section.$$

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

echo set network.$section.proto=static >> $tmpfile
if [ -n "$ifname" ]; then
	echo set network.$section.ifname=$ifname >> $tmpfile
fi
if [ -n "$ipaddr" ]; then
	echo set network.$section.ipaddr=$ipaddr >> $tmpfile
fi
if [ -n "$netmask" ]; then
	echo set network.$section.netmask=$netmask >> $tmpfile
fi
if [ -n "$mtu" ]; then
	echo set network.$section.mtu=$mtu >> $tmpfile
fi
if [ -n "$gateway" ]; then
	echo set network.$section.gateway=$gateway >> $tmpfile
fi
if [ -n "$dns1" -a -n "$dns2" ]; then
	echo set network.$section.dns=$dns1 $dns2 >> $tmpfile
elif [ -n "$dns1" ]; then
	echo set network.$section.dns=$dns1 >> $tmpfile
elif [ -n "$dns2" ]; then
	echo set network.$section.dns=$dns2 >> $tmpfile
fi

## dhcp config
echo del dhcp.$section >> $tmpfile
echo set dhcp.$section=dhcp >> $tmpfile
echo set dhcp.$section.interface=$section >> $tmpfile
echo set dhcp.$section.ignore=1 >> $tmpfile

echo commit network>> $tmpfile
echo commit dhcp>> $tmpfile
echo restart >> $tmpfile
/usr/bin/util_uci -f $tmpfile
rm $tmpfile
