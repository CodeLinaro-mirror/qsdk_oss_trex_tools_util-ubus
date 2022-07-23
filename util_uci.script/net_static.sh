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
# dns3		- dns3
# dns4		- dns4
# ip6addr	- network ip6 address
# ip6gw		- network ip6 gateway
# ip6prefix	- public prefix routed to this device for distribution to clients
# ip6ifaceid	- 'eui64', 'random', fixed value like '::1' or '::1:2'
#
# example:
# pre_del=1 interface=wan ifname=eth0 ipaddr=192.168.33.200 netmask=255.255.255.0 gateway=192.168.33.1 mtu=1500 dns1=8.8.8.8 dns2=0.0.0.0 ./net_static.sh
# pre_del=1 interface=wan6 ifname=eth0 ip6addr=2002::100 ip6gw=2002::1 ip6prefix=2002:0:0:1:: dns1=2001:4860:4860::8888 dns2=2001:4860:4860::8844 ./net_static.sh

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
# ipaddr should be list option
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

# dns is actually a list option, but we use option with multiple value instead as set_list is not supported in util_uci yet
# ps: it seems list option is backward compatible with option with multiple value
if [ -n "$dns1" -o -n "$dns2" -o -n "$dns3" -o -n "$dns4" ]; then
	local str=""
	[ -n "$dns1" ] && str="$str $dns1"
	[ -n "$dns2" ] && str="$str $dns2"
	[ -n "$dns3" ] && str="$str $dns3"
	[ -n "$dns4" ] && str="$str $dns4"
	echo "set network.$section.dns='${str# }'" >> $tmpfile
fi

# ip6addr should be list option
if [ -n "$ip6addr" ]; then
	echo set network.$section.ip6addr=$ip6addr >> $tmpfile
fi
if [ -n "$ip6gw" ]; then
	echo set network.$section.ip6gw=$ip6gw >> $tmpfile
fi
if [ -n "$ip6prefix" ]; then
	echo set network.$section.ip6prefix=$ip6prefix >> $tmpfile
fi
if [ -n "$ip6ifaceid" ]; then
	echo set network.$section.ip6ifaceid=$ip6ifaceid >> $tmpfile
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
