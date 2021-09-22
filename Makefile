STAGING_DIR=$(HOME)/openwrt/staging_dir
#STAGING_DIR=$(HOME)/openwrt_source/openwrt/staging_dir

export STAGING_DIR

CC=$(STAGING_DIR)/toolchain-x86_64_gcc-8.4.0_musl/bin/x86_64-openwrt-linux-musl-gcc
CFLAGS+=-Wall -I$(STAGING_DIR)/target-x86_64_musl/usr/include -I.
LIB=$(STAGING_DIR)/target-x86_64_musl/usr/lib/libubox.a -lubox -lubus -lblobmsg_json -ljson-c -L$(STAGING_DIR)/target-x86_64_musl/usr/lib

#%.o : %.c
#	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

all: util_ubus_example

util_ubus_example: util_ubus.o util_ubus_example.o
	$(CC) $(CFLAGS) -o util_ubus_example util_ubus.o util_ubus_example.o $(LIB)

clean:
	@rm -f util_ubus_example *.o 2>/dev/null

dist: all
	scp util_ubus_example 192.168.91.14:
