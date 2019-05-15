.global _start
_start:

	/* Value Numbers*/
	movi r2, 0x1
	movi r3, 0xb
	movi r4, 0x3
	movi r5, 0xc
	
	/* Address of SRAM*/
	movia r6, 0x9000
	movia r7, 0x9002
	movia r8, 0x9004
	movia r9, 0x9006

	/* Store Value Numbers to SRAM */
	stbio r2, 1(r6)
	stbio r3, 0(r7)
	stbio r4, 0(r8)
	stbio r5, 0(r9)
	
	/* Load from SRAM to REG */
	ldbio r10, 1(r6)
	ldbio r11, 0(r7)
	ldbio r12, 0(r8)
	ldbio r13, 0(r9)
	
.end