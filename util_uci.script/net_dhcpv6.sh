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

if [ -n "$interface" ]; then
	section=$interface
else
	section="wan6"
fi
tmpfile=/var/run/net_dhcpv6.$section.$$

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
# whether set remote nexthop as the system defaultroute
if [ -n "$defaultroute" ]; then
	echo set network.$section.defaultroute=$defaultroute >> $tmpfile
fi

echo set network.$section.proto=dhcpv6 >> $tmpfile
if [ -n "$ifname" ]; then
	echo set network.$section.ifname=$ifname >> $tmpfile
fi
if [ -n "$mtu" ]; then
	echo set network.$section.mtu=$mtu >> $tmpfile
fi

## disable dhcp server on interface
echo del dhcp.$section >> $tmpfile
echo set dhcp.$section=dhcp >> $tmpfile
echo set dhcp.$section.interface=$section >> $tmpfile
echo set dhcp.$section.ignore='1' >> $tmpfile
## add interface to firewall zone wan
iflist=$(util_uci get firewall.@zone[1].network|cut -d= -f2)
if ! echo "$iflist"|grep -qw $interface; then
	echo set_list firewall.@zone[1].network=$iflist $interface >> $tmpfile
	echo commit firewall >> $tmpfile
fi

echo commit network >> $tmpfile
echo commit dhcp >> $tmpfile
#echo restart >> $tmpfile
/usr/bin/util_uci -f $tmpfile
rm $tmpfile
