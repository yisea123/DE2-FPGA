.include "nios_macros.s"

.equ REG_BASE, 0

.global _start

_start:

	movia r2, REG_BASE /*register base address*/

	movia r3, 0x1234   /*number to write to register*/

	sthio r3, 0(r2)    /*first halfword*/

	roli r3, r3, 4 /*rotate so each register has different value*/

	sthio r3, 2(-2) /*2nd halfword - remember 16 bits words hence 2 addresses*/

	roli r3, r3, 4 /*rotate*/

	sthio r3, 4(r2) /*3rd halfword*/

	roli r3, r3, 4 /*rotate*/

	sthio r3, 6(r2) /*4th halfword*/

br _start

.end
