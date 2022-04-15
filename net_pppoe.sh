#!/bin/sh
if [ -n "$interface" ]; then
        section=$interface
else
        section="wan"
fi
if [ -n "$pre_del" ]; then
    echo del network.$section > pppoe_in
    echo set network.$section=interface >> pppoe_in
else
    echo set network.$section=interface > pppoe_in
fi
if [ -n "$ifname" ]; then
        echo set network.$section.ifname=$ifname >> pppoe_in
fi
echo set network.$section.proto=pppoe >> pppoe_in
if [ -n "$username" ]; then
        echo set network.$section.username=$username >> pppoe_in
fi
if [ -n "$passwd" ]; then
        echo set network.$section.password=$passwd >> pppoe_in
fi
if [ -n "$mtu" ]; then
        echo set network.$section.mtu=$mtu >> pppoe_in
fi
if [ -n "$disabled" ]; then
        echo set network.$section.disabled=$disabled >> pppoe_in
fi

## dhcp config
echo del dhcp.wan >> pppoe_in
echo set dhcp.wan=dhcp >> pppoe_in
echo set dhcp.wan.interface='wan' >> pppoe_in
echo set dhcp.wan.ignore='1' >> pppoe_in

echo commit >> pppoe_in
echo restart >> pppoe_in
/root/util_uci_arm pppoe_in
