#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <gccore.h>
#include <wiiuse/wpad.h>
#include <fat.h>
#include "menu_tik_bin.h"
#include "menu_tmd_bin.h"
#include "menu_certs_bin.h"
#include "patches.h"

#define DEBUG 1

static void *xfb = NULL;
static GXRModeObj *rmode = NULL;


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




void loadDol(u16 index) {
	u32 i;
	static dolheader _dolfile __attribute__((aligned(32)));
	dolheader *dolfile = &_dolfile;
	s32 s = ES_OpenContent(index);
	if(s<0) {
		printf("Error opening content\n");
		return;
	}
	printf("! %d\n", ES_ReadContent(s, dolfile, sizeof(dolheader)));
	memset ((void *) dolfile->bss_start, 0, dolfile->bss_size);
	for (i = 0; i < 7; i++) {
		if(dolfile->data_start[i] < sizeof(dolheader)) continue;
						printf ("loading text section %u @ 0x%08x "
								"(0x%08x bytes)\n",
								i, dolfile->text_start[i],
								dolfile->text_size[i]);
                        VIDEO_WaitVSync();

			ES_SeekContent(s, dolfile->text_pos[i], 0);
			 ES_ReadContent(s, dolfile->text_start[i], dolfile->text_size[i]);
	
		}

		for(i = 0; i < 11; i++) {
				if(dolfile->data_start[i] < sizeof(dolheader)) continue;
					printf ("loading data section %u @ 0x%08x "
								"(0x%08x bytes)\n",
								i, dolfile->data_start[i],
								dolfile->data_size[i]);
                        VIDEO_WaitVSync();

			ES_SeekContent(s, dolfile->data_pos[i], 0);
			ES_ReadContent(s, dolfile->data_start[i], dolfile->data_size[i]);
		}

                VIDEO_WaitVSync();

		
		
		ES_CloseContent(s);
	
}


void _unstub_start();
//---------------------------------------------------------------------------------
int main(int argc, char **argv) {
//---------------------------------------------------------------------------------
	SYS_SetArena1Lo((void*)0x80a00000);
	SYS_SetArena1Hi((void*)0x80b00000);
	SYS_SetArena2Lo((void*)0x80b00000);
	SYS_SetArena2Hi((void*)0x80c00000);
	
	
	// Initialise the video system
	VIDEO_Init();
	
	// This function initialises the attached controllers
	WPAD_Init();
	
	// Obtain the preferred video mode from the system
	// This will correspond to the settings in the Wii menu
	rmode = VIDEO_GetPreferredMode(NULL);

	// Allocate memory for the display in the uncached region
	xfb = MEM_K0_TO_K1(SYS_AllocateFramebuffer(rmode));
	
	// Initialise the console, required for printf
	console_init(xfb,20,20,rmode->fbWidth,rmode->xfbHeight,rmode->fbWidth*VI_DISPLAY_PIX_SZ);
	

	
	// Set up the video registers with the chosen mode
	VIDEO_Configure(rmode);
	
	// Tell the video hardware where our display memory is
	VIDEO_SetNextFramebuffer(xfb);
	
	// Make the display visible
	VIDEO_SetBlack(FALSE);

	// Flush the video register changes to the hardware
	VIDEO_Flush();
	IOS_ReloadIOS(38);

	// Wait for Video setup to complete
	VIDEO_WaitVSync();
	if(rmode->viTVMode&VI_NON_INTERLACE) VIDEO_WaitVSync();
    usleep(100000);
	printf("Identifying as menu:\n");
	int rest = ES_Identify((signed_blob*)menu_certs_bin, menu_certs_bin_size, (signed_blob*)menu_tmd_bin, menu_tmd_bin_size, (signed_blob*)menu_tik_bin, menu_tik_bin_size, 0);
	
	printf("ES_Identify returned %d\n", rest);
	__ES_Close();
	__ES_Init();
	u64 titleID;
	ES_GetTitleID(&titleID);
	printf("titleID: %016llx\n", titleID);
	
	u32 tmdSize;
	printf("%d\n", ES_GetStoredTMDSize(titleID, &tmdSize));
	
	// I need to do this because I have an old version of the TMD
	// I want this to be robust against TMD updates, so rather than just updating...
	u8 *tmd = memalign(32, tmdSize);
	
	int ret = 	ES_GetStoredTMD(titleID, (signed_blob *) tmd, tmdSize);
	printf("ES_GetStoredTMD: %d\n", ret);
	if(ret < 0) { sleep(5); return 1; }
	u16 boot = *((u16 *)(tmd + 0x1e0));
	u32 dataSize = 9999;
	// This is totally not the C way to do things
	int pos;
	for(pos = 0x1e4; pos < tmdSize; pos+=36) {
		printf("BOOT: %x\n",*((u16 *) (tmd + pos + 0x04))); 
		if(*((u16 *) (tmd + pos + 0x04)) == boot) {
			printf("Pos: %04x DS: %08llx\n", pos, *((u64 *) (tmd + pos + 0x08)));
			dataSize = (u32) *((u64 *) (tmd + pos + 0x08));
			break;
		}	
	}
	

	
	rest = ES_Identify((signed_blob*)menu_certs_bin, menu_certs_bin_size, (signed_blob*)tmd, tmdSize, (signed_blob*)menu_tik_bin, menu_tik_bin_size, 0);
	printf("ES_Identify (2nd time) returned %d\n", rest);
	
	printf("Boot: %d\n", boot);
	printf("Data size: %d\n", dataSize);
	
	loadDol(boot);
	u8 *p;
	// run compiled patches
	/**((u32 *) 0x81366fa0) = 0xffffffff;
	ICInvalidateRange(0x81366fa0, 4);*/
     patches();	
	


	SYS_ResetSystem(SYS_SHUTDOWN,0,0);
	DCFlushRange((u32*)0x80000000,0x10000);
	_unstub_start();
	
	return 0;

}
