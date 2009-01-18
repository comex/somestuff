#include "sha1.h"
#define HW_RVL // haxx
#include <ogc/es.h>
#undef HW_RVL
#undef SIGNATURE_SIZE
// 2048 - 00010001
// 4096 - 00010002
#define swap16(x) (((x & 0x00ffU) << 8) | ((x & 0xff00U) >> 8))

#define SIGNATURE_SIZE(x) 0x140
/*(\
        ((*(x))==0x01000100) ? sizeof(sig_rsa2048) : ( \
        ((*(x))==0x02000100) ? sizeof(sig_rsa4096) : 0 ))*/
#undef TMD_SIZE
#define TMD_SIZE(x) (swap16((x)->num_contents)*sizeof(tmd_content) + sizeof(tmd))
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>
// From patchmii
void brute_tmd(tmd *p_tmd) {
  u16 fill;
  //printf("Size: %x\n", TMD_SIZE(p_tmd));
  for(fill=0; fill<65535; fill++) {
    p_tmd->fill3=fill;
    sha1 hash;
    //printf("SHA1(%p, %x, %p)\n", p_tmd, TMD_SIZE(p_tmd), hash);
    SHA1((u8 *)p_tmd, TMD_SIZE(p_tmd), hash);;

    if (hash[0]==0) {
      //printf("setting fill3 to %04hx --> %lx\n", fill, hash);
      return;
    }
  }
  printf("Unable to fix tmd :(\n");
  exit(4);
}
void brute_tik(tik *p_tik) {
  u16 fill;
  for(fill=0; fill<65535; fill++) {
    p_tik->padding=fill;
    sha1 hash;
    SHA1((u8 *)p_tik, 0x2a4 - 0x140 /*sizeof(tik)*/, hash);
    u8 *pt = (u8 *) p_tik;
    //printf("Size: %x / really %x ... first few bytes are %x %x %x\n", sizeof(tik), 0x2a4 - 0x140, pt[0], pt[1], pt[2]);
    //printf("%02x %02x %02x %02x %02x (%x)...\n", hash[0], hash[1], hash[2], hash[3], hash[4], fill);
    if (hash[0]==0) return;
  }
  printf("Unable to fix tik :(\n");
  exit(5);
}
void zero_sig(u32 *sig) {
  u8 *sig_ptr = (u8 *)sig;
  memset(sig_ptr + 4, 0, SIGNATURE_SIZE(sig)-4);
}
int main(int argc, char **argv) {
    if(argc != 3) {
        if(argc >= 1)
            printf("Usage: %s <tmd/tik> <1 if tmd, 0 if tik>\n", argv[0]);
        exit(1);
    }
    int fd = open(argv[1], O_RDWR);
    if(fd == -1) {
        printf("Error: %s\n", strerror(errno));
        return 1;
    }
    FILE *f = fdopen(fd, "r+");
    fseek(f, 0, SEEK_END);
    long length = ftell(f);
    //printf("Length: %lx\n", length);
    void *map = mmap(0, length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    printf("Map; %x\n", map);
    u32 *x = (u32 *) map;
    //printf(":: %x\n", *x);
    //printf("%x\n", ((u32*)(SIGNATURE_PAYLOAD(x))) - x);
    zero_sig(x);
    if(atoi(argv[2]) == 1)
        brute_tmd(SIGNATURE_PAYLOAD(x));
    else
        brute_tik(SIGNATURE_PAYLOAD(x));
    
    close(fd);
}
