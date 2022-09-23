#!/bin/sh
SCRIPT=$0
echo "">/dev/null

r_omci() {

	[ -z "$1" ] && return 1
	
	local ret_val=`uci -q get omci.global.$1 | sed 's/^[ \t]*//g'`
	
	echo $ret_val
	return 0
}

w_omci() {
	[ -z "$1" -o -z "$2" ]&& return 1
	
	echo set omci.global.$1=$2 >> $tmpfile
	return 0
}

w_system(){

	[ -z "$1" -o -z "$2" ]&& return 1
	
	echo set system.@system[0].$1=$2 >> $tmpfile
	return 0

}

r_system(){

	[ -z "$1" ] && return 1
	
	local ret_val=`uci -q get system.@system[0].$1 | sed 's/^[ \t]*//g'`
	
	echo $ret_val
	return 0

}

r_ntp() {
	[ -z "$1" ] && return 1
	
	local ret_val=`uci -q get system.ntp.$1 | sed 's/^[ \t]*//g'`
	
	echo $ret_val
	return 0
}

r_ntp_all() {	
	local ret_val=`uci -q show system.ntp`
	
	echo $ret_val
	return 0
}

w_ntp() {
	[ -z "$1" -o -z "$2" ]&& return 1
	
	echo set system.ntp.$1=$2 >> $tmpfile
	return 0
}

w_ntp_list() {
	[ -z "$1" -o -z "$2" ]&& return 1
	
	echo set_list system.ntp.$1=$2 >> $tmpfile
	return 0
}

system_restart(){
	/etc/init.d system restart
}

help_short() {
	echo "r_omci|w_omci|r_system|w_system|w_ntp|r_ntp|sys_restart|w_ntp_list"	
}
if [ -z "$1" ]; then
	help_short
	exit 1
fi

proto=$1
case $proto in
	r_omci|w_omci|r_system|w_system|w_ntp|r_ntp|sys_restart|w_ntp_list) ;;
	*) help_short; exit 1;;
esac

tmpfile=/var/run/omci_cfgh.$proto.$$
echo "" > $tmpfile

case $proto in
	r_omci)	r_omci $2;;
	w_omci)	w_omci $2 $3;;	
	r_system) r_system $2;;
	w_system)	w_system $2 $3;;
	w_ntp)	w_ntp $2 $3;;
	r_ntp)	r_ntp $2;;	
	sys_restart) system_restart;;
	w_ntp_list) w_ntp_list $2 $3;;
	*)	add_none;;
esac

if [ $? != "0" ] ; then
	echo $SCRIPT $proto error
	rm -f $tmpfile
	exit 1
fi

if [ "$proto" = "w_omci" ]; then
	echo commit omci >> $tmpfile
	/usr/bin/util_uci -f $tmpfile
fi 

if [ "$proto" = "w_system" -o "$proto" = "w_ntp" -o "$proto" = "w_ntp_list" ]; then
	echo commit system >> $tmpfile
	/usr/bin/util_uci -f $tmpfile
fi 

rm $tmpfile
exit 0
