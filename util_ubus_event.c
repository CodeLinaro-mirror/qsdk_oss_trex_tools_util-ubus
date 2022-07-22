#include <libubox/uloop.h>
#include <libubox/ustream.h>
#include <libubox/utils.h>
#include <libubus.h>
#include <json-c/json.h>
#include <libubox/blobmsg_json.h>

static inline char *util_purename(char *path) { char *delim=rindex(path, '/'); return delim?(delim+1):path; }
#define dbprintf(fmt, args...)      do { if(dbg_level) fprintf(stderr,"%s:%d: %s(): " fmt, util_purename(__FILE__), __LINE__, __FUNCTION__, ##args); } while (0)

int dbg_level=0;
static struct ubus_context * ctx = NULL;
static const char * cli_path;
static int shutdown=0,trap_mode=-1,fake_mode=-1;
static char ifname[16]={0};
 
#define	UBUS_EVENT_CTL	"util_ubus_event"
#define	UBUS_EVENT_REMOVE_DEVICE	"rm_device"
#define UBUS_EVENT_ALL    "*"
#define UBUS_EVENT_NETWORK    "network.interface"

int timer_delay = 5;

static void shutdown_timer(struct uloop_timeout *timeout)
{
    //uloop_timeout_cancel(timeout);
    uloop_cancelled = true;
}

static void shell_timer(struct uloop_timeout *timeout)
{
        char cmd[128]={0};
        if(trap_mode != -1 || fake_mode!=-1 )
        {
                snprintf(cmd, 127, "ifname=%s trap_mode=%d fake_mode=%d set_igmp_route.sh",
                                ifname, trap_mode, fake_mode);
                dbprintf("call script: %s\n", cmd);
                system(cmd);
        }
        else
        {
                dbprintf("trap_mode or fake mode unknown ! \n");
        }
}

static struct uloop_timeout timer_shutdown = { .cb = shutdown_timer };
static struct uloop_timeout timer_shell = { .cb = shell_timer };

int ubus_get_objstr(struct blob_attr *msg, char *key, char *str, int strlen)
{
        int ret=0;
        json_object *jobj;
        enum json_type jtype;
        json_object *obj_key;
        const char *strval;
        jobj = json_tokener_parse(blobmsg_format_json(msg, true));
        if ( json_object_object_get_ex(jobj, key, &obj_key) )
        {
                jtype = json_object_get_type(obj_key);
                switch (jtype)
                {
                        case json_type_string:
                                strval = json_object_get_string(obj_key);
                                dbprintf("%s=%s\n", key, strval);
                                strncpy(str, strval, strlen);
                                break;
                        default:
                                ret=-1;
                                break;
                }
                json_object_put(obj_key);
        }
        else
                ret=-1;
        json_object_put(jobj);
        return ret;
}

int ubus_get_objint(struct blob_attr *msg, char *key, int *value)
{
        int ret=0;
        json_object *jobj;
        enum json_type jtype;
        json_object *obj_key;

        jobj = json_tokener_parse(blobmsg_format_json(msg, true));
        if ( json_object_object_get_ex(jobj, key, &obj_key) )
        {
                jtype = json_object_get_type(obj_key);
                switch (jtype)
                {
                        case json_type_int:
                                *value = json_object_get_int(obj_key);
                                dbprintf("%s=%d\n", key, *value);
                                break;
                        default:
                                ret=-1;
                                break;
                }
                json_object_put(obj_key);
        }
        else
                ret=-1;
        json_object_put(jobj);
        return ret;
}

static void ubus_probe_device_event(struct ubus_context *ctx, struct ubus_event_handler *ev,
			  const char *type, struct blob_attr *msg)
{
        char *str;
        const char *strval;
        //int intval;
        json_object *jobj;
        //enum json_type jtype;
        json_object *obj_key;
        int ifup = 0;

        if ( !msg )
                return;

        str = blobmsg_format_json(msg, true);
        dbprintf("{ \"%s\": %s }\n", type, str);
        jobj = json_tokener_parse(str);

        if ( strncmp(type, UBUS_EVENT_CTL, strlen(UBUS_EVENT_CTL)) == 0 )
        {
                ubus_get_objint(msg, "set_delay", &timer_delay);
                if(!ubus_get_objint(msg, "shutdown", &shutdown))
                {
                        if ( shutdown )
                                uloop_timeout_set(&timer_shutdown,timer_delay * 1000);
                }
                ubus_get_objstr(msg, "ifname", ifname, sizeof(ifname));
                ubus_get_objint(msg, "trap_mode", &trap_mode);
                ubus_get_objint(msg, "fake_mode", &fake_mode);
        }
        else if ( strncmp(type, UBUS_EVENT_NETWORK, strlen(UBUS_EVENT_NETWORK)) == 0 )
        {
                if ( json_object_object_get_ex(jobj, "action", &obj_key) )
                {
                        strval = json_object_get_string(obj_key);
                        if ( strncmp(strval, "ifup", strlen("ifup")) == 0 )
                                ifup = 1;
                        else
                                ifup = 0;
                        json_object_put(obj_key);
                }
                if ( json_object_object_get_ex(jobj, "interface", &obj_key) )
                {
                        strval = json_object_get_string(obj_key);
                        if ( strncmp(strval, "lan", strlen("lan")) == 0 && ifup )
                        {
                                uloop_timeout_set(&timer_shell, timer_delay * 1000);
                        }
                        json_object_put(obj_key);
                }
        }
        json_object_put(jobj);
        free(str);
}
 
static int client_ubus_register_events()
{
	static struct ubus_event_handler listener;
	int ret = 0;
 
	memset(&listener, 0, sizeof(listener));
	listener.cb = ubus_probe_device_event;
	ret = ubus_register_event_handler(ctx, &listener, UBUS_EVENT_CTL);
	if (ret)
	{
		fprintf(stderr, "register event failed.\n");
		return -1;
	}

	ret = ubus_register_event_handler(ctx, &listener, UBUS_EVENT_NETWORK);
	if (ret)
	{
		ubus_unregister_event_handler(ctx, &listener);
		fprintf(stderr, "register event failed.\n");
		return -1;
	}
	return 0;
}
 
static void ubus_add_fd(void)
{
	ubus_add_uloop(ctx);
 
#ifdef FD_CLOEXEC
	fcntl(ctx->sock.fd, F_SETFD,
		fcntl(ctx->sock.fd, F_GETFD) | FD_CLOEXEC);
#endif
}
 
static void ubus_reconn_timer(struct uloop_timeout *timeout)
{
	static struct uloop_timeout retry =
	{
		.cb = ubus_reconn_timer,
	};
	int t = 2;
 
	if (ubus_reconnect(ctx, cli_path) != 0) {
		uloop_timeout_set(&retry, t * 1000);
		return;
	}
	ubus_add_fd();
}
 
static void ubus_connection_lost(struct ubus_context *ctx)
{
	ubus_reconn_timer(NULL);
}
 
static int client_ubus_init(const char *path)
{
	uloop_init();
	cli_path = path;
	
	ctx = ubus_connect(path);
	if (!ctx)
	{
		printf("ubus connect failed\n");
		return -1;
	}
	
	printf("connected as %08x\n", ctx->local_id);
	ctx->connection_lost = ubus_connection_lost;
 
	ubus_add_fd();
 
	return 0;
}
 
static void client_ubus_done(void)
{
	if (ctx)
		ubus_free(ctx);
}
 
int main(int argc, char * argv[])
{
        char *path = NULL;
        const char *dbg_str = getenv("UTIL_DBG");
        if ( dbg_str )
        {
                dbg_level = atoi(dbg_str);
                //printf("dbg_level=%d\n",dbg_level);
        }

        if ( UBUS_STATUS_OK != client_ubus_init(path) )
        {
                printf("ubus connect failed!\n");
                return -1;
        }
        //init variable
        strcpy(ifname,"eth4");
        trap_mode=-1;
        fake_mode=-1;
        client_ubus_register_events();

        uloop_run();

        client_ubus_done();

        return 0;
}
