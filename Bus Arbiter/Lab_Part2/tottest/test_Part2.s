.global _start
_start:

movia r12, 0x08000000
movia r13, 0x08000002
movia r14, 0x08000004
movia r15, 0x08000006

movi r6, 0x1f9a
movi r7, 0x2332
movi r8, 0x1234
movi r9, 0x1a2b

sthio r12, 0(r6)
sthio r13, 0(r7)
sthio r14, 0(r8)
sthio r15, 0(r9)

sthio r6, 0(r12)
sthio r7, 2(r12)
sthio r8, 4(r12)
sthio r9, 6(r12)
.end
