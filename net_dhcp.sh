#!/bin/sh
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
echo del dhcp.wan >> /tmp/dhcp_in
echo set dhcp.wan=dhcp >> /tmp/dhcp_in
echo set dhcp.wan.interface='wan' >> /tmp/dhcp_in
echo set dhcp.wan.ignore='1' >> /tmp/dhcp_in

echo commit >> /tmp/dhcp_in
echo restart >> /tmp/dhcp_in
/usr/bin/util_uci /tmp/dhcp_in
rm /tmp/dhcp_in