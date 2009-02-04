#include "ppc.h"
.section .init
.globl go_lock
.globl go_unlock
.globl exisendbuffer
.globl exireceivebuffer
.globl exireceivebigbuffer
.globl exisendbyte
.globl exireceivebyte
.globl exireceivebuffer_stack
.globl exisendword
.globl _start
_start:
# 3-12 are volatile

# Awful lock. clob r3-5
go_lock:
    lis r3, 0x8000
    ori r3, r3, 0x2ff0
    li r5, 1
    b lock_loop
lock_loop_t:
	stwcx. r4, 0, r3
lock_loop:
	lwarx r4, 0, r3
	cmpwi r4, 1
	beq lock_loop_t
	stwcx. r5, 0, r3
	bne- lock_loop
	# It's locked.
     blr
go_unlock:
    lis r3, 0x8000
    ori r3, r3, 0x2ff0
    li r4, 0
    stw r4, 0(r3)
    blr

# None of these functions use the stack, but they clobber r3-r10.
# About 250 bytes.
# Plan: 
# ES_OpenContent blah blah
# lis r3,     0x8000
# ori r3, r3, 0x1800 or so
# mtctr r3
# bctr
# ------- at 1800 -----
# not r4, r3
# slwi. r4, r4, 16 # cmp to 0, i.e. is r3 0xFFFFxxxx?
# beq overridefunc
# # do whatever happened in first 4 instrs
# lis r3, ori r3, mtctr, bctr
# ...
# overridefunc:

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

exireceivebuffer_stack:
    # void exireceivebuffer(int num, void *buf)
    # clobbers only r0
    mflr r0
    stwu r0, -4(r1)
    stwu r1, -4(r1)
    stwu r3, -4(r1)
    stwu r4, -4(r1)
    stwu r5, -4(r1)
    stwu r6, -4(r1)
    stwu r7, -4(r1)
    stwu r8, -4(r1)
    stwu r9, -4(r1)
    stwu r10, -4(r1)
    bl exireceivebuffer
    lwz r10, 0(r1)
    lwzu r9, 4(r1)
    lwzu r8, 4(r1)
    lwzu r7, 4(r1)
    lwzu r6, 4(r1)
    lwzu r5, 4(r1)
    lwzu r4, 4(r1)
    lwzu r3 ,4(r1)
    lwzu r0, 8(r1)
    addi r1, r1, 4
    mtlr r0
    blr
exireceivebyteplx:
        mflr r0
        li r6, 0xff
        li r3, 0
luuplx:
        subi r6, r6, 1
        cmpwi r6, 0
        ble luuplxret
        lis r3, 0xA000
        bl checkexisendplx
        andis. r3, r4, 0x800
        beq luuplx
        rlwinm r3, r4, 16, 24, 31  
luuplxret:
        mtlr r0
        blr

checkexisendplx:
        lis r5, 0xCD00
        li      r4,0xd0
        stw r4, 0x6814(r5)
        stw r3, 0x6824(r5)
        li      r4,0x19
        stw r4, 0x6820(r5)

exicheckreceivewaitplx:
        subi r6, r6, 1
        cmpwi r6, 0
        blelr
        lwz r3, 0x6820(r5)
        andi. r3, r3, 1
        bne exicheckreceivewaitplx
        lwz r4, 0x6824(r5)
        stw r3, 0x6814(r5)
        blr
exicheckreceiveplx:
    mflr r0
    lis r6, 0x10 # 0x100000
exicheckreceiveloopplx:
    subi r6, r6, 1
    cmpwi r6, 0
    ble exicheckreceiveloopplxret
    lis r3, 0xD000
    bl checkexisendplx
    rlwinm. r3, r4, 6, 31, 31 # returns either 0 or 1 for r3 
    beq exicheckreceiveloopplx
exicheckreceiveloopplxret:
    mtlr r0
    blr
exireceivebigbuffer: # void exireceivebigbuffer(int num, void *buf)
    mflr r12
    mr r11, r3 # num
    mr r10, r4 # buf 
    li r3, 0x1d
    bl exisendbyte
    bl exireceiveword # the real size
    mr r11, r3
bbbigloop:
    li r3, 1024
    cmpw r3, r11
    ble bbskip1
    mr r3, r11
bbskip1:
    mtctr r3
    
    mr r8, r10
    li r9, 0
pktloop: # r8 = the starting pos
    bl exicheckreceiveplx
    bl exireceivebyteplx
    stbx r3, r9, r8
    addi r9, r9, 1
    bdnz pktloop


    li r3, 0x1c
    bl exisendbyte

    # What should the cs be
    bl exireceiveword
    mr r6, r3

    
    
    # Okay, now sum it
    mr r8, r10
    li r3, 1024
    cmpw r3, r11
    ble bbskip2
    mr r3, r11
bbskip2:    
    mtctr r3
    li r9, 0
    li r4, 0
sumloop:
    lbzx r3, r9, r8
    add r4, r4, r3
    addi r9, r9, 1
    bdnz sumloop

    mr r9, r4
    cmpw r4, r6
    beq bbcont
    # it failed :(
    li r3, 0x1e
    bl exisendbyte
    #mr r3, r9
    #bl exisendword
    b bbbigloop
bbcont:
    li r3, 0x1f
    bl exisendbyte
    addi r10, r10, 1024 # increase the memory address
    subi r11, r11, 1024 # and decrease the bytes remaining
    cmpwi r11, 0 # are we done?
    ble bbyesweare
    b bbbigloop
bbyesweare:
    mtlr r12
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

.align 8
ES_OpenTitleContentFile_replacement:

    mflr r12
    mr r8, r3
    mr r9, r4
    mr r10, r5
    mr r11, r6    

    bl go_lock
    li r3, 0x13
    bl exisendbyte
    nop
    nop
    li r3, 0x37
    bl exisendbyte    

    
    li r3, 'z'     # REMOVE
    bl exisendbyte # THIS

    
    li r3, '1'
    bl exisendbyte
    

    
    mr r3, r8
    bl exisendword
    mr r3, r9
    bl exisendword
    mr r3, r10
    bl exisendword
    mr r3, r11
    bl exisendword
    
    # okay
    bl exireceiveword
    #bl exisendword
    cmpwi r3, 0
    beq otcf_restore 
    mr r12, r3
    bl go_unlock
    mr r3, r12
    mtlr r7
    blr
    
    
otcf_restore:
    bl go_unlock
    mr r3, r8
    mr r4, r9
    mr r5, r10
    mr r6, r11
    # this is going to be overwritten
    mtlr r12
CRAP:

    # four arguments r3-r6
    # r5 might equal 0, in fact, usually is
    # RRRRRRRR
    # do stuff from the function
    clrlwi r11, r1, 27
    mr r12, r1
    subfic r11, r11, -0x120
    stwux r1, r1, r11
    # time to go home.
    mr r0, r7
    blr
    #lis r0, 0x8159
    #addi r0, r0, 0x4984
    #mtctr r0
    #bctr

.align 8
ES_ReadContentFile_replacement:
    # ES_ReadContentFile(cfd, data, size)    
    mflr r12

    mr r8, r3
    mr r9, r4
    mr r10, r5



    bl go_lock
    li r3, 0x14
    bl exisendbyte

    mr r3, r8
    bl exisendword
    mr r3, r9
    bl exisendword
    mr r3, r10
    bl exisendword

    bl go_unlock

    mr r3, r8
    mr r4, r9
    mr r5, r10

    lis r6, 1 # r6 = 0x10000
    cmpw r3, r6
    bgt magic # it's a fake cfd
    # ok, psh
    mtlr r12
    
    clrlwi r11, r1, 27
    mr r12, r1
    subfic r11, r11, -0x120
    stwux r1, r1, r11
    mr r0, r7
    
    blr
    #lis r0, 0x8159
    #ori r0, r0, 0x4a1c
    #mtctr r0
    #bctr
magic:
    mr r8, r5
    mr r9, r4
    bl go_lock
    li r3, 0xed
    bl exisendbyte
    mr r3, r8
    mr r4, r9
    bl exireceivebigbuffer
    bl exireceiveword
    mr r8, r3
    bl exisendword
    bl go_unlock
    mr r3, r8
    mtlr r7
    blr


.align 8
ES_SeekContentFile_replacement:
    # ES_SeekContentFile(cfd, where, whence)
    
    
    mflr r12

    mr r8, r3
    mr r9, r4
    mr r10, r5



    bl go_lock
    li r3, 0x15
    bl exisendbyte

    mr r3, r8
    bl exisendword
    mr r3, r9
    bl exisendword
    mr r3, r10
    bl exisendword
    bl go_unlock

    mr r3, r8
    mr r4, r9
    mr r5, r10
    
    lis r6, 1 # r6 = 0x10000
    cmpw r3, r6
    bgt magic2 # it's a fake cfd
    
    mtlr r12
    # ok, psh
    clrlwi r11, r1, 27
    mr r12, r1
    subfic r11, r11, -0x120
    stwux r1, r1, r11
    mr r0, r7
    blr
magic2:
    bl go_lock
    li r3, 0xee
    bl exisendbyte
    bl exireceiveword
    mr r8, r3
    bl exisendword
    bl go_unlock
    mr r3, r8
    mtlr r7
    blr

.align 8
ES_CloseContentFile_replacement:
    # ES_CloseContentFile(cfd)
    mflr r12

    mr r8, r3

    bl go_lock
    li r3, 0x16
    bl exisendbyte

    mr r3, r8
    bl exisendword
    bl go_unlock

    mr r3, r8
    
        
    lis r6, 1 # r6 = 0x10000
    cmpw r3, r6
    bgt magic3 # it's a fake cfd
    
    mtlr r12
    # ok, psh
    clrlwi r11, r1, 27
    mr r12, r1
    subfic r11, r11, -0x120
    stwux r1, r1, r11
    
    mr r0, r7
    blr
magic3:
    bl go_lock
    li r3, 0xef
    bl exisendbyte
    
    mr r3, r7
    bl exisendword
    
    bl exireceiveword
    mr r8, r3
    bl go_unlock
    mr r3, r8
    mtlr r7
    blr


.align 8
FileWrite_replacement:
    mr r8, r5
    mr r9, r4

    bl go_lock

    li r3, 0x17
    bl exisendbyte

    bl go_unlock
    mtlr r7
    blr


    mr r3, r8
    bl exisendword

    mr r3, r8
    mr r4, r9
    bl exisendbuffer

    bl go_unlock

    mtlr r7
    blr

#if 0
# Making this is important, but it's on hold for now.
load_dol_from_gecko:
    # todo: implement this based on dol.c
    stwu r1, -240(r1) # 228 + 12
    
    li r3, 'd' # get dol header
    bl exisendbyte
    addi r4, r1, 12 # Load to the stack...
    li r3, 228 # 228 bytes from the gecko.
    bl exireceivebuffer
    
    
    ;# for(i = 0; i < 7; i++)
    li r3, 7
    mtctr r3
    li r12, 0

#-----------
ldfg1:
    addi r3, r1, 156 # text_size = 144, + 12
    addi r4, r1, 84 # text_start = 72, + 12
    addi r5, r1, 12 # text_pos = 0, +12
    lwz r7, r12(r3)
    lwz r8, r12(r4)
    lwz r9, r12(r5)
    cmpwi r7, 0
    beq ldfg_cont1
    cmpwi r8, 0x100
    blt ldfg_cont1
    
    # loading text section
    
    mr r3, r8
    mr r4, r7
    bl ICInvalidateRange

    li r3, 'e' # get dol bit
    bl exisendbyte
    mr r3, r9 # pos
    bl exisendword
    mr r3, r7 # size
    bl exisendword
    
    mr r3, r7 # size
    mr r4, r8 # memory location
    bl exireceivebuffer_stack

ldfg_cont1:

    addi r12, r12, 4 # four bytes offset
    bdnz ldfg1
#------------

    addi r1, r1, 240
    blr
ICInvalidateRange: # clobber 3-5 / ICInvalidateRange(start, sizw)
        cmplwi r4, 0   # zero or negative size?
        blelr
        clrlwi. r5, r3, 27  # check for lower bits set in address
        beq 1f
        addi r4, r4, 0x20
1:
        addi r4, r4, 0x1f
        srwi r4, r4, 5
        mtctr r4
2:
        icbi r0, r3
        addi r3, r3, 0x20
        bdnz 2b
        sync
        isync
        blr

DCFlushRangeNoSync: # same
        cmplwi r4, 0   # zero or negative size?
        blelr
        clrlwi. r5, r3, 27  # check for lower bits set in address
        beq 1f
        addi r4, r4, 0x20
1:
        addi r4, r4, 0x1f
        srwi r4, r4, 5
        mtctr r4
2:
        dcbf r0, r3
        addi r3, r3, 0x20
        bdnz 2b
        blr
#endif
