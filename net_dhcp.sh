#!/bin/sh

# parameter:
# pre_del	- delete old network setting
# interface	- network section name
# ifname	- network device name
# mtu		- mtu
# disabled	- disable network
# 
# example:
# pre_del=1 interface=wan ifname=eth0 mtu=1500 disabled=0 ./net_dhcp.sh

if [ -n "$interface" ]; then
        section=$interface
else
        section="wan"
fi
if [ -n "$pre_del" ]; then
    echo del network.$section > /tmp/dhcp_in
    echo set network.$section=interface >> /tmp/dhcp_in
else
    echo set network.$section=interface > /tmp/dhcp_in
fi
if [ -n "$ifname" ]; then
        echo set network.$section.ifname=$ifname >> /tmp/dhcp_in
fi
echo set network.$section.proto=dhcp >> /tmp/dhcp_in
if [ -n "$mtu" ]; then
        echo set network.$section.mtu=$mtu >> /tmp/dhcp_in
fi
if [ -n "$disabled" ]; then
        echo set network.$section.disabled=$disabled >> /tmp/dhcp_in
fi

## dhcp config
echo del dhcp.$section >> /tmp/dhcp_in
echo set dhcp.$section=dhcp >> /tmp/dhcp_in
echo set dhcp.$section.interface=$section >> /tmp/dhcp_in
echo set dhcp.$section.ignore='1' >> /tmp/dhcp_in

echo commit network >> /tmp/dhcp_in
echo commit dhcp >> /tmp/dhcp_in
echo restart >> /tmp/dhcp_in
/usr/bin/util_uci -f /tmp/dhcp_in
rm /tmp/dhcp_in