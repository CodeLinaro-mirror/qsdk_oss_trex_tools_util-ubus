#!/bin/sh

# common parameter:
# pre_del 	- delete old network setting
# interface   	- network section name
# disabled	- disable network
# auto		- bring up on boot

# static parameter:
# ifname	- network device name
# defaultroute	- use nexthop as system defaultroute
# mtu		- mtu
# ipaddr	- network ip address
# netmask	- network netmask
# gateway	- network gateway
# dns[1-4]	- dns
# ip6addr	- network ip6 address
# ip6gw		- network ip6 gateway
# ip6prefix	- public prefix routed to this device for distribution to clients
# ip6ifaceid	- 'eui64', 'random', fixed value like '::1' or '::1:2'

# dhcp/dhcpv6 parameter:
# defaultroute	- use nexthop as system defaultroute
# ifname	- network device name
# mtu		- mtu
# defaultroute	- use nexthop as system defaultroute

# pppoe parameter :
# ifname	- network device name
# mtu		- mtu
# defaultroute	- use nexthop as system defaultroute
# username	- pppoe username
# passwd	- pppoe password
# ipv6		- nego ipv6 within ppp, possible value: 0, 1, auto(default)

# pptp parameter :
# ifname	- network device name
# mtu		- mtu
# server	- pptp server
# username	- pptp username
# passwd	- pptp password
# ipv6		- nego ipv6 within pptp, possible value: 0, 1, auto(default)

# bridge parameter:
# pre_del	- delete old network setting
# interface	- network section name
# disabled	- disable network
# auto		- bring up on boot
# ifname	- network device name
# ipaddr	- network ip address
# netmask	- network netmask
# gateway	- network gateway

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
		echo "set network.$interface.dns='${str# }'" >> $tmpfile
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

## main #####################################################################

if [ -z "$2" ]; then
	echo "$0 <proto> <openwrt_inf_name>"
	echo "ps: proto supported: static, dhcp, dhcpv6, pppoe, pptp, bridge"
	echo ""
	echo "example:"
	echo "pre_del=1 ifname=eth0 ipaddr=172.16.3.200 netmask=255.255.0.0 gateway=172.16.3.1 mtu=1500 dns1=8.8.8.8 /usr/sbin/net_add.sh static wan0"
	echo "pre_del=1 ifname=eth0 ip6addr=2002::100 ip6gw=2002::1 ip6prefix=2002:0:0:1:: dns1=2001:4860:4860::8888 /usr/sbin/net_add.sh static wan0v6"
	echo "pre_del=1 ifname=eth0 /usr/sbin/net_add.sh dhcp wan0"
	echo "pre_del=1 ifname=eth0 /usr/sbin/net_add.sh dhcpv6 wan0v6"
	echo "pre_del=1 ifname=eth0 username=test passwd=12345678 /usr/sbin/net_add.sh pppoe wan0"
	echo "pre_del=1 ifname=eth0 server=your_pptp_server username=test passwd=12345678 /usr/sbin/net_add.sh pptp vpn0"
	echo "pre_del=1 ifname='eth0.2.0 eth0.3.0 eth0.4.0 eth0.5.0' ipaddr=192.168.1.1 netmask=255.255.255.0 /usr/sbin/net_add.sh bridge lan"
	exit 1
fi

proto=$1
interface=$2
case $proto in
	static|dhcp|dhcpv6|pppoe|pptp) ;;
	bridge) ;;
	*) echo "invalid proto $proto"; exit 1;;
esac

tmpfile=/var/run/net_add.$interface.$$
echo "" > $tmpfile

[ -n "$pre_del" ]	&& echo del network.$interface > $tmpfile
echo set network.$interface=interface >> $tmpfile
[ -n "$disabled" ]	&& echo set network.$interface.disable=$disabled >> $tmpfile
[ -n "$auto" ] 		&& echo set network.$interface.auto=$auto >> $tmpfile	# bring up on boot

case $proto in
	static)	add_static;;
	dhcp)	add_dhcp;;
	dhcpv6)	add_dhcpv6;;
	pppoe)	add_pppoe;;
	pptp)	add_pptp;;
	bridge) add_bridge;;
esac

if [ "$proto" = "bridge" ]; then
	## add interface to firewall zone[0] - lan
	iflist=$(util_uci get firewall.@zone[0].network|cut -d= -f2)
	if ! echo "$iflist"|grep -qw $interface; then
		echo set_list firewall.@zone[0].network=$iflist $interface >> $tmpfile
		echo commit firewall >> $tmpfile
	fi
else
	## disable dhcp server on interface
	echo del dhcp.$interface >> $tmpfile
	echo set dhcp.$interface=dhcp >> $tmpfile
	echo set dhcp.$interface.interface=$interface >> $tmpfile
	echo set dhcp.$interface.ignore=1 >> $tmpfile
	## add interface to firewall zone[1] - wan
	iflist=$(util_uci get firewall.@zone[1].network|cut -d= -f2)
	if ! echo "$iflist"|grep -qw $interface; then
		echo set_list firewall.@zone[1].network=$iflist $interface >> $tmpfile
		echo commit firewall >> $tmpfile
	fi
fi
echo commit network >> $tmpfile
echo commit dhcp >> $tmpfile
#echo restart >> $tmpfile
/usr/bin/util_uci -f $tmpfile
rm $tmpfile
