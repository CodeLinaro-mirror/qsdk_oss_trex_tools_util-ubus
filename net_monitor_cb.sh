#!/bin/sh
#
# Copyright (c) 2024, Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: ISC 
#

case $type in
	NEWADDR)	echo "newaddr $ifname $ipaddr";;
	DELADDR)	echo "deladdr $ifname";;
	DELLINK)	echo "dellink $ifname";;
	NEWLINK)	echo "newlink $ifname $link";;	
	*)			echo "error type";;
esac
