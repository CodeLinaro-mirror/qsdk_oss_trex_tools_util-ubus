#!/bin/sh

#/usr/sbin/pots_config_kv.sh general
#/usr/sbin/pots_config_kv.sh pots0
#/usr/sbin/pots_config_kv.sh pots0 dial_plan

help() {
	echo "$0 <general|pots0|pots1> [dial_plan]"
}

if [ -z "$1" ]; then
	help
	exit 1
fi

if [ x"$2" == x"dial_plan" ]; then
	for i in 0 1 ; do
		pots_name=`ubus call uci get "{\"config\":\"pots\",\"section\":\"dial_plan$i\"}" | jsonfilter -e '@.values.pots'`
		if [ x"$pots_name" == x"$1" ]; then
			ubus call uci get "{\"config\":\"pots\",\"section\":\"dial_plan$i\"}" | jsonfilter -e '@.values.digitmap[@]'
			break
		fi
	done
else
	ubus call uci get "{\"config\":\"pots\",\"section\":\"$1\"}" \
		| jsonfilter -e sip_mode='@.values.sip_mode' \
			     -e administrative_state='@.values.administrative_state' \
			     -e impedance='@.values.impedance' \
			     -e rxgain='@.values.rxgain' \
			     -e txgain='@.values.txgain' \
			     -e user='@.values.user' \
			     -e display_name='@.values.display_name' \
			     -e auth_user='@.values.auth_user' \
			     -e auth_password='@.values.auth_password' \
			     -e registrar='@.values.registrar' \
			     -e proxy='@.values.proxy' \
			     -e outbound_proxy='@.values.outbound_proxy' \
			     -e primary_dns='@.values.primary_dns' \
			     -e secondary_dns='@.values.secondary_dns' \
			     -e sip_reg_exp_time='@.values.sip_reg_exp_time' \
			     -e sip_rereg_head_start_time='@.values.sip_rereg_head_start_time' \
			     -e domain='@.values.domain' \
			     -e tcpudp_port='@.values.tcpudp_port' \
			     -e tcpudp_protocol='@.values.tcpudp_protocol' \
			     -e tcpudp_tos='@.values.tcpudp_tos' \
			     -e iphost_devname='@.values.iphost_devname' \
			     -e iphost_addr='@.values.iphost_addr' \
			     -e dial_plan_table_max_size='@.values.dial_plan_table_max_size' \
			     -e dial_critical_timeout='@.values.dial_critical_timeout' \
			     -e dial_partial_timeout='@.values.dial_partial_timeout' \
			     -e voicemail_server='@.values.voicemail_server' \
			     -e sub_exp_time='@.values.sub_exp_time' \
			     -e release_timer='@.values.release_timer' \
			     -e roh_timer='@.values.roh_timer' \
			     -e cid_calling_number='@.values.cid_calling_number' \
			     -e cid_calling_name='@.values.cid_calling_name' \
			     -e cid_blocking='@.values.cid_blocking' \
			     -e cid_anonymous_blocking='@.values.cid_anonymous_blocking' \
			     -e call_waiting='@.values.call_waiting' \
			     -e call_waiting_cid='@.values.call_waiting_cid' \
			     -e call_3way='@.values.call_3way' \
			     -e call_transfer='@.values.call_transfer' \
			     -e call_do_not_disturb='@.values.call_do_not_disturb' \
			     -e flash_on_emergency_service_call='@.values.flash_on_emergency_service_call' \
			     -e mwi_special_dial_tone='@.values.mwi_special_dial_tone' \
			     -e mwi_visual_indication='@.values.mwi_visual_indication' \
			     -e direct_connect='@.values.direct_connect' \
			     -e direct_connect_uri='@.values.direct_connect_uri' \
			     -e direct_connect_dial_tone_delay_option='@.values.direct_connect_dial_tone_delay_option' \
			     -e direct_connect_dial_tone_delay_time='@.values.direct_connect_dial_tone_delay_time' \
			     -e fax_mode='@.values.fax_mode' \
			     -e oob_dtmf='@.values.oob_dtmf' \
			     -e codec_1='@.values.codec_1' \
			     -e pkt_period_1='@.values.pkt_period_1' \
			     -e silence_suppression_1='@.values.silence_suppression_1' \
			     -e codec_2='@.values.codec_2' \
			     -e pkt_period_2='@.values.pkt_period_2' \
			     -e silence_suppression_2='@.values.silence_suppression_2' \
			     -e codec_3='@.values.codec_3' \
			     -e pkt_period_3='@.values.pkt_period_3' \
			     -e silence_suppression_3='@.values.silence_suppression_3' \
			     -e codec_4='@.values.codec_4' \
			     -e pkt_period_4='@.values.pkt_period_4' \
			     -e silence_suppression_4='@.values.silence_suppression_4' \
			     -e rtp_local_port_min='@.values.rtp_local_port_min' \
			     -e rtp_local_port_max='@.values.rtp_local_port_max' \
			     -e rtp_dscp='@.values.rtp_dscp' \
			     -e jitter_target='@.values.jitter_target' \
			     -e jitter_buff_max='@.values.jitter_buff_max' \
			     -e echo_cancel='@.values.echo_cancel' \
			     -e pstn_protocol_variant='@.values.pstn_protocol_variant' \
			     -e hook_flash_min_time='@.values.hook_flash_min_time' \
			     -e hook_flash_max_time='@.values.hook_flash_max_time' \
			     -e ringing_event_224='@.values.ringing_event_224' \
		| sed -e "s/; export /\n/g" -e "s/;//g" -e "s/^export //" \
		| sed -e "s/='/=/" -e "s/'$//" -e "s/'.$//"
	echo ""
fi
