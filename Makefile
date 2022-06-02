ifneq ($(OPENWRT_BUILD_PLATFORM), rtl9607c)

STAGING_DIR:=$(HOME)/qcom_openwrt/qsdk_11.0/staging_dir

ifeq ($(wildcard $(STAGING_DIR)/.*),)
STAGING_DIR=$(HOME)/openwrt_source/openwrt/staging_dir
endif

export STAGING_DIR

CC:=$(STAGING_DIR)/toolchain-aarch64_cortex-a53_gcc-5.2.0_musl-1.1.16/bin/aarch64-openwrt-linux-gcc
CFLAGS+=-Wall -fPIC -fpie -I$(STAGING_DIR)/target-aarch64_cortex-a53_musl-1.1.16/usr/include -I.
LIB=-pie -L$(STAGING_DIR)/target-aarch64_cortex-a53_musl-1.1.16/usr/lib -lubox -lblobmsg_json -ljson-c -lubus 

endif

#%.o : %.c
#	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

all: util_uci

util_uci: util_ubus.o util_uci.o
	$(CC) $(CFLAGS) -o util_uci util_ubus.o util_uci.o $(LIB)

clean:
	@rm -f util_uci *.o 2>/dev/null

dist: all
	echo "scp util_uci"
	scp util_uci_arm root@172.20.0.200:/root/util_uci_arm
	scp *.sh root@172.20.0.200:/root/
