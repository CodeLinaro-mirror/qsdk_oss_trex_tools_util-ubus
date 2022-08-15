#!/bin/sh

add_static() {
	echo set network.$interface.proto=static >> $tmpfile
	[ -n "$ifname" ]	&& echo set network.$interface.ifname=$ifname >> $tmpfile
	[ -n "$mtu" ]		&& echo set network.$interface.mtu=$mtu >> $tmpfile
	[ -n "$defaultroute" ]	&& echo set network.$interface.defaultroute=$defaultroute >> $tmpfile	# use remote nexthop as default route
	[ -n "$ipaddr" ]	&& echo set network.$interface.ipaddr=$ipaddr >> $tmpfile	#  should be list option?
	[ -n "$netmask" ]	&& echo set network.$interface.netmask=$netmask >> $tmpfile
	[ -n "$gateway" ]	&& echo set network.$interface.gateway=$gateway >> $tmpfile

	# dns is actually a list option, but we use option with multiple value instead as set_list is not supported in util_uci yet
	# ps: it seems list option is backward compatible with option with multiple value
	if [ -n "$dns1" -o -n "$dns2" -o -n "$dns3" -o -n "$dns4" ]; then
		local str=""
		[ -n "$dns1" ] && str="$str $dns1"
		[ -n "$dns2" ] && str="$str $dns2"
		[ -n "$dns3" ] && str="$str $dns3"
		[ -n "$dns4" ] && str="$str $dns4"
		echo "set network.$interface.dns=${str# }" >> $tmpfile
	fi

	[ -n "$ip6addr" ]	&& echo set network.$interface.ip6addr=$ip6addr >> $tmpfile	# should be list option?
	[ -n "$ip6gw" ]		&& echo set network.$interface.ip6gw=$ip6gw >> $tmpfile
	[ -n "$ip6prefix" ]	&& echo set network.$interface.ip6prefix=$ip6prefix >> $tmpfile
	[ -n "$ip6ifaceid" ]	&& echo set network.$interface.ip6ifaceid=$ip6ifaceid >> $tmpfile
}

add_dhcp() {
	echo set network.$interface.proto=dhcp >> $tmpfile
	[ -n "$ifname" ]	&& echo set network.$interface.ifname=$ifname >> $tmpfile
	[ -n "$mtu" ]		&& echo set network.$interface.mtu=$mtu >> $tmpfile
	[ -n "$defaultroute" ]	&& echo set network.$interface.defaultroute=$defaultroute >> $tmpfile	# use remote nexthop as default route
}

add_dhcpv6() {
	echo set network.$interface.proto=dhcpv6 >> $tmpfile
	[ -n "$ifname" ]	&& echo set network.$interface.ifname=$ifname >> $tmpfile
	[ -n "$mtu" ]		&& echo set network.$interface.mtu=$mtu >> $tmpfile
	[ -n "$defaultroute" ]	&& echo set network.$interface.defaultroute=$defaultroute >> $tmpfile	# use remote nexthop as default route
}

add_pppoe() {
	echo set network.$interface.proto=pppoe >> $tmpfile
	[ -n "$ifname" ]	&& echo set network.$interface.ifname=$ifname >> $tmpfile
	[ -n "$mtu" ]		&& echo set network.$interface.mtu=$mtu >> $tmpfile
	[ -n "$defaultroute" ]	&& echo set network.$interface.defaultroute=$defaultroute >> $tmpfile	# use remote nexthop as default route
	[ -n "$username" ]	&& echo set network.$interface.username=$username >> $tmpfile
	[ -n "$passwd" ]	&& echo set network.$interface.password=$passwd >> $tmpfile
	# whether to nego ipv6 within ppp
	if [ -n "$ipv6" ]; then
		echo set network.$interface.ipv6=$ipv6 >> $tmpfile
	else
		echo set network.$interface.ipv6=auto >> $tmpfile
	fi
}

add_pptp() {
	echo set network.$interface.proto=pptp >> $tmpfile
	[ -n "$ifname" ]	&& echo set network.$interface.ifname=$ifname >> $tmpfile
	[ -n "$mtu" ]		&& echo set network.$interface.mtu=$mtu >> $tmpfile
	[ -n "$server" ]	&& echo set network.$interface.server=$server >> $tmpfile
	[ -n "$username" ]	&& echo set network.$interface.username=$username >> $tmpfile
	[ -n "$passwd" ]	&& echo set network.$interface.password=$passwd >> $tmpfile
	# whether to nego ipv6 within ppp
	if [ -n "$ipv6" ]; then
		echo set network.$interface.ipv6=$ipv6 >> $tmpfile
	else
		echo set network.$interface.ipv6=auto >> $tmpfile
	fi
}

add_bridge() {
	echo set network.$interface.type=bridge >> $tmpfile
	[ -n "$ifname" ]	&& echo set network.$interface.ifname=$ifname >> $tmpfile
	[ -n "$ipaddr" ]	&& echo set network.$interface.proto=static >> $tmpfile
	[ -n "$ipaddr" ]	&& echo set network.$interface.ipaddr=$ipaddr >> $tmpfile
	[ -n "$netmask" ]	&& echo set network.$interface.netmask=$netmask >> $tmpfile
	[ -n "$gateway" ]	&& echo set network.$interface.gateway=$gateway >> $tmpfile
}

add_none() {
	echo set network.$interface.proto=none >> $tmpfile
	[ -n "$ifname" ]	&& echo set network.$interface.ifname=$ifname >> $tmpfile
}

help_usage() {
	echo "common parameter:"
	echo "pre_del 	- delete old network setting"
	echo "disabled	- disable network"
	echo "auto		- bring up on boot"
	echo "nocommit	- no commit command"
	echo "restart	- restart network"
	echo ""

	if [ "$proto" = "static" ]; then
		echo "static parameter:"
		echo "ifname		- network device name"
		echo "defaultroute	- use nexthop as system defaultroute"
		echo "mtu		- mtu"
		echo "ipaddr		- network ip address"
		echo "netmask		- network netmask"
		echo "gateway		- network gateway"
		echo "dns[1-4]	- dns"
		echo "ip6addr		- network ip6 address"
		echo "ip6gw		- network ip6 gateway"
		echo "ip6prefix	- public prefix routed to this device for distribution to clients"
		echo "ip6ifaceid	- 'eui64', 'random', fixed value like '::1' or '::1:2'"
		echo ""
		echo "example:"
		echo "pre_del=1 ifname=eth0 ipaddr=172.16.3.200 netmask=255.255.0.0 gateway=172.16.3.1 mtu=1500 dns1=8.8.8.8 /usr/sbin/net_add.sh static wan0"
		echo "pre_del=1 ifname=eth0 ip6addr=2002::100 ip6gw=2002::1 ip6prefix=2002:0:0:1:: dns1=2001:4860:4860::8888 /usr/sbin/net_add.sh static wan0v6"
		echo ""

	elif [ "$proto" = "dhcp" -o "$proto" = "dhcpv6" ]; then
		echo "dhcp/dhcpv6 parameter:"
		echo "defaultroute	- use nexthop as system defaultroute"
		echo "ifname		- network device name"
		echo "mtu		- mtu"
		echo "defaultroute	- use nexthop as system defaultroute"
		echo ""
		echo "example:"
		echo "pre_del=1 ifname=eth0 /usr/sbin/net_add.sh dhcp wan0"
		echo "pre_del=1 ifname=eth0 /usr/sbin/net_add.sh dhcpv6 wan0v6"
		echo ""

	elif [ "$proto" = "pppoe" ]; then
		echo "pppoe parameter:"
		echo "ifname		- network device name"
		echo "mtu		- mtu"
		echo "defaultroute	- use nexthop as system defaultroute"
		echo "username	- pppoe username"
		echo "passwd		- pppoe password"
		echo "ipv6		- nego ipv6 within ppp, possible value: 0, 1, auto(default)"
		echo ""
		echo "example:"
		echo "pre_del=1 ifname=eth0 username=test passwd=12345678 /usr/sbin/net_add.sh pppoe wan0"
		echo ""

	elif [ "$proto" = "pptp" ]; then
		echo "pptp parameter:"
		echo "ifname		- network device name"
		echo "mtu		- mtu"
		echo "server		- pptp server"
		echo "username	- pptp username"
		echo "passwd		- pptp password"
		echo "ipv6		- nego ipv6 within pptp, possible value: 0, 1, auto(default)"
		echo ""
		echo "example:"
		echo "pre_del=1 ifname=eth0 server=your_pptp_server username=test passwd=12345678 /usr/sbin/net_add.sh pptp vpn0"
		echo ""

	elif [ "$proto" = "bridge" ]; then
		echo "bridge parameter:"
		echo "ifname		- network device name"
		echo "ipaddr		- network ip address"
		echo "netmask		- network netmask"
		echo "gateway		- network gateway"
		echo ""
		echo "example:"
		echo "pre_del=1 ifname='eth0.2.0 eth0.3.0 eth0.4.0 eth0.5.0' ipaddr=192.168.1.1 netmask=255.255.255.0 /usr/sbin/net_add.sh bridge lan"
		echo ""
	fi
}
help_short() {
	echo "$0 <proto> <openwrt_inf_name>"
	echo "$0 <proto> - show help"
	echo ""
	echo "available proto: static, dhcp, dhcpv6, pppoe, pptp, bridge"
	echo ""
}

## main #####################################################################

if [ -z "$1" ]; then
	help_short
	exit 1
fi

proto=$1
case $proto in
	static|dhcp|dhcpv6|pppoe|pptp|bridge|none) ;;
	*) help_short; exit 1;;
esac

interface=$2
if [ -z "$interface" ]; then
	help_usage
	exit 0
fi

tmpfile=/var/run/net_add.$interface.$$
echo "" > $tmpfile

[ -n "$pre_del" ]	&& echo del network.$interface > $tmpfile
echo set network.$interface=interface >> $tmpfile
[ -n "$disabled" ]	&& echo set network.$interface.disabled=$disabled >> $tmpfile
[ -n "$auto" ] 		&& echo set network.$interface.auto=$auto >> $tmpfile	# bring up on boot

case $proto in
	static)	add_static;;
	dhcp)	add_dhcp;;
	dhcpv6)	add_dhcpv6;;
	pppoe)	add_pppoe;;
	pptp)	add_pptp;;
	bridge) add_bridge;;
	none)	add_none;;
esac

if [ "$proto" = "bridge" ]; then
	## add interface to firewall zone[0] - lan
	iflist=$(util_uci get firewall.@zone[0].network|cut -d= -f2)
	if ! echo "$iflist"|grep -qw $interface; then
		echo set_list firewall.@zone[0].network=$iflist $interface >> $tmpfile
		echo commit firewall >> $tmpfile
	fi
else
	## disable dhcp server on wan interface
	echo del dhcp.$interface >> $tmpfile
	echo set dhcp.$interface=dhcp >> $tmpfile
	echo set dhcp.$interface.interface=$interface >> $tmpfile
	echo set dhcp.$interface.ignore=1 >> $tmpfile
	## add wan interface to firewall zone[1] (zone wan)
	if [ "$proto" != "none" ] && [ -z "$nonat" ]; then
		iflist=$(util_uci get firewall.@zone[1].network|cut -d= -f2)
		if ! echo "$iflist"|grep -qw $interface; then
			echo set_list firewall.@zone[1].network=$iflist $interface >> $tmpfile
			echo commit firewall >> $tmpfile
		fi
	fi
fi
if [ -z "$nocommit" ] || [ "$nocommit" = "0" ]; then
	echo commit network >> $tmpfile
	echo commit dhcp >> $tmpfile
fi
if [ "$restart" = "1" ]; then
	echo restart >> $tmpfile
fi
/usr/bin/util_uci -f $tmpfile
rm $tmpfile
