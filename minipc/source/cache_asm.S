/*-------------------------------------------------------------

cache_asm.S -- Cache interface

Copyright (C) 2004
Michael Wiedenbauer (shagkur)
Dave Murphy (WinterMute)

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any
damages arising from the use of this software.

Permission is granted to anyone to use this software for any
purpose, including commercial applications, and to alter it and
redistribute it freely, subject to the following restrictions:

1.	The origin of this software must not be misrepresented; you
must not claim that you wrote the original software. If you use
this software in a product, an acknowledgment in the product
documentation would be appreciated but is not required.

2.	Altered source versions must be plainly marked as such, and
must not be misrepresented as being the original software.

3.	This notice may not be removed or altered from any source
distribution.


-------------------------------------------------------------*/


#include "asm.h"
#include "ppc.h"

	.globl DCEnable
DCEnable:
	sync
	mfspr	r3,HID0
	ori		r3,r3,0x4000
	mtspr	HID0,r3
	blr
	.globl DCInvalidateRange
DCInvalidateRange:
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
	dcbi r0, r3
	addi r3, r3, 0x20
	bdnz 2b
	blr

	.globl DCFlushRange
DCFlushRange:
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
	sc
	blr

	.globl ICFlashInvalidate
ICFlashInvalidate:
	mfspr	r3,HID0
	ori		r3,r3,0x0800
	mtspr	HID0,r3
	blr

	.globl ICEnable
ICEnable:
	isync
	mfspr	r3,HID0
	ori		r3,r3,0x8000
	mtspr	HID0,r3
	blr


	.globl L2Init
L2Init:
	mflr	r0
	stw		r0,4(r1)
	stwu	r1,-16(r1)
	stw		r31,12(r1)
	mfmsr	r3
	mr		r31,r3
	sync
	li		r3,48
	mtmsr	r3
	sync
	bl		L2Disable
	bl		L2GlobalInvalidate
	mr		r3,r31
	mtmsr	r3
	lwz		r0,20(r1)
	lwz		r31,12(r1)
	mtlr	r0
	blr

	.globl L2Enable
L2Enable:
	mfspr	r3,L2CR;
	oris	r0,r3,0x8000
	rlwinm	r3,r0,0,11,9
	mtspr	L2CR,r3
	blr

	.globl L2Disable
L2Disable:
	sync
	mfspr	r3,L2CR
	clrlwi	r3,r3,1
	mtspr	L2CR,r3
	sync
	blr

	.globl L2GlobalInvalidate
L2GlobalInvalidate:
	mflr	r0
	stw		r0,4(r1)
	stwu	r1,-8(r1)
	bl		L2Disable
	mfspr	r3,L2CR
	oris	r3,r3,0x0020
	mtspr	L2CR,r3
1:	mfspr	r3,L2CR
	clrlwi	r0,r3,31
	cmplwi	r0,0x0000
	bne		1b
	mfspr	r3,L2CR
	rlwinm	r3,r3,0,11,9
	mtspr	L2CR,r3
2:	mfspr	r3,L2CR
	clrlwi	r0,r3,31
	cmplwi	r0,0x0000
	bne		2b
	lwz		r0,12(r1)
	addi	r1,r1,8
	mtlr	r0
	blr