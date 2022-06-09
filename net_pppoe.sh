#!/bin/sh
if [ -n "$interface" ]; then
        section=$interface
else
        section="wan"
fi
if [ -n "$pre_del" ]; then
    echo del network.$section > /tmp/pppoe_in
    echo set network.$section=interface >> /tmp/pppoe_in
else
    echo set network.$section=interface > /tmp/pppoe_in
fi
if [ -n "$ifname" ]; then
        echo set network.$section.ifname=$ifname >> /tmp/pppoe_in
fi
echo set network.$section.proto=pppoe >> /tmp/pppoe_in
if [ -n "$username" ]; then
        echo set network.$section.username=$username >> /tmp/pppoe_in
fi
if [ -n "$passwd" ]; then
        echo set network.$section.password=$passwd >> /tmp/pppoe_in
fi
if [ -n "$mtu" ]; then
        echo set network.$section.mtu=$mtu >> /tmp/pppoe_in
fi
if [ -n "$disabled" ]; then
        echo set network.$section.disabled=$disabled >> /tmp/pppoe_in
fi

## dhcp config
echo del dhcp.$section >> /tmp/pppoe_in
echo set dhcp.$section=dhcp >> /tmp/pppoe_in
echo set dhcp.$section.interface=$section >> /tmp/pppoe_in
echo set dhcp.$section.ignore='1' >> /tmp/pppoe_in

echo commit network >> /tmp/pppoe_in
echo commit dhcp >> /tmp/pppoe_in
echo restart >> /tmp/pppoe_in
/usr/bin/util_uci -f /tmp/pppoe_in
rm /tmp/pppoe_in
