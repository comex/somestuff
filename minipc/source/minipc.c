#include <gctypes.h>
#include <gcutil.h>
#include <stdio.h>
#include "usbprintf.h"
#define IPC_REQ_MAGIC                   0x4C4F4743
void DCFlushRange(void *startaddress,u32 len);

//#define DEBUG_MINIPC_SORTA
#ifdef DEBUG_MINIPC
#define debug_printf usbprintf
void dump_mem(void *stuff, int len) {
    char *s = (char *) stuff;
    while(len--) {
        debug_printf("%02hhx ", *(s++));
    }
    debug_printf("\n");
}
#else
#ifdef DEBUG_MINIPC_SORTA
#define debug_printf usbprint
#else
#define debug_printf(...)
#endif
inline void dump_mem(void *stuff, int len) {}
#endif
typedef struct _ioctlv
{
        void *data;
        u32 len;
} ioctlv;

struct _ipcreq
{                                               //ipc struct size: 32
        u32 cmd;                        //0
        s32 result;                     //4
        union {                         //8
                s32 fd;
                u32 req_cmd;
        };
        union {
                struct {
                        char *filepath;
                        u32 mode;
                } open;
                struct {
                        void *data;
                        u32 len;
                } read, write;
                struct {
                        s32 where;
                        s32 whence;
                } seek;
                struct {
                        u32 ioctl;
                        void *buffer_in;
                        u32 len_in;
                        void *buffer_io;
                        u32 len_io;
                } ioctl;
                struct {
                        u32 ioctl;
                        u32 argcin;
                        u32 argcio;
                        struct _ioctlv *argv;
                } ioctlv;
                u32 args[5];
        };

        void * /* ipccallback*/ cb;         //32 
        u32 usrdata;          //36 =
        u32 relnch;                     //40 
        void * /*lwpq_t*/ syncqueue;       //44
        u32 magic;                      //48 - used to avoid spurious responses, like from zelda.
        u8 pad1[12];            //52 - 60
} __attribute__((packed));
typedef struct _tiklimit {
        u32 tag;
        u32 value;
} __attribute__((packed)) tiklimit;

typedef struct _tikview {
        u32 view;
        u64 ticketid;
        u32 devicetype;
        u64 titleid;
        u16 access_mask;
        u8 reserved[0x3c];
        u8 cidx_mask[0x40];
        u16 padding;
        tiklimit limits[8];
} __attribute__((packed)) tikview;

struct _ipcreqres
{
        u32 cnt_sent;
        u32 cnt_queue;
        u32 req_send_no;
        u32 req_queue_no;
        struct _ipcreq *reqs[16];
};

typedef struct {
	u32 checksum;
	u8 flags;
	u8 type;
	u8 discstate;
	u8 returnto;
	u32 unknown[6];
} StateFlags;
static vu32 *_ipcReg = (u32*)0xCD000000;
#define v2p(x)              (((u32)(x)) & ~(0xC0000000))
static inline u32 IPC_ReadReg(u32 reg)
{
        return _ipcReg[reg];
}

static inline void IPC_WriteReg(u32 reg,u32 val)
{
        _ipcReg[reg] = val;
}


char *ipcland;
char *ipcland_base;
int ipcland_size;
void init() {
    ipcland_base = (char *) 0x80902c00;//0x933f0000; //933e
    ipcland_size = 0x2000;
    IPC_WriteReg(1, 56);
    ipcland = ipcland_base;
    memset(ipcland, 0, ipcland_size);
    DCFlushRange(ipcland, ipcland_size);
}

void *ios_alloc(int len) { // worst allocator ever
    void *ret = (void *) (ipcland += ((len & ~31) + 32));
    if(ipcland > ipcland_base + ipcland_size) {
        debug_printf("oom\n");
        while(1);
    }
    return ret;
}




s32 send_request(struct _ipcreq *req) {
    debug_printf("[send request]\n");
    req->result = 0xdeadbeef;
    req->cb = 0;
    req->usrdata = 0xfeedb0bb;
    
    req->magic = IPC_REQ_MAGIC;
    dump_mem(req, sizeof(struct _ipcreq));
    
    // Flush the world, why not
    DCFlushRange(ipcland_base, ipcland_size);
    
    
    IPC_WriteReg(0, v2p(req));
    u32 ipc_send = (IPC_ReadReg(1) & 0x30) | 0x01;
    IPC_WriteReg(1, ipc_send);
    // do something --> interrupt handler?
    while(1) {
        u32 ipc_int;
        ipc_int = IPC_ReadReg(1);
        if((ipc_int & 0x0014) == 0x0014) {
            IPC_WriteReg(1, (IPC_ReadReg(1) & 0x30) | 0x4);
            IPC_WriteReg(48 >> 2,0x40000000);
            struct _ipcreq *req2 = (struct _ipcreq *) IPC_ReadReg(2);
            
            if(!req2) {
                debug_printf("Invalid req\n");
                continue;
            }
            
            req2 = (struct _ipcreq *) (((u32) req2) + 0x80000000);
            debug_printf("[req is %x]\n", req2);
            DCInvalidateRange(req2, sizeof(struct _ipcreq));
            debug_printf("%x = %x?\n", req2->magic, IPC_REQ_MAGIC);
            dump_mem(req2, sizeof(struct _ipcreq));
            if(req2->magic != IPC_REQ_MAGIC) {
                continue;
            }
            u32 ipc_ack = ((IPC_ReadReg(1)&0x30)|0x08);
            IPC_WriteReg(1,ipc_ack);
//             IPC_WriteReg(1, (IPC_ReadReg(1) & 0x30) | 0x8);
            if(req2->usrdata != 0xfeedb0bb) {
                debug_printf("Ignoring spurious response\n");
                continue;
            }
            DCInvalidateRange(ipcland_base, ipcland_size);
            return req2->result;
        }
        ipc_int = IPC_ReadReg(1);
        if((ipc_int & 0x0022) == 0x0022) { // Okay, we got it!
            debug_printf("[ack]\n");
            IPC_WriteReg(1, (IPC_ReadReg(1) & 0x30) | 0x2);
            IPC_WriteReg(48 >> 2,0x40000000);
        }
    }
}


static u32 __CalcChecksum(u32 *buf, int len)
{
	u32 sum = 0;
	int i;
	len = (len/4);

	for(i=1; i<len; i++)
		sum += buf[i];

	return sum;
}

static void __SetChecksum(void *buf, int len)
{
	u32 *p = (u32*)buf;
	p[0] = __CalcChecksum(p, len);
}
void write_state_flags() {
    static char __stateflags[] ATTRIBUTE_ALIGN(32) = "/title/00000001/00000002/data/state.dat";
    struct _ipcreq *req = ios_alloc(sizeof(struct _ipcreq));
    memset(req, 0xee, sizeof(struct _ipcreq));

    req->cmd = 1; // open
    req->fd = 0;
    req->open.filepath = v2p(__stateflags);
    req->open.mode = 3;

    int fd = send_request(req);
    debug_printf("Flags FD: %d\n", fd);
    
    
    StateFlags *stateflags = (StateFlags *)  ios_alloc(sizeof(StateFlags));
    
    req->cmd = 3; // read
    req->fd = fd;
    req->read.data = v2p(stateflags);
    req->read.len = sizeof(StateFlags);
    
    int res = send_request(req);
    debug_printf("Read:%d\n", res);
    if(res < 0) return;
    
    // Now modify
    stateflags->type = 3;//TYPE_RETURN;
	stateflags->returnto = 0;//RETURN_TO_MENU;
	
	__SetChecksum(stateflags, sizeof(StateFlags));
	
	debug_printf("OK...\n");
	
	req->cmd = 5; // seek
	req->fd = fd;
	req->seek.where = 0;
	req->seek.whence = 0;
	
    res = send_request(req);
    debug_printf("Seek:%d\n", res);
    if(res < 0) return;
    
    req->cmd = 4; // write
    req->fd = fd;
    req->write.data = v2p(stateflags);
    req->write.len = sizeof(StateFlags);
    
    res = send_request(req);
    debug_printf("Write:%d\n", res);
    if(res < 0) return;

    req->cmd = 2; // close
    req->fd = fd;
    
    res = send_request(req);
    debug_printf("Close:%d\n", res);

    
    return;

}



void do_something() {
    debug_printf("Hi!");

    init();
    debug_printf("!\n");
    struct _ipcreq *req = ios_alloc(sizeof(struct _ipcreq));
    debug_printf("(alloc req)\n");
    memset(req, 0xee, sizeof(struct _ipcreq));
    
    
    char *dev_es = ios_alloc(32);
    memset(dev_es, 0, 32);
    dev_es[0] = '/';
    dev_es[1] = 'd';
    dev_es[2] = 'e';
    dev_es[3] = 'v';
    dev_es[4] = '/';
    dev_es[5] = 'e';
    dev_es[6] = 's';
    
    
    debug_printf("(/dev/es)\n");
    ioctlv *argv = (ioctlv *) ios_alloc(40);
    u32 *numviews = (u32 *) ios_alloc(8); // 4
    *numviews = 0;
    u64 *titleid = (u64 *) ios_alloc(8);
    *titleid = 0x100000002LL;
       
    debug_printf("(set stuff)\n");
    
    
    req->cmd = 1; // open
    req->fd = 0;
    debug_printf("Taking the plunge...\n");
    req->open.filepath = v2p(dev_es);
    req->open.mode = 0;
    int fd = send_request(req);
    debug_printf("Result: %d\n", fd);
    if(fd < 0) return;

    write_state_flags();
    
    req->cmd = 7; // ioctlv
    req->fd = fd;
    req->ioctlv.ioctl = 0x12; // ES_GETVIEWCNT = 0x12
    req->ioctlv.argcin = 1;
    req->ioctlv.argcio = 1;
    req->ioctlv.argv = v2p(argv);
    
     
    
    
    
    argv[0].data = v2p(titleid);
    argv[0].len = 8;
    argv[1].data = v2p(numviews);
    argv[1].len = 4;
    
    debug_printf("argv:%x argv[0].data: %x\nargv[1].data: %x\n", req->ioctlv.argv, argv[0].data, argv[1].data);
    
    dump_mem(argv, 20);
    dump_mem(titleid, 8);
    
    int res = send_request(req);

    DCInvalidateRange(titleid, 8);
    DCInvalidateRange(numviews, 4);

    debug_printf("[NumViews] Result: %d (%ux)\n", res, res);
    
    
    
    if(res >= 0) {
        debug_printf("Num views: %x\n", *numviews);
    }
//      return;
     if(*numviews > 4) return;


    void *views = (void *) 0x90009000;
    
    req->cmd = 7; // ioctlv
    req->fd = fd;
    req->ioctlv.ioctl = 0x13; // ES_GETVIEWS
    req->ioctlv.argcin = 2;
    req->ioctlv.argcio = 1;
    req->ioctlv.argv = v2p(argv);
    
    argv[0].data = v2p(titleid);
    argv[0].len = 8;
    argv[1].data = v2p(numviews);
    argv[1].len = 4;
    argv[2].data = v2p(views);
    argv[2].len = sizeof(tikview) * (*numviews);
    
    
    res = send_request(req);
    
    debug_printf("[GetViews] Result: %d\n", res);
    
    // Now launch it!
    
    req->cmd = 7; // ioctlv
    req->fd = fd;
    req->ioctlv.ioctl = 0x8; // ES_LAUNCH
    req->ioctlv.argcin = 2;
    req->ioctlv.argcio = 0;
    req->ioctlv.argv = v2p(argv);
    req->relnch = 1; // RELNCH_RELAUNCH
    
    argv[0].data = v2p(titleid);
    argv[0].len = 8;
    argv[1].data = v2p(views);
    argv[1].len = sizeof(tikview);

    res = send_request(req);
    
    debug_printf("[Launch] Result: %d\n", res);
}