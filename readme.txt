
1. Please modify STAGING_DIR=$HOME/openwrt/staging_dir

2. enable debug message 

root@OpenWrt:~# ./util_ubus_example
util_ubus.c:21: util_ubus_client_init(): connected as 70e112a7
util_ubus.c:144: util_ubus_session_login_cb(): sid=04a6caa34aaec81a336b2ffd8eb2d503
util_ubus_example.c:21: main(): ret=0(ok)

util_ubus.c:231: util_ubus_session_validate_cb(): sid=04a6caa34aaec81a336b2ffd8eb2d503, expire time=600
util_ubus_example.c:24: main(): ret=0(ok)

util_ubus.c:39: util_ubus_dump_blobmsg():
{
        "value": [
                "0.openwrt.pool.ntp.org",
                "1.openwrt.pool.ntp.org",
                "2.openwrt.pool.ntp.org",
                "3.openwrt.pool.ntp.org"
        ]
}
util_ubus_example.c:30: main(): ret=0(ok), value=0.openwrt.pool.ntp.org, 1.openwrt.pool.ntp.org, 2.openwrt.pool.ntp.org, 3.openwrt.pool.ntp.org

util_ubus.c:39: util_ubus_dump_blobmsg():
{
        "values": {
                ".anonymous": true,
                ".type": "system",
                ".name": "cfg01e48a",
                "hostname": "OpenWrt",
                "ttylogin": "0",
                "log_size": "64",
                "urandom_seed": "0",
                "zonename": "UTC",
                "log_proto": "udp",
                "conloglevel": "8",
                "cronloglevel": "5",
                "zram_comp_algo": "lzo"
        }
}
util_ubus.c:430: util_ubus_uci_get_cb(): type=2(int8)
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=.type
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=.name
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=hostname
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=ttylogin
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=log_size
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=urandom_seed
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=zonename
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=log_proto
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=conloglevel
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=cronloglevel
util_ubus.c:400: util_ubus_uci_get_cb(): type=2(string) name=zram_comp_algo
util_ubus_example.c:34: main(): ret=0(ok), value=cfg01e48a

util_ubus.c:497: util_ubus_uci_get(): ubus_invoke uci::get cb error -1003(entry_not_found)
util_ubus_example.c:38: main(): ret=-1003(entry_not_found), value=

util_ubus.c:39: util_ubus_dump_blobmsg():
{
        "value": "OpenWrt"
}
util_ubus_example.c:42: main(): ret=0(ok), value=OpenWrt

util_ubus.c:39: util_ubus_dump_blobmsg():
{
        "value": "5"
}
util_ubus_example.c:45: main(): ret=0(ok), value=5

util_ubus.c:497: util_ubus_uci_get(): ubus_invoke uci::get cb error -1003(entry_not_found)
util_ubus_example.c:50: main(): ret=-1003(entry_not_found), value=

util_ubus_example.c:55: main(): ret=0(ok)

util_ubus_example.c:58: main(): ret=0(ok)

util_ubus_example.c:63: main(): ret=0(ok)

util_ubus_example.c:65: main(): ret=0(ok)

util_ubus_example.c:70: main(): ret=0(ok)

{
        "changes": [
                [
                        "set",
                        "cfg01e48a",
                        "hostname",
                        "ucitest1"
                ],
                [
                        "set",
                        "cfg01e48a",
                        "cronloglevel",
                        "1"
                ],
                [
                        "remove",
                        "ntp",
                        "server"
                ],
                [
                        "list-add",
                        "ntp",
                        "server",
                        "1.ucitest.org"
                ],
                [
                        "list-add",
                        "ntp",
                        "server",
                        "11.ucitest.org"
                ],
                [
                        "list-add",
                        "ntp",
                        "server",
                        "111.ucitest.org"
                ]
        ]
}
util_ubus_example.c:76: main(): ret=0(ok)

util_ubus_example.c:82: main(): ret=0(ok)

util_ubus_example.c:85: main(): ret=0(ok)

util_ubus_example.c:88: main(): ret=0(ok)

util_ubus_example.c:94: main(): ret=0(ok)

util_ubus_example.c:97: main(): ret=0(ok)

util_ubus_example.c:104: main(): ret=0(ok)

util_ubus_example.c:107: main(): ret=0(ok)

util_ubus_example.c:109: main(): ret=0(ok)

util_ubus.c:39: util_ubus_dump_blobmsg():
{
        "section": "name1001"
}
util_ubus_example.c:115: main(): ret=0(ok)

util_ubus.c:39: util_ubus_dump_blobmsg():
{
        "section": "name1002"
}
util_ubus_example.c:117: main(): ret=0(ok)

util_ubus.c:39: util_ubus_dump_blobmsg():
{
        "section": "name2001"
}
util_ubus_example.c:119: main(): ret=0(ok)

util_ubus.c:39: util_ubus_dump_blobmsg():
{
        "section": "name2002"
}
util_ubus_example.c:121: main(): ret=0(ok)

util_ubus_example.c:124: main(): ret=0(ok)

util_ubus_example.c:129: main(): ret=0(ok)

util_ubus_example.c:133: main(): ret=0(ok)

util_ubus_example.c:136: main(): ret=0(ok)

util_ubus_example.c:142: main(): ret=0(ok)

util_ubus_example.c:145: main(): ret=0(ok)

root@OpenWrt:~#

