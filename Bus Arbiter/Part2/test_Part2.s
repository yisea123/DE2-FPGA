.global _start
_start:

	/* Value Numbers*/
	movi r6, 0x1
	movi r7, 0xc
	movi r8, 0x3
	movi r9, 0xe

	/* Address of SRAM*/
	movia r10, 0x1000
	movia r11, 0x1002
	movia r12, 0x1004
	movia r13, 0x1006

	/* Write to SRAM */
	sthio r6, 0(r10)
	sthio r7, 0(r11)
	sthio r8, 0(r12)
	sthio r9, 0(r13)

	/*Load from SRAM to REG*/
	ldbio r16, 0(r10)
	ldbio r17, 0(r11)
	ldbio r18, 0(r12)
	ldbio r19, 0(r13)

.end
