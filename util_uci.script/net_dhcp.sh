#!/bin/sh

# parameter:
# pre_del	- delete old network setting
# interface	- network section name
# disabled	- disable network
# auto		- bring up on boot
# ifname	- network device name
# mtu		- mtu
# 
# example:
# pre_del=1 interface=wan ifname=eth0 ./net_dhcp.sh

if [ -n "$interface" ]; then
	section=$interface
else
	section="wan"
fi
tmpfile=/var/run/net_dhcp.$section.$$

if [ -n "$pre_del" ]; then
	echo del network.$section > $tmpfile
	echo set network.$section=interface >> $tmpfile
else
	echo set network.$section=interface > $tmpfile
fi
if [ -n "$disabled" ]; then
	echo set network.$section.disabled=$disabled >> $tmpfile
fi
# whether to bring up interface on boot
if [ -n "$auto" ]; then
	echo set network.$section.auto=$auto >> $tmpfile
fi

echo set network.$section.proto=dhcp >> $tmpfile
if [ -n "$ifname" ]; then
	echo set network.$section.ifname=$ifname >> $tmpfile
fi
if [ -n "$mtu" ]; then
	echo set network.$section.mtu=$mtu >> $tmpfile
fi

## dhcp config
echo del dhcp.$section >> $tmpfile
echo set dhcp.$section=dhcp >> $tmpfile
echo set dhcp.$section.interface=$section >> $tmpfile
echo set dhcp.$section.ignore='1' >> $tmpfile

echo commit network >> $tmpfile
echo commit dhcp >> $tmpfile
echo restart >> $tmpfile
/usr/bin/util_uci -f $tmpfile
rm $tmpfile
