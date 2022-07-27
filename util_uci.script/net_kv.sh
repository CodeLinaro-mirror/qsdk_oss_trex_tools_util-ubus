#!/bin/sh
# this script uses the jsonfilter to do json parse and turn the result to key=value format
#
# support attr
# ----------------------------------------------------------------------------
# up|available|autostart|dynamic
# uptime
# proto|device|l3_device
# ipaddr[1-3]_			(addr|mask|ptpaddr) ipv4 addr assigned by static/dhcp/pppoe
# ip6addr[1-3]_			(addr|mask) -ipv6 addr assigned by static/dhcpv6
# ip6pf[1-3]_			(addr|mask) - ipv6 subnet assigned by static
# ip6pf_assign[1-3]_		(addr|mask|preferred|valid|localaddr|localmask) - ipv6 subnet assigned by dhcpv6
# route[1-4]_			(target|mask|nexthop|metric|valid|source)
# dns[1-4]
# 
if [ -z "$1" ]; then
	echo $0 [openwrt_inf_name]
	ubus call network.interface dump |  jsonfilter -e '@.interface[@].interface'
	exit 1
fi

ubus call network.interface.$1 status|jsonfilter \
-e up='@["up"]' \
-e available='@["available"]' \
-e autostart='@["autostart"]' \
-e dynamic='@["dynamic"]' \
-e uptime='@["uptime"]' \
-e proto='@["proto"]' \
-e device='@["device"]' \
-e l3_device='@["l3_device"]' \
-e ipaddr1_addr='@["ipv4-address"][0].address' \
-e ipaddr1_mask='@["ipv4-address"][0].mask' \
-e ipaddr1_ptpaddr='@["ipv4-address"][0].ptpaddress' \
-e ipaddr2_addr='@["ipv4-address"][1].address' \
-e ipaddr2_mask='@["ipv4-address"][1].mask' \
-e ipaddr2_ptpaddr='@["ipv4-address"][1].ptpaddress' \
-e ipaddr3_addr='@["ipv4-address"][2].address' \
-e ipaddr3_mask='@["ipv4-address"][2].mask' \
-e ipaddr3_ptpaddr='@["ipv4-address"][2].ptpaddress' \
-e ip6addr1_addr='@["ipv6-address"][0].address' \
-e ip6addr1_mask='@["ipv6-address"][0].mask' \
-e ip6addr2_addr='@["ipv6-address"][1].address' \
-e ip6addr2_mask='@["ipv6-address"][1].mask' \
-e ip6addr3_addr='@["ipv6-address"][2].address' \
-e ip6addr3_mask='@["ipv6-address"][2].mask' \
-e ip6pf1_addr='@["ipv6-prefix"][0].address' \
-e ip6pf1_mask='@["ipv6-prefix"][0].mask' \
-e ip6pf2_addr='@["ipv6-prefix"][1].address' \
-e ip6pf2_mask='@["ipv6-prefix"][1].mask' \
-e ip6pf3_addr='@["ipv6-prefix"][2].address' \
-e ip6pf3_mask='@["ipv6-prefix"][2].mask' \
-e ip6pf_assign1_addr='@["ipv6-prefix-assignment"][0].addr' \
-e ip6pf_assign1_mask='@["ipv6-prefix-assignment"][0].mask' \
-e ip6pf_assign1_preferred='@["ipv6-prefix-assignment"][0].preferred' \
-e ip6pf_assign1_valid='@["ipv6-prefix-assignment"][0].valid' \
-e ip6pf_assign1_localaddr='@["ipv6-prefix-assignment"][0]["local-address"].address' \
-e ip6pf_assign1_localmask='@["ipv6-prefix-assignment"][0]["local-address"].mask' \
-e ip6pf_assign2_addr='@["ipv6-prefix-assignment"][1].addr' \
-e ip6pf_assign2_mask='@["ipv6-prefix-assignment"][1].mask' \
-e ip6pf_assign2_preferred='@["ipv6-prefix-assignment"][1].preferred' \
-e ip6pf_assign2_valid='@["ipv6-prefix-assignment"][1].valid' \
-e ip6pf_assign2_localaddr='@["ipv6-prefix-assignment"][1]["local-address"].address' \
-e ip6pf_assign2_localmask='@["ipv6-prefix-assignment"][1]["local-address"].mask' \
-e ip6pf_assign3_addr='@["ipv6-prefix-assignment"][2].addr' \
-e ip6pf_assign3_mask='@["ipv6-prefix-assignment"][2].mask' \
-e ip6pf_assign3_preferred='@["ipv6-prefix-assignment"][2].preferred' \
-e ip6pf_assign3_valid='@["ipv6-prefix-assignment"][2].valid' \
-e ip6pf_assign3_localaddr='@["ipv6-prefix-assignment"][2]["local-address"].address' \
-e ip6pf_assign3_localmask='@["ipv6-prefix-assignment"][2]["local-address"].mask' \
-e route1_target='@["route"][0].target' \
-e route1_mask='@["route"][0].mask' \
-e route1_nexthop='@["route"][0].nexthop' \
-e route1_metric='@["route"][0].metric' \
-e route1_valid='@["route"][0].valid' \
-e route1_source='@["route"][0].source' \
-e route2_target='@["route"][1].target' \
-e route2_mask='@["route"][1].mask' \
-e route2_nexthop='@["route"][1].nexthop' \
-e route2_metric='@["route"][1].metric' \
-e route2_valid='@["route"][1].valid' \
-e route2_source='@["route"][1].source' \
-e route3_target='@["route"][2].target' \
-e route3_mask='@["route"][2].mask' \
-e route3_nexthop='@["route"][2].nexthop' \
-e route3_metric='@["route"][2].metric' \
-e route3_valid='@["route"][2].valid' \
-e route3_source='@["route"][2].source' \
-e route4_target='@["route"][3].target' \
-e route4_mask='@["route"][3].mask' \
-e route4_nexthop='@["route"][3].nexthop' \
-e route4_metric='@["route"][3].metric' \
-e route4_valid='@["route"][3].valid' \
-e route4_source='@["route"][3].source' \
-e dns1='@["dns-server"][0]' \
-e dns2='@["dns-server"][1]' \
-e dns3='@["dns-server"][2]' \
-e dns4='@["dns-server"][3]' \
|sed -e "s/; export /\n/g" -e "s/;//g" -e "s/^export //" \
|sed -e "s/='/=/" -e "s/'$//" -e "s/'.$//"
echo ""
