#include "asm.h"
#include "ppc.h"
.section .init
.globl _start
_start:
#     li r3, 63
#     bl exisendbyte
    
	bl		InitGPRS			# Initialize the General Purpose Registers
	
#     li r3, 97
#     bl exisendbyte

	bl		FPRInit			 	# Initialize the FPR's
	
#     li r3, 98
#     bl exisendbyte
	
	bl		__PSInit 			# Initialize Paired Singles
	
#     li r3, 99
#     bl exisendbyte
	
	bl		__CacheInit 		# Initialize the system caches
	
#     li r3, 100
#     bl exisendbyte
	
	bl		__SystemInit		# Initialize more cache aspects, clear a few SPR's, and disable interrupts.
	
#     li r3, 101
#     bl exisendbyte
	
	b do_something
	
	
InitGPRS:
	# Clear all of the GPR's to 0
	li      r0,0
	li      r3,0
	li      r4,0
	li      r5,0
	li      r6,0
	li      r7,0
	li      r8,0
	li      r9,0
	li      r10,0
	li      r11,0
	li      r12,0
	li      r14,0
	li      r15,0
	li      r16,0
	li      r17,0
	li      r18,0
	li      r19,0
	li      r20,0
	li      r21,0
	li      r22,0
	li      r23,0
	li      r24,0
	li      r25,0
	li      r26,0
	li      r27,0
	li      r28,0
	li      r29,0
	li      r30,0
	li      r31,0

	lis		sp,__crt0stack@h		    # we take 0x8173FFF0 as the topmost starting point for our stack,this gives us ~128Kb Stack
	ori		sp,sp,__crt0stack@l
	addi	sp,sp,-4
	stw		r0,0(sp)
	stwu	sp,-56(sp)

	lis     r2,_SDA2_BASE_@h
	ori     r2,r2,_SDA2_BASE_@l  # Set the Small Data 2 (Read Only) base register.
	lis     r13,_SDA_BASE_@h
	ori     r13,r13,_SDA_BASE_@l # Set the Small Data (Read\Write) base register.	
	blr

FPRInit:
	# Enable the Floating Point Registers
	mfmsr   r3
	ori     r3,r3,0x2000
	mtmsr   r3
	
	# Clear all of the FPR's to 0
	lis	    r3,zfloat@ha
	lfd	    fr0,zfloat@l(r3)
	fmr     fr1,fr0
	fmr     fr2,fr0
	fmr     fr3,fr0
	fmr     fr4,fr0
	fmr     fr5,fr0
	fmr     fr6,fr0
	fmr     fr7,fr0
	fmr     fr8,fr0
	fmr     fr9,fr0
	fmr     fr10,fr0
	fmr     fr11,fr0
	fmr     fr12,fr0
	fmr     fr13,fr0
	fmr     fr14,fr0
	fmr     fr15,fr0
	fmr     fr16,fr0
	fmr     fr17,fr0
	fmr     fr18,fr0
	fmr     fr19,fr0
	fmr     fr20,fr0
	fmr     fr21,fr0
	fmr     fr22,fr0
	fmr     fr23,fr0
	fmr     fr24,fr0
	fmr     fr25,fr0
	fmr     fr26,fr0
	fmr     fr27,fr0
	fmr     fr28,fr0
	fmr     fr29,fr0
	fmr     fr30,fr0
	fmr     fr31,fr0
	mtfsf   255,fr0

	# Return
	blr

	//r3 = ptr, r4 = fill, r5 = size
	.globl _memset
_memset:
	clrlwi.	r6,r5,29
	srwi	r5,r5,2
	subi	r3,r3,4
	mtctr	r5
1:	stwu	r4,4(r3)
	bdnz	1b
	cmplwi	r6,0
	beq		3f
2:	stbu	r4,1(r3)
	addic.	r6,r6,-1
	bne+	2b
3:	blr

	.globl video_line
video_line:
	mulli	r5,r3,640
	lis		r3,0xC0F0
	mtctr	r5
1:	stwu	r4,4(r3)
	bdnz	1b
	blr

	.section .bss
	.balign 8
__crt0stack_end:
	.space 0x4000
__crt0stack:

	.section .data
	.balign	4
zfloat:
	.double 0.0
