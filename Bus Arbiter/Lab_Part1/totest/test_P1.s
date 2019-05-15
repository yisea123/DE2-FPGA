.global _start
_start:
movi r2, 0x1010
movi r3, 0x1234
movi r4, 0x2468
movi r5, 0x3579

sthio r2, 0(r1)
sthio r3, 2(r1)
sthio r4, 4(r1)
sthio r5, 6(r1)
.end
