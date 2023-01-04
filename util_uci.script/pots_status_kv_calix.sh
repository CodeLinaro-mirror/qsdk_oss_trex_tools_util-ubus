#!/bin/sh

properitary_help() {
	echo "$0 <pots index> <sip_call_status|voip_call_statistics1|voip_call_statistics2|voip_call_statistics3|voip_call_statistics4|clear_error_counters|clear_call_counters>"
}

properitary_status()
{
	ubus call pots $1 "{\"name\": \"pots$1\"}" \
		| jsonfilter -e sip_call_status='@["sip_call_status"]' \
			     -e in_call_attempts='@["in_call_attempts"]' \
			     -e in_call_completions='@["in_call_completions"]' \
			     -e in_call_busy='@["in_call_busy"]' \
			     -e in_call_peer_disconnects='@["in_call_peer_disconnects"]' \
			     -e in_call_ont_disconnects='@["in_call_ont_disconnects"]' \
			     -e out_call_attempts='@["out_call_attempts"]' \
			     -e out_call_completions='@["out_call_completions"]' \
			     -e out_call_busy='@["out_call_busy"]' \
			     -e out_call_peer_disconnects='@["out_call_peer_disconnects"]' \
			     -e out_call_ont_disconnects='@["out_call_ont_disconnects"]' \
			     -e e911_call_attempts='@["e911_call_attempts"]' \
			     -e e911_call_completions='@["e911_call_completions"]' \
			     -e e911_call_busy='@["e911_call_busy"]' \
			     -e e911_call_peer_disconnects='@["e911_call_peer_disconnects"]' \
			     -e e911_call_onhooks='@["e911_call_onhooks"]' \
			     -e vmwi_notify_msgs_waiting='@["vmwi_notify_msgs_waiting"]' \
			     -e vmwi_notify_no_msgs_waiting='@["vmwi_notify_no_msgs_waiting"]' \
			     -e rtp_pkts_sent='@["rtp_pkts_sent"]' \
			     -e rtp_pkts_recv='@["rtp_pkts_recv"]' \
			     -e rtp_null_ip_sent='@["rtp_null_ip_sent"]' \
			     -e rtp_null_ip_recv='@["rtp_null_ip_recv"]' \
			     -e active_call_cntr='@["active_call_cntr"]' \
			     -e recv_errors='@["recv_errors"]' \
			     -e xmit_errors='@["xmit_errors"]' \
			     -e encode_type='@["encode_type"]' \
			     -e packet_size='@["packet_size"]' \
			     -e missing_rtp='@["missing_rtp"]' \
			     -e sequence_err='@["sequence_err"]' \
			     -e drop_outs='@["drop_outs"]' \
			     -e under_runs='@["under_runs"]' \
			     -e listens='@["listens"]' \
			     -e recv_bad_src_ports='@["recv_bad_src_ports"]' \
			     -e recv_comfort_noise_pkts='@["recv_comfort_noise_pkts"]' \
			     -e local_udp_port='@["local_udp_port"]' \
			     -e rem_ip_addr='@["rem_ip_addr"]' \
			     -e rem_udp_port='@["rem_udp_port"]' \
			     -e sec_rem_ip_addr='@["sec_rem_ip_addr"]' \
			     -e sec_rem_udp_port='@["sec_rem_udp_port"]' \
			     -e qos='@["qos"]' \
			     -e ip_line_status='@["ip_line_status"]' \
			     -e active_911_call='@["active_911_call"]' \
			     -e result='@["result"]' \
		| sed -e "s/; export /\n/g" -e "s/;//g" -e "s/^export //" \
		| sed -e "s/='/=/" -e "s/'$//" -e "s/'.$//"
}
