#!/bin/sh

# parameter:
# pre_del 	- delete old network setting
# interface   	- network section name
# ifname	- network device name
# ipaddr	- network ip address
# netmask	- network netmask
# mtu		- mtu
# gateway	- network gateway
# disabled	- disable network
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
if [ -n "$pre_del" ]; then
    echo del network.$section > /tmp/static_in
    echo set network.$section=interface >> /tmp/static_in
else
    echo set network.$section=interface > /tmp/static_in
fi

if [ -n "$ipaddr" ]; then
        echo set network.$section.ipaddr=$ipaddr >> /tmp/static_in
fi
if [ -n "$ifname" ]; then
        echo set network.$section.ifname=$ifname >> /tmp/static_in
fi
echo set network.$section.proto=static >> /tmp/static_in
if [ -n "$netmask" ]; then
        echo set network.$section.netmask=$netmask >> /tmp/static_in
fi
if [ -n "$mtu" ]; then
        echo set network.$section.mtu=$mtu >> /tmp/static_in
fi
if [ -n "$gateway" ]; then
        echo set network.$section.gateway=$gateway >> /tmp/static_in
fi
if [ -n "$disabled" ]; then
        echo set network.$section.disable=$disabled >> /tmp/static_in
fi
if [ -n "$dns1" ]; then
	if [ -n "$dns2" ]; then
        echo set network.$section.dns=$dns1 $dns2 >> /tmp/static_in
    else
    	echo set network.$section.dns=$dns1 >> /tmp/static_in
    fi
fi

## dhcp config
echo del dhcp.$section >> /tmp/static_in
echo set dhcp.$section=dhcp >> /tmp/static_in
echo set dhcp.$section.interface=$section >> /tmp/static_in
echo set dhcp.$section.ignore=1 >> /tmp/static_in

echo commit network>> /tmp/static_in
echo commit dhcp>> /tmp/static_in
echo restart >> /tmp/static_in
/usr/bin/util_uci -f /tmp/static_in
rm /tmp/static_in

