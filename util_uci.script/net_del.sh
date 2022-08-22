#!/bin/sh
# remove interface from /etc/config/(network|dhcp|firewall)
# the interface instance in mem is automatically removed when network.interface is removed

remove_name_from_list() {
	local name=$1; shift
	local str=""
	for listname in $*; do
		if [ "$listname" != "$name" ]; then
			str="$str $listname"
		fi
	done
	echo ${str# }
}

if [ -z "$1" ]; then
	echo "$0 <openwrt_inf...>"
	echo "[restart=1] $0 <openwrt_inf...>"

	if [ -z "$(which ubus)" ]; then
		echo "ubus not available?"
		exit 1
	fi
	echo ""
	echo "available openwrt_inf:"
	iflist=$(ubus call network.interface dump |  jsonfilter -e '@.interface[@].interface')
	if [ ! -z "$iflist" ]; then
		set $(ubus call network.interface dump |  jsonfilter -e '@.interface[@].device')
		for ifname in $iflist; do
			devname=$1; shift
			printf "%-15s\t%s\n" "$ifname" "($devname)"
		done
	fi

	echo ""
	echo "example:"
	echo "net_del.sh wan0"
	echo "restart=1 /usr/sbin/net_del.sh wan0"
	echo ""
	exit 1
fi

iflist="$*"
tmpfile=/var/run/net_del.$$
echo "" > $tmpfile

## del interface
for ifname in $iflist; do
	echo del network.$ifname >> $tmpfile
done

## del dhcp server config for interface
for ifname in $iflist; do
	# do not remove dhcp config for lan, as lan contains default dhcp setting for nat subnet
	[ "$ifname" != "lan" ] && echo del dhcp.$ifname >> $tmpfile
done

## del interface from firewall zone wan
wanlist=$(util_uci get firewall.@zone[1].network|cut -d= -s -f2)
for ifname in $iflist; do
	wanlist2=$(remove_name_from_list $ifname $wanlist)
	wanlist="$wanlist2"
done
if [ -n "$wanlist" ]; then
	echo "set_list firewall.@zone[1].network=$wanlist" >> $tmpfile
else
	echo "del firewall.@zone[1].network" >> $tmpfile
fi

## del interface from firewall zone lan
lanlist=$(util_uci get firewall.@zone[0].network|cut -d= -s -f2)
for ifname in $iflist; do
	lanlist2=$(remove_name_from_list $ifname $lanlist)
	lanlist="$lanlist2"
done
if [ -n "$lanlist" ]; then
	echo "set_list firewall.@zone[0].network=$lanlist" >> $tmpfile
else
	echo "del firewall.@zone[0].network" >> $tmpfile
fi

echo commit firewall >> $tmpfile
echo commit network >> $tmpfile
echo commit dhcp >> $tmpfile

if [ -n "$restart" -a "$restart" = "1" ]; then
	echo restart >> $tmpfile
fi
/usr/bin/util_uci -f $tmpfile
rm $tmpfile
