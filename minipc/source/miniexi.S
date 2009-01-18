#include "ppc.h"


.globl exisendbuffer
.globl exireceivebuffer
.globl exisendbyte
.globl exireceivebyte
.globl exisendword




exisendbuffer: # void exisendbuffer(int num, void *buf)
    mflr r10
    mtctr r3
    mr r8, r4
    li r9, 0
sendloop:
    lbzx r3, r8, r9
    bl exisendbyte
    beq sendloop
    
    addi r9, r9, 1
    bdnz sendloop
# we're done
    mtlr r10
    blr



exireceivebuffer: # void exireceivebuffer(int num, void *buf)
    mflr r10
    mtctr r3
    mr r8, r4
    li r9, 0
rcvloop:
    #bl exicheckreceive
    bl exicheckreceive
    bl exireceivebyte
    stbx r3, r9, r8 # check this
    addi r9, r9, 1
    bdnz rcvloop
    mtlr r10
    blr

exicheckreceive:
    mflr r6
exicheckreceiveloop:
    lis r3, 0xD000
    bl checkexisend
    rlwinm. r3, r4, 6, 31, 31 # returns either 0 or 1 for r3 
    beq exicheckreceiveloop
    mtlr r6
    blr
exisendword:
    mflr r0
    stwu r0, -4(r1)
    mr r0, r3
    srwi r3, r0, 24
    bl exisendbyte
    srwi r3, r0, 16
    bl exisendbyte
    srwi r3, r0, 8
    bl exisendbyte
    srwi r3, r0, 0
    bl exisendbyte    
    lwz r0, 0(r1)
    addi r1, r1, 4
    mtlr r0
    blr

exireceiveword:
    mflr r6
    stwu r6, -4(r1)
    li r6, 0
    bl exireceivebyte
    slwi r3, r3, 24
    add r6, r6, r3    
    bl exireceivebyte
    slwi r3, r3, 16
    add r6, r6, r3
    bl exireceivebyte
    slwi r3, r3, 8
    add r6, r6, r3
    bl exireceivebyte
    add r6, r6, r3
    mr r3, r6
    lwz r6, 0(r1)
    addi r1, r1, 4
    mtlr r6
    blr
    

# CLOBBERS r7 too
exisendbyte:                            # r3, send value
        mflr    r6
        andi.    r3, r3, 0xff
        slwi    r3, r3, 20              # (sendbyte<<20);
        oris    r3, r3, 0xB000          # 0xB0000000 | (OR)

        bl checkexisend
        
        extrwi.  r3, r4, 1,5           # returns either 0 or 1, one for byte received ok
        mtlr    r6
        blr

exireceivebyte:
        mflr r0
luup:

        lis r3, 0xA000
        
        bl checkexisend
        
        #rlwinm r7, r4, 16, 24, 31
        #andis. r3, r4, 0x800
        andis. r3, r4, 0x800
        beq luup
        rlwinm r3, r4, 16, 24, 31
exireceivebyteisdone:
        mtlr r0
        blr

checkexisend:
        lis r5, 0xCD00
        li      r4,0xd0
        stw r4, 0x6814(r5)
        stw r3, 0x6824(r5)
        li      r4,0x19
        stw r4, 0x6820(r5)

exicheckreceivewait:
        lwz r3, 0x6820(r5)
        andi. r3, r3, 1
        bne exicheckreceivewait
        lwz r4, 0x6824(r5)
        stw r3, 0x6814(r5)
        blr

