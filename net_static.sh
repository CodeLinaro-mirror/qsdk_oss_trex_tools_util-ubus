#!/bin/sh
if [ -n "$interface" ]; then
        section=$interface
else
        section="wan"
fi
if [ -n "$pre_del" ]; then
    echo del network.$section > static_in
    echo set network.$section=interface >> static_in
else
    echo set network.$section=interface > static_in
fi
echo set network.$section=interface >> static_in
if [ -n "$ipaddr" ]; then
        echo set network.$section.ipaddr=$ipaddr >> static_in
fi
if [ -n "$ifname" ]; then
        echo set network.$section.ifname=$ifname >> static_in
fi
echo set network.$section.proto=static >> static_in
if [ -n "$netmask" ]; then
        echo set network.$section.netmask=$netmask >> static_in
fi
if [ -n "$mtu" ]; then
        echo set network.$section.mtu=$mtu >> static_in
fi
if [ -n "$gateway" ]; then
        echo set network.$section.gateway=$gateway >> static_in
fi
if [ -n "$disabled" ]; then
        echo set network.$section.disable=$disabled >> static_in
fi

## dhcp config
echo del dhcp.wan >> static_in
echo set dhcp.wan=dhcp >> static_in
echo set dhcp.wan.interface='wan' >> static_in
echo set dhcp.wan.ignore='1' >> static_in

echo commit >> static_in
echo restart >> static_in
/root/util_uci_arm static_in

