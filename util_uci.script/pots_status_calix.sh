#!/bin/sh

. /usr/share/libubox/jshn.sh

proprietary_object_list()
{
	json_add_object sip_call_status
	json_add_string name "pots name"
	json_close_object
	json_add_object voip_call_statistics1
	json_add_string name "pots name"
	json_close_object
	json_add_object voip_call_statistics2
	json_add_string name "pots name"
	json_close_object
	json_add_object voip_call_statistics3
	json_add_string name "pots name"
	json_close_object
	json_add_object voip_call_statistics4
	json_add_string name "pots name"
	json_close_object
	json_add_object clear_error_counters
	json_add_string name "pots name"
	json_close_object
	json_add_object clear_call_counters
	json_add_string name "pots name"
	json_close_object
}

#parm 1: functions name
#parm 2: pots name
proprietary_call()
{
	case "$1" in
		sip_call_status)
			get_sipcallstatus $2 #ME 244 PotsUniExtension
			;;

		voip_call_statistics1)
			get_voipcallstatistics1 $2 #ME 65280 MeClassCalixVoIPCallStatistics
			;;

		voip_call_statistics2)
			get_voipcallstatistics2 $2 #ME 65281 MeClassCalixVoIPCallStatisticsExt2
			;;

		voip_call_statistics3)
			get_voipcallstatistics3 $2 #ME 65282 CalixVoipCallStatsExt3
			;;

		voip_call_statistics4)
			get_voipcallstatistics4 $2 #ME 65283 CalixVoipCallStatsExt4
			;;

		clear_error_counters)
			clear_error_counters $2 #ME 65283 ClrErrorCntrs
			;;

		clear_call_counters)
			clear_call_counters $2 #ME 65283 ClrCallCntrs
			;;
	esac
}


#ME 244 PotsUniExtension - Calix
get_sipcallstatus() {
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	sip_call_status="1" # to call fvcli get eplinestate [EP]
	json_add_string sip_call_status "$sip_call_status"
	json_dump
}

#ME 65280 MeClassCalixVoIPCallStatistics - Calix
get_voipcallstatistics1() {
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	in_call_attempts="0" # to call fvcli get incallattemptstats [EP]
	json_add_string in_call_attempts "$in_call_attempts"
	in_call_completions="0" # to call fvcli get incallcompletestats [EP]
	json_add_string in_call_completions "$in_call_completions"
	in_call_busy="0" # to call fvcli get incallrejectstats [EP]
	json_add_string in_call_busy "$in_call_busy"
	in_call_peer_disconnects="0" # to call fvcli get incallremotedisconnectstats [EP]
	json_add_string in_call_peer_disconnects "$in_call_peer_disconnects"
	in_call_ont_disconnects="0" # to call fvcli get incalllocaldisconnectstats [EP]
	json_add_string in_call_ont_disconnects "$in_call_ont_disconnects"
	out_call_attempts="0" # to call fvcli get outcallattemptstats [EP]
	json_add_string out_call_attempts "$out_call_attempts"
	out_call_completions="0" # to call fvcli get outcallcompletestats [EP]
	json_add_string out_call_completions "$out_call_completions"
	out_call_busy="0" # to call fvcli get outcallrejectstats [EP]
	json_add_string out_call_busy "$out_call_busy"
	json_dump
}

#ME 65281 MeClassCalixVoIPCallStatisticsExt2 - Calix
get_voipcallstatistics2() {
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	out_call_peer_disconnects="0" # to call fvcli get outcallremotedisconnectstats [EP]
	json_add_string out_call_peer_disconnects "$out_call_peer_disconnects"
	out_call_ont_disconnects="0" # to call fvcli get outcalllocaldisconnectstats [EP]
	json_add_string out_call_ont_disconnects "$out_call_ont_disconnects"
	e911_call_attempts="0" # to call fvcli get emergencycallattemptstats [EP]
	json_add_string e911_call_attempts "$e911_call_attempts"
	e911_call_completions="0" # to call fvcli get emergencycallcompletestats [EP]
	json_add_string e911_call_completions "$e911_call_completions"
	e911_call_busy="0" # to call fvcli get emergencycallrejectstats [EP]
	json_add_string e911_call_busy "$e911_call_busy"
	e911_call_peer_disconnects="0" # to call fvcli get emergencycallremotedisconnectstats [EP]
	json_add_string e911_call_peer_disconnects "$e911_call_peer_disconnects"
	e911_call_onhooks="0" # to call fvcli get emergencycalllonhookstats [EP]
	json_add_string e911_call_onhooks "$e911_call_onhooks"
	vmwi_notify_msgs_waiting="0" # to call fvcli get messagewaitingyesstats [EP]
	json_add_string vmwi_notify_msgs_waiting "$vmwi_notify_msgs_waiting"
	vmwi_notify_no_msgs_waiting="0" # to call fvcli get messagewaitingnostats [EP]
	json_add_string vmwi_notify_no_msgs_waiting "$vmwi_notify_no_msgs_waiting"
	rtp_pkts_sent="0" # to call fvcli get rtpstatsall [EP] | grep "Sent Pkts:"
	json_add_string rtp_pkts_sent "$rtp_pkts_sent"
	rtp_pkts_recv="0" # to call fvcli get rtpstatsall [EP] | grep "Recv Pkts:"
	json_add_string rtp_pkts_recv "$rtp_pkts_recv"
	rtp_null_ip_sent="0" # to call fvcli get rtpstatsall [EP] | grep "Sent Null Pkts:"
	json_add_string rtp_null_ip_sent "$rtp_null_ip_sent"
	rtp_null_ip_recv="0" # to call fvcli get rtpstatsall [EP] | grep "Recv Null Pkts:"
	json_add_string rtp_null_ip_recv "$rtp_null_ip_recv"
	active_call_cntr="0" # to call fvcli get totalcallduration [EP] | active_call_cntr = duration / 100
	json_add_string active_call_cntr "$active_call_cntr"
	json_dump
}

#ME 65282 CalixVoipCallStatsExt3 - Calix
get_voipcallstatistics3() {
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	recv_errors="0" # to call fvcli get rtpstatsall [EP] | grep "Recv Error Pkts:"
	json_add_string recv_errors "$recv_errors"
	xmit_errors="0" # to call fvcli get rtpstatsall [EP] | grep "Sent Error Pkts:"
	json_add_string xmit_errors "$xmit_errors"
	encode_type="0" # to call fvcli get rtpstatsall [EP] | grep "Last Sent Payload Type:"
	json_add_string encode_type "$encode_type"
	packet_size="0" # to call fvcli get rtpstatsall [EP] | grep "Last Recv Samples:"
	json_add_string packet_size "$packet_size"
	missing_rtp="0" # to call fvcli get rtpstatsall [EP] | grep "Lost Pkts:" + "Sequence Error Pkts:"+ "Under Runs Pkts"
	json_add_string missing_rtp "$missing_rtp"
	sequence_err="0" # to call fvcli get rtpstatsall [EP] | grep "Sequence Error Pkts:"
	json_add_string sequence_err "$sequence_err"
	drop_outs="0" # to call fvcli get rtpstatsall [EP] | grep "Lost Pkts:"
	json_add_string drop_outs "$drop_outs"
	under_runs="0" # to call fvcli get rtpstatsall [EP] | grep "Under Runs Pkts:"
	json_add_string under_runs "$under_runs"
	listens="0" # to call fvcli get rtpstatsall [EP] | grep "Recv Listen Count:"
	json_add_string listens "$listens"
	recv_bad_src_ports="0" # always 0
	json_add_string recv_bad_src_ports "$recv_bad_src_ports"
	recv_comfort_noise_pkts="0" # to call fvcli get rtpstatsall [EP] | grep "SID Pkts:"
	json_add_string recv_comfort_noise_pkts "$recv_comfort_noise_pkts"
	json_dump
}

#ME 65283 CalixVoipCallStatsExt4 - Calix
get_voipcallstatistics4() {
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	local_udp_port="0" # to call fvcli get localmediaport1 [EP]
	json_add_string local_udp_port "$local_udp_port"
	rem_ip_addr="0" # to call fvcli get remotemediaaddr1 [EP]
	json_add_string rem_ip_addr "$rem_ip_addr"
	rem_udp_port="0" # to call fvcli get remotemediaport1 [EP]
	json_add_string rem_udp_port "$rem_udp_port"
	sec_rem_ip_addr="0" # to call fvcli get  remotemediaaddr2 [EP]
	json_add_string sec_rem_ip_addr "$sec_rem_ip_addr"
	sec_rem_udp_port="0" # to call fvcli get remotemediaport2 [EP]
	json_add_string sec_rem_udp_port "$sec_rem_udp_port"
	qos="0" # to call fvcli get mediatos
	json_add_string qos "$qos"
	ip_line_status="0" # to call fvcli ...
	json_add_string ip_line_status "$ip_line_status"
	active_911_call="0" # to call fvcli get emergencycallstate [EP]
	json_add_string active_911_call "$active_911_call"
	json_dump
}

#ME 65283 ClrErrorCntrs - Calix
clear_error_counters(){
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	result="ok" # to call fvcli -p set callstatsclear [EP] 0x003f
	json_add_string result "$result"
	json_dump
}

#ME 65283 ClrCallCntrs - Calix
clear_call_counters(){
	pots_name=$1
	pots_index=$(echo "$pots_name" | sed 's/pots/ /g'| awk '{print $1}')
	json_init
	result="ok" # to call fvcli -p set callstatsclear [EP] 0x003f
	json_add_string result "$result"
	json_dump
}
