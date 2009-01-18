#include <ogc/machine/asm.h>

	.globl _start
_start:
        lis r1, 0x11
        ori r1, r1, 0xcc64
        isync;# To prevent locking during a cache access, an isync instruction must precede the setting of ILOCK.
        mtspr HID0, r1

        isync
        li r4, 0x2000 ;#Floating point enable.  Interrupts still disabled.
        mtmsr   r4

        isync
        # Reset BATs.
        li r0, 0
        mtspr IBAT0U, r0
        mtspr IBAT1U, r0
        mtspr IBAT2U, r0
        mtspr IBAT3U, r0
        mtspr IBAT4U, r0
        mtspr IBAT5U, r0
        mtspr DBAT0U, r0
        mtspr DBAT1U, r0
        mtspr DBAT2U, r0
        mtspr DBAT3U, r0
        mtspr DBAT4U, r0
        mtspr DBAT5U, r0
        isync

        # Set segment registers.
        # T is set to 1 so we get a "direct-store segment"
        # This doesn't do anything unless BAT fails
        lis r4, 0x8000
        mtsr 0, r4
        mtsr 1, r4
        mtsr 2, r4
        mtsr 3, r4
        mtsr 4, r4
        mtsr 5, r4
        mtsr 6, r4
        mtsr 7, r4
        mtsr 8, r4
        mtsr 9, r4
        mtsr 10, r4
        mtsr 11, r4
        mtsr 12, r4
        mtsr 13, r4
        mtsr 14, r4
        mtsr 15, r4
        isync

        # Set up BATs.  Note that if I switch the order of the BATs,
        # we still come back fine, but reloading back to HBC fails.

        # Cached MEM1 (based on libogc)
        lis             r4,0
        addi    r4,r4,2
        lis             r3,0x8000
        addi    r3,r3,0x1fff ;# a 256MB BAT.  The size could be reduced, but be careful you don't exclude the registers...
        isync
        mtspr   DBAT0L,r4
        mtspr   DBAT0U,r3
        isync
        mtspr   IBAT0L,r4
        mtspr   IBAT0U,r3
        isync

        # Cached MEM2
        lis r4, 0x1000
        addi r4, r4, 2
        lis r3, 0x9000
        addi r3, r3, 0x1fff
        mtspr DBAT4L, r4
        mtspr DBAT4U, r3
        isync
        mtspr IBAT4L, r4
        mtspr IBAT4U, r3
        isync

        # Uncached MEM1 & HW registers
        li r6, 0x2a
        lis             r5,0xc000 
        addi    r5,r5,0x1fff
        isync
        mtspr   DBAT1L,r6
        mtspr   DBAT1U,r5
        isync
        mtspr   IBAT1L,r6
        mtspr   IBAT1U,r5
        isync

        # Uncached MEM2
        lis r4, 0x1000
        addi r4, r4, 0x2a
        lis r3, 0xd000
        addi r3, r3, 0x1fff
        mtspr DBAT2L, r4
        mtspr DBAT2U, r3
        isync
        mtspr IBAT2L, r4
        mtspr IBAT2U, r3
        isync

        # turn on translation (set IR, DR)
        mfmsr   r3
        ori             r3,r3,MSR_DR|MSR_IR
        mtsrr1  r3

        lis r3, 0x8000
        addi r3, r3, 0x4000
        mtsrr0  r3
        #isync

        rfi
        nop
.align 8
