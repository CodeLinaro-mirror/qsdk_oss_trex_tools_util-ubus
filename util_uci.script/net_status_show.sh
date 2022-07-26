#!/bin/sh
net_status_show ()
{
	local up available autostart dynamic
	local uptime
	local proto device l3_device
	local ipaddr1_addr ipaddr1_mask ipaddr1_ptpaddr
	local ipaddr2_addr ipaddr2_mask ipaddr2_ptpaddr
	local ipaddr3_addr ipaddr3_mask ipaddr3_ptpaddr
	local ip6addr1_addr ip6addr1_mask
	local ip6addr2_addr ip6addr2_mask
	local ip6addr3_addr ip6addr3_mask
	local ip6pf1_addr ip6pf1_mask
	local ip6pf2_addr ip6pf2_mask
	local ip6pf3_addr ip6pf3_mask
	local ip6pf_assig1_addr ip6pf_assig1_mask ip6pf_assig1_preferred ip6pf_assig1_valid ip6pf_assig1_localaddr ip6pf_assig1_localmask
	local ip6pf_assig2_addr ip6pf_assig2_mask ip6pf_assig2_preferred ip6pf_assig2_valid ip6pf_assig2_localaddr ip6pf_assig2_localmask
	local ip6pf_assig3_addr ip6pf_assig3_mask ip6pf_assig3_preferred ip6pf_assig3_valid ip6pf_assig3_localaddr ip6pf_assig3_localmask
	local route1_target route1_mask route1_nexthop route1_metric route1_valid route1_source 
	local route2_target route2_mask route2_nexthop route2_metric route2_valid route2_source 
	local route3_target route3_mask route3_nexthop route3_metric route3_valid route3_source 
	local route4_target route4_mask route4_nexthop route4_metric route4_valid route4_source 
	local dns1 dns2 dns3 dns4
	local interface str ifname

	interface=$1
	/usr/sbin/net_status.sh $interface > /var/run/$interface.tmp.$$
	. /var/run/$interface.tmp.$$
	rm . /var/run/$interface.tmp.$$
	
	str="[$interface]"
	[ -n "$device" ] && str="$str dev=$device"
	# show l3_device only if it differs than device
	[ -n "$l3_device" -a "$l3_device" != "$device" ] && str="$str l3dev=$l3_device"
	str="$str proto=$proto up=$up auto=$autostart dynamic=$dynamic"
	[ -n "$uptime" ] && str="$str uptime=$uptime"
	echo "$str"

	ifname=$(echo $(ubus call network.device status |jsonfilter -e "@['$device']['bridge-members'].*"))
	[ -n "$ifname" ] && echo "	ifname	$ifname"
	
	if [ -n "$ipaddr1_addr" -o -n "$ipaddr2_addr" -o -n "$ipaddr3_addr" ]; then
		str=""
		[ -n "$ipaddr1_addr" ] && str="$str$ipaddr1_addr/$ipaddr1_mask "
		[ -n "$ipaddr2_addr" ] && str="$str$ipaddr2_addr/$ipaddr2_mask "
		[ -n "$ipaddr3_addr" ] && str="$str$ipaddr3_addr/$ipaddr3_mask "
		echo "	ip	$str"
	fi
	
	if [ -n "$ip6addr1_addr" -o -n "$ip6addr2_addr" -o -n "$ip6addr3_addr" ]; then
		str=""
		[ -n "$ip6addr1_addr" ] && str="$str$ip6addr1_addr/$ip6addr1_mask "
		[ -n "$ip6addr2_addr" ] && str="$str$ip6addr2_addr/$ip6addr2_mask "
		[ -n "$ip6addr3_addr" ] && str="$str$ip6addr3_addr/$ip6addr3_mask "
		echo "	ip6	$str"
	fi
	
	if [ -n "$ip6pf1_addr" -o -n "$ip6pf2_addr" -o -n "$ip6pf3_addr" ]; then
		str=""
		[ -n "$ip6pf1_addr" ] && str="$str$ip6pf1_addr/$ip6pf1_mask "
		[ -n "$ip6pf2_addr" ] && str="$str$ip6pf2_addr/$ip6pf2_mask "
		[ -n "$ip6pf3_addr" ] && str="$str$ip6pf3_addr/$ip6pf3_mask "
		echo "	ip6pf	$str"
	fi
	
	if [ -n "$ip6pf_assig1_addr" -o -n "$ip6pf_assig2_addr" -o -n "$ip6pf_assig3_addr" ]; then
		str=""
		[ -n "$ip6pf_assig1_addr" ] && str="$str$ip6pf_assig1_addr/$ip6pf_assig1_mask "
		[ -n "$ip6pf_assig2_addr" ] && str="$str$ip6pf_assig2_addr/$ip6pf_assig2_mask "
		[ -n "$ip6pf_assig3_addr" ] && str="$str$ip6pf_assig3_addr/$ip6pf_assig3_mask "
		echo "	ip6pf_assign	$str"
	fi
	
	if [ "$proto" = "pptp" ]; then
		if [ -n "$route1_target" -o -n "$route2_target" -o -n "$route3_target" -o -n "$route4_target" ]; then
			str=""
			[ -n "$route1_target" ] && str="$str$route1_target/$route1_mask "
			[ -n "$route2_target" ] && str="$str$route2_target/$route2_mask "
			[ -n "$route3_target" ] && str="$str$route3_target/$route3_mask "
			[ -n "$route4_target" ] && str="$str$route4_target/$route4_mask "
			echo "	route	$str"
		fi
	else
		[ -n "$route1_target" ] && echo "	route	$route1_target/$route1_mask nh=$route1_nexthop src=$route1_source"
		[ -n "$route2_target" ] && echo "	route	$route2_target/$route2_mask nh=$route2_nexthop src=$route2_source"
		[ -n "$route3_target" ] && echo "	route	$route3_target/$route3_mask nh=$route3_nexthop src=$route3_source"
		[ -n "$route4_target" ] && echo "	route	$route4_target/$route4_mask nh=$route4_nexthop src=$route4_source"
	fi
	
	if [ -n "$dns1" -o -n "$dns2" -o -n "$dns3" -o -n "$dns4" ]; then
		str=""
		[ -n "$dns1" ] && str="$str$dns1 "
		[ -n "$dns2" ] && str="$str$dns2 "
		[ -n "$dns3" ] && str="$str$dns3 "
		[ -n "$dns4" ] && str="$str$dns4 "
		echo "	dns	$str"
	fi
}

list="$(ubus call network.interface dump |  jsonfilter -e '@.interface[@].interface')"
for inf in $list; do
	if [ -z "$1" ]; then
		net_status_show $inf
	elif echo $inf | grep -q "$1"; then
		net_status_show $inf
	fi
done
