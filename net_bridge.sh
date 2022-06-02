#!/bin/sh
if [ -n "$interface" ]; then
        section=$interface
else
        section="lan0"
fi
if [ -n "$pre_del" ]; then
    echo del network.$section > /tmp/bridge_in
    echo set network.$section=interface >> /tmp/bridge_in
else
    echo set network.$section=interface > /tmp/bridge_in
fi

if [ -n "$ipaddr" ]; then
        echo set network.$section.ipaddr=$ipaddr >> /tmp/bridge_in
fi
if [ -n "$ifname" ]; then
        echo set network.$section.ifname=$ifname >> /tmp/bridge_in
fi
echo set network.$section.type=bridge >> /tmp/bridge_in
if [ -n "$netmask" ]; then
        echo set network.$section.netmask=$netmask >> /tmp/bridge_in
fi
if [ -n "$gateway" ]; then
        echo set network.$section.gateway=$gateway >> /tmp/bridge_in
fi
if [ -n "$disabled" ]; then
        echo set network.$section.disable=$disabled >> /tmp/bridge_in
fi

echo commit >> /tmp/bridge_in
echo restart >> /tmp/bridge_in
/usr/bin/util_uci -f /tmp/bridge_in
rm -f /tmp/static_in

