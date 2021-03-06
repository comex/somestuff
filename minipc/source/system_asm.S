#include "asm.h"

	.globl __realmode
__realmode:
	clrlwi	r3,r3,2
	mtsrr0	r3
	mfmsr	r3
	rlwinm	r3,r3,0,28,25
	mtsrr1	r3
	rfi

	.globl __configMEM1_24Mb
__configMEM1_24Mb:
	li		r7,0
	lis		r4,0
	addi	r4,r4,2
	lis		r3,0x8000
	addi	r3,r3,0x1ff
	lis		r6,0x100
	addi	r6,r6,2
	lis		r5,0x8100
	addi	r5,r5,0xff
	isync
	mtspr	DBAT0U,r7
	mtspr	DBAT0L,r4
	mtspr	DBAT0U,r3
	isync
	mtspr	IBAT0U,r7
	mtspr	IBAT0L,r4
	mtspr	IBAT0U,r3
	isync
	mtspr	DBAT2U,r7
	mtspr	DBAT2L,r6
	mtspr	DBAT2U,r5
	isync
	mtspr	IBAT2U,r7
	mtspr	IBAT2L,r6
	mtspr	IBAT2U,r5
	isync
	mfmsr	r3
	ori		r3,r3,MSR_DR|MSR_IR
	mtsrr1	r3
	mflr	r3
	mtsrr0	r3
	rfi

	.globl __configMEM1_48Mb
__configMEM1_48Mb:
	li		r7,0
	lis		r4,0
	addi	r4,r4,2
	lis		r3,0x8000
	addi	r3,r3,0x3ff
	lis		r6,0x200
	addi	r6,r6,2
	lis		r5,0x8200
	addi	r5,r5,0x1ff
	isync
	mtspr	DBAT0U,r7
	mtspr	DBAT0L,r4
	mtspr	DBAT0U,r3
	isync
	mtspr	IBAT0U,r7
	mtspr	IBAT0L,r4
	mtspr	IBAT0U,r3
	isync
	mtspr	DBAT2U,r7
	mtspr	DBAT2L,r6
	mtspr	DBAT2U,r5
	isync
	mtspr	IBAT2U,r7
	mtspr	IBAT2L,r6
	mtspr	IBAT2U,r5
	isync
	mfmsr	r3
	ori		r3,r3,MSR_DR|MSR_IR
	mtsrr1	r3
	mflr	r3
	mtsrr0	r3
	rfi

	.globl __configMEM2_56Mb
__configMEM2_56Mb:
	li		r7,0
	lis		r4,0x1000
	addi	r4,r4,2
	lis		r3,0x9000
	addi	r3,r3,0x3ff
	lis		r6,0x1000
	addi	r6,r6,0x2a
	lis		r5,0xd000
	addi	r5,r5,0x7ff
	isync
	mtspr	DBAT4U,r7
	mtspr	DBAT4L,r4
	mtspr	DBAT4U,r3
	isync
	mtspr	IBAT4U,r7
	mtspr	IBAT4L,r4
	mtspr	IBAT4U,r3
	isync
	mtspr	DBAT5U,r7
	mtspr	DBAT5L,r6
	mtspr	DBAT5U,r5
	isync
	mtspr	IBAT5U,r7
	mtspr	IBAT5L,r7
	isync
	lis		r4,0x1200
	addi	r4,r4,2
	lis		r3,0x9200
	addi	r3,r3,0x1ff
	lis		r6,0x1300
	addi	r6,r6,2
	lis		r5,0x9300
	addi	r5,r5,0xff
	isync
	mtspr	DBAT6U,r7
	mtspr	DBAT6L,r4
	mtspr	DBAT6U,r3
	isync
	mtspr	IBAT6U,r7
	mtspr	IBAT6L,r4
	mtspr	IBAT6U,r3
	isync
	mtspr	DBAT7U,r7
	mtspr	DBAT7L,r6
	mtspr	DBAT7U,r5
	isync
	mtspr	IBAT7U,r7
	mtspr	IBAT7L,r6
	mtspr	IBAT7U,r5
	isync
	mfmsr	r3
	ori		r3,r3,MSR_DR|MSR_IR
	mtsrr1	r3
	mflr	r3
	mtsrr0	r3
	rfi

	.globl __configMEM2_64Mb
__configMEM2_64Mb:
	li		r7,0
	lis		r4,0x1000
	addi	r4,r4,2
	lis		r3,0x9000
	addi	r3,r3,0x7ff
	lis		r6,0x1000
	addi	r6,r6,0x2a
	lis		r5,0xd000
	addi	r5,r5,0x7ff
	isync
	mtspr	DBAT4U,r7
	mtspr	DBAT4L,r4
	mtspr	DBAT4U,r3
	isync
	mtspr	IBAT4U,r7
	mtspr	IBAT4L,r4
	mtspr	IBAT4U,r3
	isync
	mtspr	DBAT5U,r7
	mtspr	DBAT5L,r6
	mtspr	DBAT5U,r5
	isync
	mtspr	IBAT5U,r7
	mtspr	IBAT5L,r7
	isync
	mfmsr	r3
	ori		r3,r3,MSR_DR|MSR_IR
	mtsrr1	r3
	mflr	r3
	mtsrr0	r3
	rfi	

	.globl __configMEM2_112Mb
__configMEM2_112Mb:
	li		r7,0
	lis		r4,0x1000
	addi	r4,r4,2
	lis		r3,0x9000
	addi	r3,r3,0x7ff
	lis		r6,0x1000
	addi	r6,r6,0x2a
	lis		r5,0xd000
	addi	r5,r5,0xfff
	isync
	mtspr	DBAT4U,r7
	mtspr	DBAT4L,r4
	mtspr	DBAT4U,r3
	isync
	mtspr	IBAT4U,r7
	mtspr	IBAT4L,r4
	mtspr	IBAT4U,r3
	isync
	mtspr	DBAT5U,r7
	mtspr	DBAT5L,r6
	mtspr	DBAT5U,r5
	isync
	mtspr	IBAT5U,r7
	mtspr	IBAT5L,r7
	isync
	lis		r4,0x1400
	addi	r4,r4,2
	lis		r3,0x9400
	addi	r3,r3,0x3ff
	lis		r6,0x1600
	addi	r6,r6,2
	lis		r5,0x9600
	addi	r5,r5,0x1ff
	isync
	mtspr	DBAT6U,r7
	mtspr	DBAT6L,r4
	mtspr	DBAT6U,r3
	isync
	mtspr	IBAT6U,r7
	mtspr	IBAT6L,r4
	mtspr	IBAT6U,r3
	isync
	mtspr	DBAT7U,r7
	mtspr	DBAT7L,r6
	mtspr	DBAT7U,r5
	isync
	mtspr	IBAT7U,r7
	mtspr	IBAT7L,r6
	mtspr	IBAT7U,r5
	isync
	mfmsr	r3
	ori		r3,r3,MSR_DR|MSR_IR
	mtsrr1	r3
	mflr	r3
	mtsrr0	r3
	rfi

	.globl __configMEM2_128Mb
__configMEM2_128Mb:
	li		r7,0
	lis		r4,0x1000
	addi	r4,r4,2
	lis		r3,0x9000
	addi	r3,r3,0xfff
	lis		r6,0x1000
	addi	r6,r6,0x2a
	lis		r5,0xd000
	addi	r5,r5,0xfff
	isync
	mtspr	DBAT4U,r7
	mtspr	DBAT4L,r4
	mtspr	DBAT4U,r3
	isync
	mtspr	IBAT4U,r7
	mtspr	IBAT4L,r4
	mtspr	IBAT4U,r3
	isync
	mtspr	DBAT5U,r7
	mtspr	DBAT5L,r6
	mtspr	DBAT5U,r5
	isync
	mtspr	IBAT5U,r7
	mtspr	IBAT5L,r7
	isync
	mfmsr	r3
	ori		r3,r3,MSR_DR|MSR_IR
	mtsrr1	r3
	mflr	r3
	mtsrr0	r3
	rfi	

	.extern ICFlashInvalidate
	.globl __PSInit
__PSInit:
	mflr	r0
	stw		r0,4(sp)
	stwu	sp,-8(sp)
	mfspr	r3,HID2
	oris	r3,r3,0xA000
	mtspr	HID2,r3
	bl		ICFlashInvalidate
	sync
	li		r3,0
	mtspr	GQR0,r3
	lwz		r0,12(sp)
	addi	sp,sp,8
	mtlr	r0
	blr

	.extern ICEnable
	.extern DCEnable
	.extern L2Init
	.extern L2Enable
	.globl __CacheInit
__CacheInit:
	mflr    r0
	stw     r0, 4(sp)
	stwu    sp, -16(sp)
	stw     r31, 12(sp)

	mfspr   r3,HID0 # (HID0)
	rlwinm  r0,r3, 0, 16, 16
	cmplwi  r0, 0x0000 # Check if the Instruction Cache has been enabled or not.
	bne     ICEnabled

	bl		ICEnable
ICEnabled:
	mfspr   r3, HID0 # bl       PPCMfhid0
	rlwinm  r0, r3, 0, 17, 17
	cmplwi  r0, 0x0000 # Check if the Data Cache has been enabled or not.
	bne     DCEnabled
	
	bl		DCEnable	
DCEnabled:
	
	mfspr   r3, L2CR # (L2CR)
	clrrwi  r0, r3, 31 # Clear all of the bits except 31
	cmplwi  r0, 0x0000
	bne     L2Enabled

	bl		L2Init
	bl		L2Enable

L2Enabled:
	# Restore the non-volatile registers to their previous values and return.
	lwz     r0, 20(sp)
	lwz     r31, 12(sp)
	addi    sp, sp, 16
	mtlr    r0
	blr

	.globl __SystemInit
__SystemInit:
	mflr    r0
	stw     r0, 4(sp)
	stwu    sp, -24(sp)
	stw     r31, 20(sp)
	stw     r30, 16(sp)
	stw     r29, 12(sp)

	# Disable interrupts!
	mfmsr   r3
	rlwinm  r4,r3,0,17,15
	rlwinm  r4,r4,0,26,24
	mtmsr   r4

	# Clear various SPR's
	li      r3,0
	mtspr   952, r3
	mtspr   956, r3
	mtspr   953, r3
	mtspr   954, r3
	mtspr   957, r3
	mtspr   958, r3

	lis		r3,0x8390		//bits set: H4A(HID4 access), SBE(2nd BAT enabled),  SR0(store 0), LPE(PS LE exception), L2CFI(L2 castout prior to L2 inv. flash)
	mtspr	HID4,r3

	# Disable Speculative Bus Accesses to non-guarded space from both caches.
	mfspr   r3, HID0
	ori     r3, r3, 0x0200
	mtspr   HID0, r3

	# Set the Non-IEEE mode in the FPSCR
	mtfsb1  29
	
	mfspr   r3,HID2 # (HID2)
	rlwinm  r3, r3, 0, 2, 0
	mtspr   HID2,r3 # (HID2)

	# Restore the non-volatile registers to their previous values and return.
	lwz     r0, 28(sp)
	lwz     r31,20(sp)
	lwz     r30,16(sp)
	lwz     r29,12(sp)
	addi    sp, sp, 24
	mtlr    r0
	blr

