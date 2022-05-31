#include <stdio.h>
#include <stdlib.h>
#include "util_ubus.h"
#include <unistd.h>
#include <string.h>
#include <sys/stat.h>
#define UCI_LINE_DEF
#define dbprintf_wanif(fmt, args...)      do { if(dbg_level) fprintf(stderr,"%s:%d: %s(): " fmt, util_purename(__FILE__), __LINE__, __FUNCTION__, ##args); } while (0)


int dbg_level=0;
enum uci_option_type {
    UCI_TYPE_STRING = 0,
    UCI_TYPE_LIST = 1,
};

typedef struct _uci_line_ {
  int  cmd_idx;
  char *cmd_str;
  char *package;
  char *section;
  char *option;
  enum uci_option_type type;
  char *value;
} UCI_LINE;

enum uci_command {
    UCI_CMD_ADD,
    UCI_CMD_SET,
    UCI_CMD_DEL,
    UCI_CMD_GET,
    UCI_CMD_CHANGES,
    UCI_CMD_COMMIT,
    UCI_CMD_RESTART,
    __UCI_CMD_MAX,
    __UCI_CMD_LAST = __UCI_CMD_MAX - 1
};

char *configName=NULL;

int uci_cmd2index(char *cmd);

void uci_line_init(UCI_LINE *line, int freept)
{
    if(freept)
    {
        if ( line->cmd_str )
            free(line->cmd_str);
        if ( line->package )
            free(line->package);
        if ( line->section )
            free(line->section);
        if ( line->option )
            free(line->option);
        if ( line->value )
            free(line->value);
    }
    memset(line,0,sizeof(UCI_LINE));
    line->cmd_idx=-1;
}

void uci_line_dump(UCI_LINE *line)
{
    printf("cmd=%s,package=%s,section=%s,option=%s,value=%s\n",
            line->cmd_str,line->package,line->section,
            line->option,line->value);
}
#define MAX(a,b)    (a>b)?a:b

void check_config_file(char *package)
{
    FILE *fp;
    char filepath[128]="/etc/config/";
    int needcreate=0;
    if(configName==NULL)
    {
        needcreate=1;
    }
    else
    {
        size_t len = MAX(strlen(configName), strlen(package));
        if ( strncmp(configName, package, len) != 0 )
        {
            needcreate=1;
        }
    }
    if(needcreate)
    {
        if(configName)  free(configName);
        strcat(filepath, package);
        configName = strdup(package);
        if ( access(filepath, F_OK) != 0 )
        {
            if ( !(fp = fopen(filepath, "w+")) )
                printf("%s create fail!\n", filepath);
            else
                fclose(fp);
        }
    }
}

int uci_line_parser(char *input_line, UCI_LINE *line)
{
    char *pt;
    strtok(input_line, "\n");

    /* value */
    pt = strchr(input_line, '=');
    if ( pt )
    {
        *pt = 0;
        pt++;
        line->value = strdup(pt);
    }
    pt=strtok(input_line, " ");
    if(pt)
    {
        line->cmd_idx = uci_cmd2index(pt);
        line->cmd_str = strdup(pt);
    }
    if(line->cmd_idx<0)
    {
        printf("cmd not found!\n");
        uci_line_init(line,1);
        return -1;
    }
    switch(line->cmd_idx)
    {
        case UCI_CMD_ADD:
            pt=strtok(NULL, " ");
            break;
        case UCI_CMD_CHANGES:
        case UCI_CMD_COMMIT:
            pt=strtok(NULL, "\n");
            break;
        case UCI_CMD_SET:
        case UCI_CMD_DEL:
        case UCI_CMD_GET:
            pt=strtok(NULL, ".");
            break;
        default:
            return 0;
            break;
    }
    if ( pt )
    {
        line->package = strdup(pt);
    }
    pt=strtok(NULL, ".");
    if ( pt )
    {
        line->section = strdup(pt);
        check_config_file(line->package);
    }
    pt = strtok(NULL, ".");
    if ( pt )
    {
        line->option = strdup(pt);
    }
    return 0;
}

int uci_cmd_add(UCI_LINE *line)
{
    int ret;
    ret = util_ubus_uci_add_section(line->package, "interface", line->section);
    dbprintf_wanif("ret=%d(%s)\n\n", ret, util_ubus_error_str(ret));
    return ret;
}
int uci_cmd_set(UCI_LINE *line)
{   int ret;
    if(line->option)
        ret = util_ubus_uci_set(line->package, line->section, line->option, line->value);
    else
        ret = util_ubus_uci_add_section(line->package, line->value, line->section);
    dbprintf_wanif("ret=%d(%s)\n\n", ret, util_ubus_error_str(ret));
    return ret;
}
int uci_cmd_del(UCI_LINE *line)
{
    int ret;
    ret = util_ubus_uci_delete(line->package, NULL, line->section, line->option);
    dbprintf_wanif("ret=%d(%s)\n\n", ret, util_ubus_error_str(ret));
    return ret;
}
int uci_cmd_get(UCI_LINE *line)
{
    int ret;
    char buf[256];
    char *name,*value;
    ret = util_ubus_uci_get(line->package, line->section, line->option, buf, sizeof(buf)-1);
    dbprintf_wanif("ret=%d(%s)\nbuf=%s\n", ret, util_ubus_error_str(ret),buf);
    if(line->option)
        printf("%s.%s.%s=%s\n",line->package,line->section,line->option,buf);
    else
    {
        name=strtok(buf,":");
        if(!name)   return ret;
        do
        {
            value=strtok(NULL,",");
            if(name[0]=='.')
                printf("%s.%s=%s\n",line->package,line->section,value);
            else
                printf("%s.%s.%s=%s\n",line->package,line->section,name,value);
        }while((name=strtok(NULL,":")));
    }
    return ret;
}
int uci_cmd_changes(UCI_LINE *line)
{
    int ret;
    ret=util_ubus_uci_dump_changes(line->package);
    dbprintf_wanif("ret=%d(%s)\n\n", ret, util_ubus_error_str(ret));
    return ret;
}
int uci_cmd_commit(UCI_LINE *line)
{
    int ret;
    if(line->package)
        ret = util_ubus_uci_commit(line->package);
    else
        ret = util_ubus_uci_apply(0, 30);
    dbprintf_wanif("ret=%d(%s)\n\n", ret, util_ubus_error_str(ret));
    return ret;
}
int uci_cmd_restart(UCI_LINE *line)
{
    int ret;
    //system("/etc/init.d/network restart &");
    ret=system("ubus call network restart &");
    return ret;
}

typedef int uci_fn_t(UCI_LINE *line);
typedef struct {
    char    *cmdName;
    uci_fn_t  *func;
} uci_dispatchTable;

uci_dispatchTable uci_cmd_dispatch[] = {
        [UCI_CMD_ADD] = { "add", uci_cmd_add },
        [UCI_CMD_SET] = { "set", uci_cmd_set },
        [UCI_CMD_DEL] = { "del", uci_cmd_del },
        [UCI_CMD_GET] = { "get", uci_cmd_get },
        [UCI_CMD_CHANGES] = { "changes", uci_cmd_changes },
        [UCI_CMD_COMMIT] = { "commit", uci_cmd_commit },
        [UCI_CMD_RESTART] = { "restart", uci_cmd_restart }
};

int numdispatch = sizeof( uci_cmd_dispatch ) / sizeof(uci_cmd_dispatch[0] );

int uci_cmd2index(char *cmd)
{
    for(int i=UCI_CMD_ADD; i<__UCI_CMD_MAX;i++)
    {
        if(!strncmp(cmd,uci_cmd_dispatch[i].cmdName,strlen(cmd)))
            return i;
    }
    return -1;
}

int uci_run(UCI_LINE *line)
{
    int ret = -1;
    if ( line->cmd_idx >= UCI_CMD_ADD && line->cmd_idx < __UCI_CMD_MAX )
        ret = uci_cmd_dispatch[line->cmd_idx].func(line);
    else
        printf("uci command not found!\n");
    return ret;
}

int main(int argc, char *argv[])
{
    unsigned int session_expire;
    int ret;
    char *line = NULL;
    size_t len = 0;
    ssize_t lineSize = 0;
    FILE *input=stdin;
    UCI_LINE uci_line;
    const char* dbg_str = getenv("UTIL_DBG");
    if(dbg_str)
    {
        dbg_level=atoi(dbg_str);
        //printf("dbg_level=%d\n",dbg_level);
    }

// CLIENT INIT
    dbprintf_wanif("util_ubus_client_init\n");
    if (util_ubus_client_init() != 0)
        return -1;
    dbprintf_wanif("util_ubus_session_login\n");
// SESSSION_LOGIN
    // login with session idle timeout 60s
    ret = util_ubus_session_login("root", "admin", 60);
    dbprintf_wanif("ret=%d(%s)\n\n", ret, util_ubus_error_str(ret));
// SESSION_VALIDATE, ret != 0 if session is invalid, session_expire means seconds to expire the rpcd session
    dbprintf_wanif("util_ubus_session_validate\n");
    ret = util_ubus_session_validate(&session_expire);
    dbprintf_wanif("ret=%d(%s)\n\n", ret, util_ubus_error_str(ret));

    if(argc>1)
    {
       if(!(input = fopen(argv[1],"r")))
       {
         printf("open %s error!\n",argv[1]);
         util_ubus_client_finish();
         return -1;
       }
    }
    uci_line_init(&uci_line,0);
    while(!feof(input))
    {
        //sleep(1);
        //fgets(line, 255, stdin);
        lineSize = getline(&line, &len, input);

        if ( lineSize == 1 )
            dbprintf_wanif("char =%x\n", line[0]);
        else if ( lineSize > 1 )
        {
            uci_line_parser(line, &uci_line);
            if(dbg_level) uci_line_dump(&uci_line);
            ret = uci_run(&uci_line);
            if(dbg_level) printf("ret=%d\n", ret);
            uci_line_init(&uci_line,1);
        }
        if ( line )
        {
            free(line);
            line = NULL;
            len = 0;
        }

    }
    util_ubus_client_finish();
    if(input!=stdin)
         fclose(input);
    if(configName)
         free(configName);

    return 0;
}
