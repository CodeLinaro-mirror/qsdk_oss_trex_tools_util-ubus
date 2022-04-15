#!/bin/sh
if [ -n "$interface" ]; then
        section=$interface
else
        section="wan"
fi
if [ -n "$pre_del" ]; then
    echo del network.$section > dhcp_in
    echo set network.$section=interface >> dhcp_in
else
    echo set network.$section=interface > dhcp_in
fi
if [ -n "$ifname" ]; then
        echo set network.$section.ifname=$ifname >> dhcp_in
fi
echo set network.$section.proto=dhcp >> dhcp_in
if [ -n "$mtu" ]; then
        echo set network.$section.mtu=$mtu >> dhcp_in
fi
if [ -n "$disabled" ]; then
        echo set network.$section.disabled=$disabled >> dhcp_in
fi

## dhcp config
echo del dhcp.wan >> dhcp_in
echo set dhcp.wan=dhcp >> dhcp_in
echo set dhcp.wan.interface='wan' >> dhcp_in
echo set dhcp.wan.ignore='1' >> dhcp_in

echo commit >> dhcp_in
echo restart >> dhcp_in
/root/util_uci_arm dhcp_in