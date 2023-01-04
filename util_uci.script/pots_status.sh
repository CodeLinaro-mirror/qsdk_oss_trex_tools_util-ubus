#!/bin/sh

. /usr/share/libubox/jshn.sh

#ME 53
get_hookstate() {
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	hook_state="0" # to call fvcli get hookstate [EP], Onhook: 0, Offhook:1
	json_add_string hook_state "$hook_state"
	json_dump
}

# ME 150
get_sipstatus() {
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	sip_status="0" # to call fvcli get registrationstatus [EP], Non-Registered: 0, Registered: 1, Timeout: 5
	json_add_string sip_status "$sip_status"
	json_dump
}

#ME 141
get_voiplinestatus() {
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	voip_codec_used="0" # to call fvcli get currentcodec [EP], 0: PCMU, 4: G723, 8: PCMA, 18: G729
	voip_voice_server_status="0" # to call fvcli get epregstate [EP], return value 0~7: keep same value, 99~101: map to 0 (None)
	voip_port_session_type="0" # to call fvcli get voipsessiontype [EP]
	voip_call_1_packet_period="20" # to call fvcli get txpacketsize1 [EP]
	voip_call_2_packet_period="20" # to call fvcli get txpacketsize2 [EP]
	voip_call_1_dest_addr="0.0.0.0" # to call fvcli get calldestaddr1 [EP]
	voip_call_2_dest_addr="0.0.0.0" # to call fvcli get calldestaddr2 [EP]
	json_add_string voip_codec_used "$voip_codec_used"
	json_add_string voip_voice_server_status "$voip_voice_server_status"
	json_add_string voip_port_session_type "$voip_port_session_type"
	json_add_string voip_call_1_packet_period "$voip_call_1_packet_period"
	json_add_string voip_call_2_packet_period "$voip_call_2_packet_period"
	json_add_string voip_call_1_dest_addr "$voip_call_1_dest_addr"
	json_add_string voip_call_2_dest_addr "$voip_call_2_dest_addr"
	json_dump
}
