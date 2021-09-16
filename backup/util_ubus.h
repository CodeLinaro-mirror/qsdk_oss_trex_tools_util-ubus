#ifndef __UTIL_UBUS_H__
#define __UTIL_UBUS_H__

#include <libubox/uloop.h>
#include <libubox/ustream.h>
#include <libubox/utils.h>
#include <libubus.h>
#include <json-c/json.h>
#include <libubox/blobmsg_json.h>

static inline char *util_purename(char *path) { char *delim=rindex(path, '/'); return delim?(delim+1):path; }
#define dbprintf(fmt, args...)		do { fprintf(stderr,"%s:%d: %s(): " fmt, util_purename(__FILE__), __LINE__, __FUNCTION__, ##args); } while (0)

#define UTIL_UBUS_DEBUG_DEFAULT		1
#define UBUS_INVOKE_TIMEOUT_DEFAULT	30
#define HAS_MAIN			1

#define UTIL_UBUS_ERROR_NULL_POINTER			-1001
#define UTIL_UBUS_ERROR_VALUE_BUFFER_TOO_SMALL		-1002
#define UTIL_UBUS_ERROR_ENTRY_NOT_FOUND			-1003
#define UTIL_UBUS_ERROR_BLOB_MSG_NULL			-1004
#define UTIL_UBUS_ERROR_BLOB_MSG_PARSE			-1005
#define UTIL_UBUS_ERROR_BLOB_ATTR_NOT_FOUND		-1006
#define UTIL_UBUS_ERROR_BLOB_ATTR_PARSE			-1007
#define UTIL_UBUS_ERROR_BLOB_MSG_TYPE_UNSUPPORTED	-1008

/* util_ubus.c */
int util_ubus_client_init(void);
void util_ubus_client_finish(void);
char *util_ubus_error_str(int error);
char *util_ubus_blogmsg_type_str(unsigned int type);
int util_ubus_session_login(char *username, char *password, unsigned int session_timeout);
int util_ubus_session_validate(unsigned int *session_expire);
int util_ubus_session_destroy(void);
int util_ubus_uci_get(char *config, char *section, char *option, char *value, unsigned int value_size);
int util_ubus_uci_set(char *config, char *section, char *option, char *value);
int util_ubus_uci_set_list(char *config, char *section, char *option, char *array[], int array_size);
int util_ubus_uci_add_section(char *config, char *type, char *name);
int util_ubus_uci_delete(char *config, char *type, char *section, char *option);
int util_ubus_uci_revert(char *config);
int util_ubus_uci_commit(char *config);
int util_ubus_uci_apply(int rollback_enable, unsigned int auto_rollback_timeout);
int util_ubus_uci_confirm(void);
int util_ubus_uci_rollback(void);
int util_ubus_uci_dump_changes(char *config);

#endif
