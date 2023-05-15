#!/bin/sh
SCRIPT=$0
echo "">/dev/null


# $1: file name
r_protocol_vlan_entry_state() {
	local entry_enable
	local entry_state

	entry_enable=$(ubus call uci get "{'config':'protocol_vlan' }" | jsonfilter \
				-e "@.values.vlan0.enable" \
				-e "@.values.vlan1.enable" \
				-e "@.values.vlan2.enable" \
				-e "@.values.vlan3.enable" \
				-e "@.values.vlan4.enable" \
				-e "@.values.vlan5.enable" \
				-e "@.values.vlan6.enable" \
				-e "@.values.vlan7.enable")

	i=0
	entry_state=0
	for entry_s in $entry_enable;do
		if [ "$entry_s" = "1" ]; then
			entry_state=$(( entry_state | 1 << i ))
		fi
		i=$((i+1))
	done	

	echo -ne "$entry_state" > $1
	return 0
}


# $1: entry index
# $2: file name
r_protocol_vlan_entry() {
	[ -z "$1" -o -z "$2" ] && return 1

	ubus call uci get "{'config':'protocol_vlan' }" | jsonfilter \
	-e "@.values.vlan$1.enable" \
	-e "@.values.vlan$1.oui" \
	-e "@.values.vlan$1.oui" \
	-e "@.values.vlan$1.ethertype" \
	-e "@.values.vlan$1.dmac" \
	-e "@.values.vlan$1.dmac_prefix" \
	-e "@.values.vlan$1.smac" \
	-e "@.values.vlan$1.smac_prefix" \
	-e "@.values.vlan$1.uniport" \
	-e "@.values.vlan$1.v4_protocol" \
	-e "@.values.vlan$1.v6_next_header" \
	-e "@.values.vlan$1.dip" \
	-e "@.values.vlan$1.dip_prefix" \
	-e "@.values.vlan$1.sip" \
	-e "@.values.vlan$1.sip_prefix" \
	-e "@.values.vlan$1.v6dip" \
	-e "@.values.vlan$1.v6dip_prefix" \
	-e "@.values.vlan$1.v6sip" \
	-e "@.values.vlan$1.v6sip_prefix" \
	-e "@.values.vlan$1.dport_start" \
	-e "@.values.vlan$1.dport_end" \
	-e "@.values.vlan$1.sport_start" \
	-e "@.values.vlan$1.sport_end" \
	-e "@.values.vlan$1.vlantag_enable" \
	-e "@.values.vlan$1.vlantag_id" \
	-e "@.values.vlan$1.vlantag_pbit" \
	-e "@.values.vlan$1.vlan_mark" \
	-e "@.values.vlan$1.pbit_mark" > $2

	return 0
}

help_short() {
	echo "r_protocol_vlan_entry|r_protocol_vlan_entry_state"
}

if [ -z "$1" ]; then
	help_short
	exit 1
fi

proto=$1
case $proto in
	r_protocol_vlan_entry|r_protocol_vlan_entry_state) ;;
	*) help_short; exit 1;;
esac

tmpfile=/var/run/protocol_vlan_cfg.$proto.$$
echo "" > $tmpfile

case $proto in
	r_protocol_vlan_entry)		r_protocol_vlan_entry $2 $3;;
	r_protocol_vlan_entry_state)		r_protocol_vlan_entry_state $2;;
	*)			add_none;;
esac

if [ $? != "0" ] ; then
	echo $SCRIPT $proto error
	rm -f $tmpfile
	exit 1
fi

rm $tmpfile
exit 0
