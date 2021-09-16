STAGING_DIR=/home/kevin_tung/openwrt/staging_dir
export STAGING_DIR

CC=$(STAGING_DIR)/toolchain-x86_64_gcc-8.4.0_musl/bin/x86_64-openwrt-linux-musl-gcc
CFLAGS+=-I$(STAGING_DIR)/target-x86_64_musl/usr/include -I.
LIB=$(STAGING_DIR)/target-x86_64_musl/usr/lib/libubox.a -lubox -lubus -lblobmsg_json -ljson-c -L$(STAGING_DIR)/target-x86_64_musl/usr/lib

#%.o : %.c
#	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

all: invoke_server invoke_client notify_server notify_client event_server event_client

invoke_server: invoke_server.o
	$(CC) $(CFLAGS) -o invoke_server invoke_server.o $(LIB)

invoke_client: invoke_client.o
	$(CC) $(CFLAGS) -o invoke_client invoke_client.o $(LIB)

notify_server: notify_server.o
	$(CC) $(CFLAGS) -o notify_server notify_server.o $(LIB)

notify_client: notify_client.o
	$(CC) $(CFLAGS) -o notify_client notify_client.o $(LIB)

event_server: event_server.o
	$(CC) $(CFLAGS) -o event_server event_server.o $(LIB)

event_client: event_client.o
	$(CC) $(CFLAGS) -o event_client event_client.o $(LIB)

clean:
	@rm -f invoke_server invoke_client notify_server notify_client event_server event_client *.o 2>/dev/null

dist: all
	scp invoke_server invoke_client notify_server notify_client event_server event_client 192.168.0.13:
