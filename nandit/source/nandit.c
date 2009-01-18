#include <stdio.h>
#include <stdlib.h>
#include <gccore.h>
#include "minipc_dump_bin.h"
#ifndef DEBUG
#define debug_printf(...)
#endif
static void *xfb = NULL;
static GXRModeObj *rmode = NULL;
#define fail(x) { printf("Fail: " #x); sleep(5); return 1; }
// this code was contributed by shagkur of the devkitpro team, thx!

#include <stdio.h>
#include <string.h>

#include <gccore.h>
#include <ogcsys.h>

typedef struct _dolheader {
	u32 text_pos[7];
	u32 data_pos[11];
	u32 text_start[7];
	u32 data_start[11];
	u32 text_size[7];
	u32 data_size[11];
	u32 bss_start;
	u32 bss_size;
	u32 entry_point;
} dolheader;

u32 load_dol_image (s32 fd) {
	u32 i;
	dolheader dols ATTRIBUTE_ALIGN(32);
	dolheader *dolfile = (dolheader *) memalign(64, sizeof(dolheader));

    int ret = ES_ReadContent(fd, dolfile, sizeof(dolheader));
    debug_printf("ES_ReadContent(%d, %x, %x) --> %d\n", fd, dolfile, sizeof(dolheader), ret);

    if(ret < 0) fail(ES_ReadContent);

    for (i = 0; i < 7; i++) {
        if ((!dolfile->text_size[i]) ||
                        (dolfile->text_start[i] < 0x100))
                            continue;

                    debug_printf ("loading text section %u @ 0x%08x "
                            "(0x%08x bytes)\n",
                            i, dolfile->text_start[i],
                            dolfile->text_size[i]);
                    VIDEO_WaitVSync();

        ICInvalidateRange ((void *) dolfile->text_start[i],
                                                dolfile->text_size[i]);
        if(ES_SeekContent(fd, dolfile->text_pos[i], 0) < 0) fail(ES_SeekContent);
        if(ES_ReadContent(fd, (void *) dolfile->text_start[i], dolfile->text_size[i]) < 0) fail(ES_ReadContent_two);
    }

    for(i = 0; i < 11; i++) {
        if ((!dolfile->data_size[i]) ||
                        (dolfile->data_start[i] < 0x100))
                            continue;

                    debug_printf ("loading data section %u @ 0x%08x "
                            "(0x%08x bytes)\n",
                            i, dolfile->data_start[i],
                            dolfile->data_size[i]);
                    VIDEO_WaitVSync();

        if(ES_SeekContent(fd, dolfile->data_pos[i], 0) < 0) fail(ES_SeekContent);
        if(ES_ReadContent(fd, (void *) dolfile->data_start[i], dolfile->data_size[i]) < 0) fail(ES_ReadContent_two);
        
        DCFlushRangeNoSync ((void *) dolfile->data_start[i],
                                        dolfile->data_size[i]);
    }

            debug_printf ("clearing bss\n");
            VIDEO_WaitVSync();

            return dolfile->entry_point;
}


//---------------------------------------------------------------------------------
int main(int argc, char **argv) {
//---------------------------------------------------------------------------------
//     IOS_ReloadIOS(0xea);
	// Initialise the video system
	VIDEO_Init();

#ifdef DEBUG	
	// Obtain the preferred video mode from the system
	// This will correspond to the settings in the Wii menu
	rmode = VIDEO_GetPreferredMode(NULL);

	// Allocate memory for the display in the uncached region
	xfb = MEM_K0_TO_K1(SYS_AllocateFramebuffer(rmode));
	
	// Initialise the console, required for debug_printf
	console_init(xfb,20,20,rmode->fbWidth,rmode->xfbHeight,rmode->fbWidth*VI_DISPLAY_PIX_SZ);
	
	// Set up the video registers with the chosen mode
	VIDEO_Configure(rmode);
	
	// Tell the video hardware where our display memory is
	VIDEO_SetNextFramebuffer(xfb);
	
	// Make the display visible
	VIDEO_SetBlack(FALSE);

	// Flush the video register changes to the hardware
	VIDEO_Flush();

	// Wait for Video setup to complete
	VIDEO_WaitVSync();
	if(rmode->viTVMode&VI_NON_INTERLACE) VIDEO_WaitVSync();


	// The console understands VT terminal escape codes
	// This positions the cursor on row 2, column 0
	// we can use variables for this with format codes too
	// e.g. debug_printf ("\x1b[%d;%dH", row, column );
	debug_printf("\x1b[2;0H");
	

	debug_printf("Hello World!");
    debug_printf("LOL: %d\n", ES_SetUID(0x0000000100000002));
#endif
    if(minipc_dump_bin_size >= 0x1800) {
        debug_printf("Too big\n");
        while(1);
    }
    memcpy((void *) 0x80001800, minipc_dump_bin, minipc_dump_bin_size);
    
    ICInvalidateRange((void *) 0x80001800, 0x1800);
    DCFlushRange((void *) 0x80001800, 0x1800);

    


    s32 fd = ES_OpenContent(2); // (1)
    debug_printf("fd: %x\n", fd);
    if(fd < 0) {
        debug_printf("OpenContent fail: %d\n", fd);
        return 1;
    }
    
    typedef void (*entrypoint)();
    
    entrypoint ep = (entrypoint) load_dol_image(fd);
    
    ES_CloseContent(fd);
    
    ep();

	return 0;
}
