#!/bin/sh

# variable=xxx /usr/sbin/pots_add.sh general
# variable=xxx /usr/sbin/pots_add.sh pots 0
# variable=xxx /usr/sbin/pots_add.sh pots 1

help() {
	echo "Usage:"
	echo "$0 general"
	echo "$0 pots <instance>"
}

add_general() {
	echo set pots.general=general >> $tmpfile
	[ -n "$sip_mode" ]			&& echo set pots.general.sip_mode=$sip_mode >> $tmpfile
}

add_dial_plan() {
	echo del pots.dial_plan$pots_instance >> $tmpfile
	for i in $(seq 1 $dial_plan_table_max_size); do
		str=dial_plan${i}
		[ ! -z "$(eval echo "\$$str")" ] && digitmap="$digitmap $(eval echo "\$$str")"
	done
	if [ ! -z "$digitmap" ] ; then
		echo set pots.dial_plan$pots_instance=dial_plan >> $tmpfile
		echo set pots.dial_plan$pots_instance.pots=pots$pots_instance >> $tmpfile
		echo set_list pots.dial_plan$pots_instance.digitmap="$digitmap" >> $tmpfile
	fi
}

add_pots() {
	echo del pots.pots$pots_instance >> $tmpfile
	echo set pots.pots$pots_instance=pots >> $tmpfile
	add_dial_plan
	[ -n "$admin" ]				&& echo set pots.pots$pots_instance.administrative_state=$admin >> $tmpfile
	[ -n "$impedance" ]			&& echo set pots.pots$pots_instance.impedance=$impedance >> $tmpfile
	[ -n "$rxgain" ]			&& echo set pots.pots$pots_instance.rxgain=$rxgain >> $tmpfile
	[ -n "$txgain" ]			&& echo set pots.pots$pots_instance.txgain=$txgain >> $tmpfile
	[ ! -z "$user" ]			&& echo set pots.pots$pots_instance.user=$user >> $tmpfile
	[ ! -z "$disp" ]			&& echo set pots.pots$pots_instance.display_name=$disp >> $tmpfile
	[ ! -z "$auth_user" ]			&& echo set pots.pots$pots_instance.auth_user=$auth_user >> $tmpfile
	[ ! -z "$auth_pass" ]			&& echo set pots.pots$pots_instance.auth_password=$auth_pass >> $tmpfile
	[ ! -z "$realm" ]			&& echo set pots.pots$pots_instance.realm=$realm >> $tmpfile
	[ ! -z "$registrar" ]			&& echo set pots.pots$pots_instance.registrar=$registrar >> $tmpfile
	[ ! -z "$proxy" ]			&& echo set pots.pots$pots_instance.proxy=$proxy >> $tmpfile
	[ ! -z "$outbound_proxy" ]		&& echo set pots.pots$pots_instance.outbound_proxy=$outbound_proxy >> $tmpfile
	[ ! -z "$primary_dns" ]			&& echo set pots.pots$pots_instance.primary_dns=$primary_dns >> $tmpfile
	[ ! -z "$secondary_dns" ]		&& echo set pots.pots$pots_instance.secondary_dns=$secondary_dns >> $tmpfile
	[ -n "$sip_reg_exp_time" ]		&& echo set pots.pots$pots_instance.sip_reg_exp_time=$sip_reg_exp_time >> $tmpfile
	[ -n "$sip_rereg_head_start_time" ]	&& echo set pots.pots$pots_instance.sip_rereg_head_start_time=$sip_rereg_head_start_time >> $tmpfile
	[ ! -z "$domain" ]			&& echo set pots.pots$pots_instance.domain=$domain >> $tmpfile
	[ -n "$tcpudp_port" ]			&& echo set pots.pots$pots_instance.tcpudp_port=$tcpudp_port >> $tmpfile
	[ -n "$tcpudp_protocol" ]		&& echo set pots.pots$pots_instance.tcpudp_protocol=$tcpudp_protocol >> $tmpfile
	[ -n "$tcpudp_tos" ]			&& echo set pots.pots$pots_instance.tcpudp_tos=$tcpudp_tos >> $tmpfile
	[ ! -z "$iphost_devname" ]		&& echo set pots.pots$pots_instance.iphost_devname=$iphost_devname >> $tmpfile
	[ ! -z "$iphost_addr_static" ]		&& echo set pots.pots$pots_instance.iphost_addr_static=$iphost_addr_static >> $tmpfile
	[ ! -z "$iphost_addr_dhcp" ]		&& echo set pots.pots$pots_instance.iphost_addr_dhcp=$iphost_addr_dhcp >> $tmpfile
	[ -n "$dial_plan_table_max_size" ]	&& echo set pots.pots$pots_instance.dial_plan_table_max_size=$dial_plan_table_max_size >> $tmpfile
	[ -n "$dial_critical_timeout" ]		&& echo set pots.pots$pots_instance.dial_critical_timeout=$dial_critical_timeout >> $tmpfile
	[ -n "$dial_partial_timeout" ]		&& echo set pots.pots$pots_instance.dial_partial_timeout=$dial_partial_timeout >> $tmpfile
	[ ! -z "$voicemail_server" ]		&& echo set pots.pots$pots_instance.voicemail_server=$voicemail_server >> $tmpfile
	[ -n "$sub_exp_time" ]			&& echo set pots.pots$pots_instance.sub_exp_time=$sub_exp_time >> $tmpfile
	[ -n "$release_timer" ]			&& echo set pots.pots$pots_instance.release_timer=$release_timer >> $tmpfile
	[ -n "$roh_timer" ]			&& echo set pots.pots$pots_instance.roh_timer=$roh_timer >> $tmpfile
	[ -n "$cid_calling_number" ]		&& echo set pots.pots$pots_instance.cid_calling_number=$cid_calling_number >> $tmpfile
	[ -n "$cid_calling_name" ]		&& echo set pots.pots$pots_instance.cid_calling_name=$cid_calling_name >> $tmpfile
	[ -n "$cid_blocking" ]			&& echo set pots.pots$pots_instance.cid_blocking=$cid_blocking >> $tmpfile
	[ -n "$cid_anonymous_blocking" ]	&& echo set pots.pots$pots_instance.cid_anonymous_blocking=$cid_anonymous_blocking >> $tmpfile
	[ -n "$call_waiting" ]			&& echo set pots.pots$pots_instance.call_waiting=$call_waiting >> $tmpfile
	[ -n "$call_waiting_cid" ]		&& echo set pots.pots$pots_instance.call_waiting_cid=$call_waiting_cid >> $tmpfile
	[ -n "$call_3way" ]			&& echo set pots.pots$pots_instance.call_3way=$call_3way >> $tmpfile
	[ -n "$call_transfer" ]			&& echo set pots.pots$pots_instance.call_transfer=$call_transfer >> $tmpfile
	[ -n "$call_do_not_disturb" ]		&& echo set pots.pots$pots_instance.call_do_not_disturb=$call_do_not_disturb >> $tmpfile
	[ -n "$flash_on_emergency_service_call" ] && echo set pots.pots$pots_instance.flash_on_emergency_service_call=$flash_on_emergency_service_call >> $tmpfile
	[ -n "$mwi_special_dial_tone" ]		&& echo set pots.pots$pots_instance.mwi_special_dial_tone=$mwi_special_dial_tone >> $tmpfile
	[ -n "$mwi_visual_indication" ]		&& echo set pots.pots$pots_instance.mwi_visual_indication=$mwi_visual_indication >> $tmpfile
	[ -n "$direct_connect" ]		&& echo set pots.pots$pots_instance.direct_connect=$direct_connect >> $tmpfile
	[ -n "$direct_connect_dial_tone_delay_option" ] && echo set pots.pots$pots_instance.direct_connect_dial_tone_delay_option=$direct_connect_dial_tone_delay >> $tmpfile
	[ -n "$direct_connect_dial_tone_delay_time" ] && echo set pots.pots$pots_instance.direct_connect_dial_tone_delay_time=$direct_connect_dial_tone_delay_time >> $tmpfile
	[ ! -z "$direct_connect_uri" ]		&& echo set pots.pots$pots_instance.direct_connect_uri=$direct_connect_uri >> $tmpfile
	[ -n "$fax_mode" ]			&& echo set pots.pots$pots_instance.fax_mode=$fax_mode >> $tmpfile
	[ -n "$oob_dtmf" ]			&& echo set pots.pots$pots_instance.oob_dtmf=$oob_dtmf >> $tmpfile
	[ ! -z "$codec_1" ]			&& echo set pots.pots$pots_instance.codec_1=$codec_1 >> $tmpfile
	[ ! -z "$pkt_period_1" ]		&& echo set pots.pots$pots_instance.pkt_period_1=$pkt_period_1 >> $tmpfile
	[ ! -z "$silence_suppression_1" ]	&& echo set pots.pots$pots_instance.silence_suppression_1=$silence_suppression_1 >> $tmpfile
	[ ! -z "$codec_2" ]			&& echo set pots.pots$pots_instance.codec_2=$codec_2 >> $tmpfile
	[ ! -z "$pkt_period_2" ]		&& echo set pots.pots$pots_instance.pkt_period_2=$pkt_period_2 >> $tmpfile
	[ ! -z "$silence_suppression_2" ]	&& echo set pots.pots$pots_instance.silence_suppression_2=$silence_suppression_2 >> $tmpfile
	[ ! -z "$codec_3" ]			&& echo set pots.pots$pots_instance.codec_3=$codec_3 >> $tmpfile
	[ ! -z "$pkt_period_3" ]		&& echo set pots.pots$pots_instance.pkt_period_3=$pkt_period_3 >> $tmpfile
	[ ! -z "$silence_suppression_3" ]	&& echo set pots.pots$pots_instance.silence_suppression_3=$silence_suppression_3 >> $tmpfile
	[ ! -z "$codec_4" ]			&& echo set pots.pots$pots_instance.codec_4=$codec_4 >> $tmpfile
	[ ! -z "$pkt_period_4" ]		&& echo set pots.pots$pots_instance.pkt_period_4=$pkt_period_4 >> $tmpfile
	[ ! -z "$silence_suppression_4" ]	&& echo set pots.pots$pots_instance.silence_suppression_4=$silence_suppression_4 >> $tmpfile
	[ -n "$rtp_local_port_min" ]		&& echo set pots.pots$pots_instance.rtp_local_port_min=$rtp_local_port_min >> $tmpfile
	[ -n "$rtp_local_port_max" ]		&& echo set pots.pots$pots_instance.rtp_local_port_max=$rtp_local_port_max >> $tmpfile
	[ -n "$rtp_dscp" ]			&& echo set pots.pots$pots_instance.rtp_dscp=$rtp_dscp >> $tmpfile
	[ -n "$jitter_target" ]			&& echo set pots.pots$pots_instance.jitter_target=$jitter_target >> $tmpfile
	[ -n "$jitter_buff_max" ]		&& echo set pots.pots$pots_instance.jitter_buff_max=$jitter_buff_max >> $tmpfile
	[ -n "$echo_cancel" ]			&& echo set pots.pots$pots_instance.echo_cancel=$echo_cancel >> $tmpfile
	[ -n "$pstn_protocol_variant" ]		&& echo set pots.pots$pots_instance.pstn_protocol_variant=$pstn_protocol_variant >> $tmpfile
	[ -n "$hook_flash_min_time" ]		&& echo set pots.pots$pots_instance.hook_flash_min_time=$hook_flash_min_time >> $tmpfile
	[ -n "$hook_flash_max_time" ]		&& echo set pots.pots$pots_instance.hook_flash_max_time=$hook_flash_max_time >> $tmpfile
	for i in `seq 1 255`; do
		ringing_event=ringing_event_${i}
		[ ! -z "$(eval echo "\$$ringing_event")" ]  && echo set pots.pots$pots_instance.ringing_event_${i}="$(eval echo "\$$ringing_event")" >> $tmpfile
	done
}

## main #####################################################################

if [ -z "$1" ]; then
	help
	exit 1
fi

section_name=$1
pots_instance=$2
if [ "$section_name" == "pots" ] && [ -z "$pots_instance" ]; then
	help
	exit 0
fi

tmpfile=/var/run/pots_add.$pots_instance.$$
echo "" > $tmpfile

case $section_name in
	general) add_general;;
	pots) add_pots;;
	*) help;;
esac

echo commit pots >> $tmpfile
/usr/bin/util_uci -f $tmpfile
rm -f $tmpfile
