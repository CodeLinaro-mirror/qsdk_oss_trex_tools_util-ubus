STAGING_DIR=/home/kevin_tung/openwrt/staging_dir
export STAGING_DIR

CC=$(STAGING_DIR)/toolchain-x86_64_gcc-8.4.0_musl/bin/x86_64-openwrt-linux-musl-gcc
CFLAGS+=-I$(STAGING_DIR)/target-x86_64_musl/usr/include -I.
LIB=$(STAGING_DIR)/target-x86_64_musl/usr/lib/libubox.a -lubox -lubus -lblobmsg_json -ljson-c -L$(STAGING_DIR)/target-x86_64_musl/usr/lib

#%.o : %.c
#	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

all: ubus_server ubus_client 

ubus_server: ubus_server.o count.o
	$(CC) $(CFLAGS) -o ubus_server ubus_server.o count.o $(LIB)

ubus_client: ubus_client.o count.o
	$(CC) $(CFLAGS) -o ubus_client ubus_client.o count.o $(LIB)

clean:
	@rm -f ubus_server ubus_client *.o 2>/dev/null

dist: all
	scp ubus_server ubus_client 192.168.0.13:
	