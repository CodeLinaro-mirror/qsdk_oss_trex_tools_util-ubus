#include <stdio.h>
#include "util_ubus.h"

static int util_ubus_debug = UTIL_UBUS_DEBUG_DEFAULT;
static int ubus_invoke_timeout = UBUS_INVOKE_TIMEOUT_DEFAULT;
static struct ubus_context *ubus_ctx = NULL;
static char rpc_session_id[129];

// common routines //////////////////////////////////////////////////////////////////////////////////////////
int
util_ubus_client_init(void)
{
	char *path = NULL;	// ipc_path: unix domain socket filename, NULL means default /var/run/ubus.sock
	//uloop_init();
	ubus_ctx = ubus_connect(path);
	if (!ubus_ctx) {
		dbprintf("ubus connect failed\n");
		return -1;
	}
	if (util_ubus_debug)
		dbprintf("connected as %08x\n", ubus_ctx->local_id);

	return 0;
}

void
util_ubus_client_finish(void)
{
	if (ubus_ctx)
		ubus_free(ubus_ctx);
	//uloop_done();
}

static void
util_ubus_dump_blobmsg(struct blob_attr *msg)
{
	static bool simple_output = false;
	char *str= blobmsg_format_json_indent(msg, true, simple_output ? -1 : 0);
	dbprintf("\n%s\n", str);
	free(str);
}

char *
util_ubus_error_str(int error)
{
	switch (error) {
		// ubus system error		
		case UBUS_STATUS_OK:			return "ok";
		case UBUS_STATUS_INVALID_COMMAND:	return "invalid cmd";
		case UBUS_STATUS_INVALID_ARGUMENT:	return "invalid arg";
		case UBUS_STATUS_METHOD_NOT_FOUND:	return "method not found";
		case UBUS_STATUS_NOT_FOUND:		return "not found";
		case UBUS_STATUS_NO_DATA:		return "no data";
		case UBUS_STATUS_PERMISSION_DENIED:	return "permission denied";
		case UBUS_STATUS_TIMEOUT:		return "timeout";
		case UBUS_STATUS_NOT_SUPPORTED:		return "not supported";
		case UBUS_STATUS_UNKNOWN_ERROR:		return "unknown err";
		case UBUS_STATUS_CONNECTION_FAILED:	return "connection failed";
		// util_ubus_cb_error
		case UTIL_UBUS_ERROR_NULL_POINTER:		return "null_pointer";
		case UTIL_UBUS_ERROR_VALUE_BUFFER_TOO_SMALL:	return "value_buffer_too_small";
		case UTIL_UBUS_ERROR_ENTRY_NOT_FOUND:		return "entry_not_found";
		case UTIL_UBUS_ERROR_BLOB_MSG_NULL:		return "blob_msg_null";
		case UTIL_UBUS_ERROR_BLOB_MSG_PARSE:		return "blob_msg_parse_error";
		case UTIL_UBUS_ERROR_BLOB_ATTR_NOT_FOUND:	return "blob_attr_not_found";
		case UTIL_UBUS_ERROR_BLOB_ATTR_PARSE:		return "blob_attr_parse_error";	
		case UTIL_UBUS_ERROR_BLOB_MSG_TYPE_UNSUPPORTED:	return "blob_msg_type_unsupported";
	}
	return "?";
}

char *
util_ubus_blogmsg_type_str(unsigned int type)
{
	switch (type) {
		case BLOBMSG_TYPE_UNSPEC:       return "unspec";
		case BLOBMSG_TYPE_ARRAY:	return "array";
		case BLOBMSG_TYPE_TABLE:	return "table";
		case BLOBMSG_TYPE_STRING:       return "string";
		case BLOBMSG_TYPE_INT64:	return "int64";
		case BLOBMSG_TYPE_INT32:	return "int32";
		case BLOBMSG_TYPE_INT16:	return "int16";
		case BLOBMSG_TYPE_INT8:		return "int8";
	}
	return "?";
}

// session login /////////////////////////////////////////////////////////////////////////////////////////

enum {
	SESSION_LOGIN_SID,
	SESSION_LOGIN_TIMEOUT,
	SESSION_LOGIN_EXPIRES,
	SESSION_LOGIN_ACLS,
	SESSION_LOGIN_DATA,
	__SESSION_LOGIN_MAX,
};
static const struct blobmsg_policy 
session_login_reply_policy[__SESSION_LOGIN_MAX] = {
	[SESSION_LOGIN_SID] = { .name = "ubus_rpc_session", .type = BLOBMSG_TYPE_STRING },
	[SESSION_LOGIN_TIMEOUT] = { .name = "timeout", .type = BLOBMSG_TYPE_INT32 },
	[SESSION_LOGIN_EXPIRES] = { .name = "expires", .type = BLOBMSG_TYPE_INT32 },
	[SESSION_LOGIN_ACLS] = { .name = "acls", .type = BLOBMSG_TYPE_TABLE },
	[SESSION_LOGIN_DATA] = { .name = "data", .type = BLOBMSG_TYPE_TABLE },
};

struct util_ubus_session_login_priv_t {
	char sid[129];
	int ret;
};

static void
util_ubus_session_login_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	struct util_ubus_session_login_priv_t *priv = req->priv;
	struct blob_attr *tb[__SESSION_LOGIN_MAX];
	char *sid;
	int ret;

	if (!msg) {
		priv->ret = UTIL_UBUS_ERROR_BLOB_MSG_NULL;
		return;
	}
	//if (util_ubus_debug)
	//	util_ubus_dump_blobmsg(msg);

	if ((ret = blobmsg_parse(session_login_reply_policy, __SESSION_LOGIN_MAX, tb, blobmsg_data(msg), blobmsg_data_len(msg))) != 0) {
		dbprintf("blobmsg_parse uci error %d\n", ret);
		priv->ret = UTIL_UBUS_ERROR_BLOB_MSG_PARSE;
		return;
	}
	if (!tb[SESSION_LOGIN_SID]) { // blob_attr exist?
		util_ubus_dump_blobmsg(msg);
		priv->ret = UTIL_UBUS_ERROR_BLOB_ATTR_NOT_FOUND;
		return;
	}
	if ((sid = blobmsg_get_string(tb[SESSION_LOGIN_SID])) == NULL) {
		priv->ret = UTIL_UBUS_ERROR_BLOB_ATTR_PARSE;
		return;
	}
	strncpy(priv->sid, sid, 128);	// we ensure priv->sid[129] is enough for sid(64byte)
	priv->ret = 0;
	if (util_ubus_debug)
		dbprintf("sid=%s\n", sid);
}

// if session_timeout is 0, caller has to call util_ubus_destroy to clean up session
// if session_timeout n > 0, session would be disabled if session is idle for n seconds
int
util_ubus_session_login(char *username, char *password, unsigned int session_timeout)
{
	unsigned int ubus_path_id;
	struct blob_buf b;
	int ret;
	struct util_ubus_session_login_priv_t priv;

	if (!username || !password)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "username",  username);
	blobmsg_add_string(&b, "password",  password);
	blobmsg_add_u32(&b, "timeout",  session_timeout);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "session", &ubus_path_id)) != 0) {
		dbprintf("lookup 'session' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	memset(&priv, 0, sizeof(priv));
	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "login", b.head, util_ubus_session_login_cb, &priv, ubus_invoke_timeout * 1000)) != 0) {
		dbprintf("ubus_invoke session::login error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}
	blob_buf_free(&b);

	rpc_session_id[0] = 0;
	if (priv.ret <0) {
		dbprintf("ubus_invoke session::login cb error %d(%s)\n", priv.ret, util_ubus_error_str(priv.ret));
		return priv.ret;
	}
	strncpy(rpc_session_id, priv.sid, 128);
	return 0;
}	

// session validate /////////////////////////////////////////////////////////////////////////////////

struct util_ubus_session_validate_priv_t {
	unsigned int expire;
	int ret;
};

static void
util_ubus_session_validate_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	struct util_ubus_session_validate_priv_t *priv = req->priv;
	struct blob_attr *tb[__SESSION_LOGIN_MAX];
	char *sid;
	int ret;

	if (!msg) {
		priv->ret = UTIL_UBUS_ERROR_BLOB_MSG_NULL;
		return;
	}
	//if (util_ubus_debug)
	//	util_ubus_dump_blobmsg(msg);

	if ((ret = blobmsg_parse(session_login_reply_policy, __SESSION_LOGIN_MAX, tb, blobmsg_data(msg), blobmsg_data_len(msg))) != 0) {
		dbprintf("blobmsg_parse uci error %d\n", ret);
		priv->ret = UTIL_UBUS_ERROR_BLOB_MSG_PARSE;
		return;
	}
	if (!tb[SESSION_LOGIN_SID] || !tb[SESSION_LOGIN_EXPIRES]) { // blob_attr exists?
		util_ubus_dump_blobmsg(msg);
		priv->ret = UTIL_UBUS_ERROR_BLOB_ATTR_NOT_FOUND;
		return;
	}
	if ((sid = blobmsg_get_string(tb[SESSION_LOGIN_SID])) == NULL) {
		priv->ret = UTIL_UBUS_ERROR_BLOB_ATTR_PARSE;
		return;
	}
	priv->expire = blobmsg_get_u32(tb[SESSION_LOGIN_EXPIRES]);
	priv->ret = 0;
	if (util_ubus_debug)
		dbprintf("sid=%s, expire time=%u\n", sid, priv->expire);
}

int
util_ubus_session_validate(unsigned int *session_expire)
{
	unsigned int ubus_path_id;
	struct blob_buf b;
	int ret;
	struct util_ubus_session_validate_priv_t priv = { .expire = 0, .ret = UTIL_UBUS_ERROR_ENTRY_NOT_FOUND };

	if (!session_expire)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "session", &ubus_path_id)) != 0) {
		dbprintf("lookup 'session' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "list", b.head, util_ubus_session_validate_cb, &priv, ubus_invoke_timeout * 1000)) != 0) {
		dbprintf("ubus_invoke session::list error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}
	blob_buf_free(&b);
	
	*session_expire = 0;
	if (priv.ret <0) {
		dbprintf("ubus_invoke session::validate cb error %d(%s)\n", priv.ret, util_ubus_error_str(priv.ret));
		return priv.ret;
	}
	*session_expire = priv.expire;
	return 0;
}

// session destroy /////////////////////////////////////////////////////////////////////////////////

static void
util_ubus_session_destroy_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (!msg)
		return;
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);
}
int
util_ubus_session_destroy(void)
{
	unsigned int ubus_path_id;
	struct blob_buf b;
	int ret;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "session", &ubus_path_id)) != 0) {
		dbprintf("lookup 'session' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}
	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "destroy", b.head, util_ubus_session_destroy_cb, NULL, ubus_invoke_timeout * 1000)) != 0) {
		dbprintf("ubus_invoke session::destroy error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}
	blob_buf_free(&b);

	rpc_session_id[0] = 0;
	return 0;
}

// uci get /////////////////////////////////////////////////////////////////////////////////////////

struct util_ubus_uci_get_priv_t {
	unsigned int value_size;
	char *value;
	int ret;
};
static void
util_ubus_uci_get_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	struct util_ubus_uci_get_priv_t *priv = req->priv;
	char *value;
	struct blob_attr *cur;
	int rem, found = 0;

	if (!msg) {
		priv->ret = UTIL_UBUS_ERROR_BLOB_MSG_NULL;
		return;
	}
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);

	blobmsg_for_each_attr(cur, msg, rem) {
		unsigned int type = blobmsg_type(cur);

		if (type == BLOBMSG_TYPE_STRING) {
			if ((value = blobmsg_get_string(cur)) == NULL) {
				priv->ret = UTIL_UBUS_ERROR_BLOB_ATTR_PARSE;
				return;
			}			
			strncat(priv->value, value, priv->value_size-1);
			found++;

		} else if (type == BLOBMSG_TYPE_ARRAY) {
			struct blob_attr *_cur;
			int _rem;
			blobmsg_for_each_attr(_cur, cur, _rem) {
				unsigned int _type = blobmsg_type(_cur);
				if (_type == BLOBMSG_TYPE_STRING) {
					int len;
					if ((value = blobmsg_get_string(_cur)) == NULL) {
						priv->ret = UTIL_UBUS_ERROR_BLOB_ATTR_PARSE;
						continue;
					}
					if ((len = strlen(priv->value)) >0) {
						if (priv->value_size-1-len <= 2) {
							priv->ret = UTIL_UBUS_ERROR_VALUE_BUFFER_TOO_SMALL;
							return;
						}
						strncat(priv->value, ", " , priv->value_size-1-len);
						len+=2;
					}
					if (priv->value_size-1-len < strlen(value)) {
						priv->ret = UTIL_UBUS_ERROR_VALUE_BUFFER_TOO_SMALL;
						return;
					}
					strncat(priv->value, value, priv->value_size-1-len);
					found++;
				} else {
					if (util_ubus_debug)
						dbprintf("2nd layer: unsupported  blobmsg_type %u(%s)\n", _type, util_ubus_blogmsg_type_str(_type));
					priv->ret = UTIL_UBUS_ERROR_BLOB_MSG_TYPE_UNSUPPORTED;
				}
			}
				
		} else {
			if (util_ubus_debug)
				dbprintf("1st layer: unsupported blobmsg_type %u(%s)\n", type, util_ubus_blogmsg_type_str(type));
			priv->ret = UTIL_UBUS_ERROR_BLOB_MSG_TYPE_UNSUPPORTED;
		}
	}

	if (found >0)
		priv->ret = 0;
	if (found == 0 && priv->ret == 0)
		priv->ret = UTIL_UBUS_ERROR_ENTRY_NOT_FOUND;
}
// ubus call uci get '{"config":"network2", "section":"wan", "option":"ifname", "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
int
util_ubus_uci_get(char *config, char *section, char *option, char *value, unsigned int value_size)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;
	struct util_ubus_uci_get_priv_t priv = { .value_size = value_size, .value = value, .ret = UTIL_UBUS_ERROR_ENTRY_NOT_FOUND };

	if (!config || !section || !option || !value)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "config",  config);
	blobmsg_add_string(&b, "section",  section);
	blobmsg_add_string(&b, "option",  option);
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	value[0] = 0;

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "get", b.head, util_ubus_uci_get_cb, &priv, ubus_invoke_timeout * 1000)) != 0) {
		dbprintf("ubus_invoke uci::get error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}
	blob_buf_free(&b);

	if (priv.ret <0) {
		dbprintf("ubus_invoke uci::get cb error %d(%s)\n", priv.ret, util_ubus_error_str(priv.ret));
		return priv.ret;
	}
	return 0;
}

// uci set /////////////////////////////////////////////////////////////////////////////////////////

// it seems the 'uci set' wont return meaningful msg, so this callback is not called
static void
util_ubus_uci_set_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (!msg)
		return;
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);
}
// ubus call uci set '{"config":"network2", "section":"wan", "values":{"ifname":"eth3"}, "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
int
util_ubus_uci_set(char *config, char *section, char *option, char *value)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;

	if (!config || !section || !option || !value)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "config",  config);
	blobmsg_add_string(&b, "section",  section);
	{
		void *table_values = blobmsg_open_table(&b, "values");
		blobmsg_add_string(&b, option, value);
		blobmsg_close_table(&b, table_values);
	}
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "set", b.head, util_ubus_uci_set_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::set error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}
// ubus call uci set '{"config":"network2", "section":"@device[1]", "values":{ "ports":{{"":"10"},{"":"20"},{"":"30"}}}, ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
int
util_ubus_uci_set_list(char *config, char *section, char *option, char *array[], int array_size)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int i, ret;

	if (!config || !section || !option || !array)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "config",  config);
	blobmsg_add_string(&b, "section",  section);
	{
		void *table_values = blobmsg_open_table(&b, "values");
		void *array_option = blobmsg_open_array(&b, option);
		for (i=0; i <array_size; i++)
			blobmsg_add_string(&b, "", array[i]);
		blobmsg_close_table(&b, array_option);
		blobmsg_close_table(&b, table_values);
	}
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "set", b.head, util_ubus_uci_set_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::set error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}

// uci add_section /////////////////////////////////////////////////////////////////////////////////////////

// it seems the 'uci add' wont return meaningful msg, so this callback is not called
static void
util_ubus_uci_add_section_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (!msg)
		return;
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);
}
// ubus call uci add '{"config":"network2", "type":"interface", "name":"wan", "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
// name is optional, its value could be null
int
util_ubus_uci_add_section(char *config, char *type, char *name)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;

	if (!config || !type)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "config",  config);
	blobmsg_add_string(&b, "type",  type);
	if (name)
		blobmsg_add_string(&b, "name",  name);
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "add", b.head, util_ubus_uci_add_section_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::add error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}

// uci del /////////////////////////////////////////////////////////////////////////////////////////

// it seems the 'uci del' wont return meaningful msg, so this callback is not called
static void
util_ubus_uci_delete_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (!msg)
		return;
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);
}
// ubus call uci del '{"config":"network2", "section":"wan", "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
// type,section,option is optional, its value could be null
int
util_ubus_uci_delete(char *config, char *type, char *section, char *option)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;

	if (!config)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "config",  config);
	if (type)
		blobmsg_add_string(&b, "type",  type);
	if (section)
		blobmsg_add_string(&b, "section",  section);
	if (option)
		blobmsg_add_string(&b, "option",  option);
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "delete", b.head, util_ubus_uci_delete_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::delete error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}

// uci revert /////////////////////////////////////////////////////////////////////////////////////////

// it seems the 'uci revert' wont return meaningful msg, so this callback is not called
static void
util_ubus_uci_revert_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (!msg)
		return;
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);
}
// ubus call uci revert '{"config":"network2", "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
int
util_ubus_uci_revert(char *config)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;

	if (!config)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "config",  config);
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "revert", b.head, util_ubus_uci_revert_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::revert error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}

// uci commit /////////////////////////////////////////////////////////////////////////////////////////

// it seems the 'uci commit' wont return meaningful msg, so this callback is not called
static void
util_ubus_uci_commit_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (!msg)
		return;
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);
}
// ubus call uci commit '{"config":"network2", "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
int
util_ubus_uci_commit(char *config)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;

	if (!config)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "config",  config);
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "commit", b.head, util_ubus_uci_commit_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::commit error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}

// uci apply /////////////////////////////////////////////////////////////////////////////////////////

// it seems the 'uci apply' wont return meaningful msg, so this callback is not called
static void
util_ubus_uci_apply_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (!msg)
		return;
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);
}
// ubus call uci apply '{"config":"network2", "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
//
// when rollback_enable on
// rollback is scheduled at timeout, caller has to call util_ubus_confirm() to cancel this rollback
// when rollback_enable off
// no rollback is scheduled, but caller has to call util_ubus_rollback() manually in case issues found after util_ubus_apply()
int
util_ubus_uci_apply(int rollback_enable, unsigned int auto_rollback_timeout)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_u8(&b, "rollback", rollback_enable);
	blobmsg_add_u32(&b, "timeout",  auto_rollback_timeout);
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "apply", b.head, util_ubus_uci_apply_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::apply error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}

// uci confirm /////////////////////////////////////////////////////////////////////////////////////////

// it seems the 'uci confirm' wont return meaningful msg, so this callback is not called
static void
util_ubus_uci_confirm_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (!msg)
		return;
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);
}

// ubus call uci confirm '{"config":"network2", "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
int
util_ubus_uci_confirm(void)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "confirm", b.head, util_ubus_uci_confirm_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::confirm error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}

// uci rollback /////////////////////////////////////////////////////////////////////////////////////////

// it seems the 'uci rollback' wont return meaningful msg, so this callback is not called
static void
util_ubus_uci_rollback_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (!msg)
		return;
	if (util_ubus_debug)
		util_ubus_dump_blobmsg(msg);
}
// ubus call uci rollback '{"config":"network2", "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
int
util_ubus_uci_rollback(void)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "rollback", b.head, util_ubus_uci_rollback_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::rollback error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}

// uci dump_changes /////////////////////////////////////////////////////////////////////////////////////////

static void
util_ubus_uci_dump_changes_cb(struct ubus_request *req, int type, struct blob_attr *msg)
{
	if (msg) {
		char *str = blobmsg_format_json_indent(msg, true, 0);
		printf("%s\n", str);
		free(str);
	}
}
// ubus call uci changes '{"config":"network2", "ubus_rpc_session":"3dd6cf717b85041e73ad660066577727"}'
int
util_ubus_uci_dump_changes(char *config)
{
	struct blob_buf b;
	unsigned int ubus_path_id;
	int ret;

	if (!config)
		return UTIL_UBUS_ERROR_NULL_POINTER;

	memset(&b, 0, sizeof(b));	// must! or blob_buf_init would segfault
	blob_buf_init(&b, 0);

	// prepare parameter
	blobmsg_add_string(&b, "config",  config);
	blobmsg_add_string(&b, "ubus_rpc_session",  rpc_session_id);

	// check if path 'session' is registered on ubusd
	if ((ret = ubus_lookup_id(ubus_ctx, "uci", &ubus_path_id)) != 0) {
		dbprintf("lookup 'uci' error %d(%s)\n", ret, util_ubus_error_str(ret));
		blob_buf_free(&b);
		return ret;
	}

	if ((ret = ubus_invoke(ubus_ctx, ubus_path_id, "changes", b.head, util_ubus_uci_dump_changes_cb, NULL, ubus_invoke_timeout * 1000)) != 0)
		dbprintf("ubus_invoke uci::changes error %d(%s)\n", ret, util_ubus_error_str(ret));
	blob_buf_free(&b);
	return ret;
}
