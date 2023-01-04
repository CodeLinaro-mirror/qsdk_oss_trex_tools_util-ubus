#!/bin/sh

if [ -f /usr/sbin/pots_status_kv_calix.sh ]; then
	. /usr/sbin/pots_status_kv_calix.sh
	support_proprietary="1"
fi


help() {
	echo "$0 <pots index> <hook_state|sip_status|voip_line_status>"
	properitary_help
}

if [ -z "$1" ] || [ -z "$2" ]; then
	help
	exit 1
fi

case "$2" in
	"hook_state" | "sip_status" | "voip_line_status")
		ubus call pots $2 "{\"name\": \"pots$1\"}" \
			| jsonfilter -e hook_state='@["hook_state"]' \
				     -e sip_status='@["sip_status"]' \
				     -e voip_codec_used='@["voip_codec_used"]' \
				     -e voip_voice_server_status='@["voip_voice_server_status"]' \
				     -e voip_port_session_type='@["voip_port_session_type"]' \
				     -e voip_call_1_packet_period='@["voip_call_1_packet_period"]' \
				     -e voip_call_2_packet_period='@["voip_call_2_packet_period"]' \
				     -e voip_call_1_dest_addr='@["voip_call_1_dest_addr"]' \
				     -e voip_call_2_dest_addr='@["voip_call_2_dest_addr"]' \
			| sed -e "s/; export /\n/g" -e "s/;//g" -e "s/^export //" \
			| sed -e "s/='/=/" -e "s/'$//" -e "s/'.$//"
		;;

	*)
		if [ x"$support_proprietary" == x"1" ]; then
			properitary_status $2
		fi
		;;
esac
echo ""
