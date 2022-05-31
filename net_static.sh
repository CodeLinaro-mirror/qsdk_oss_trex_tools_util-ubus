#!/bin/sh
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

echo commit >> /tmp/static_in
echo restart >> /tmp/static_in
/usr/bin/util_uci /tmp/static_in
rm /tmp/static_in

