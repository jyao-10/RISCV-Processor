#  mp3-cp4-ewb.s version 1.0
.align 4
.section .text
.globl _start
_start:



	# because our L2 cache is 5 bit index + 22 bit tag
	# A = 00 offset
	# B = 20
	# C = 40
	# D = 60
	# E = 80
	# F = A0
	# G = C0
	# H = E0

	la x1, DATASTART

	# load something in A (L1: [A, -], L2 <- [A, -])
	lw x2, 0x00(x1)

	# load something in B (L1: [A, B], L2 <- [A, B])
	lw x3, 0x20(x1)

	# write to A (L1: [A, B], L2 <- [A, B])
	lui x4, 0x1111
	sw x4, 0x00(x1)

	# write to B (L1: [A, B], L2 <- [A, B])
	lui x4, 0x2222
	sw x4, 0x20(x1)

	# load something in C (L1: [C, B], L2 <- [A, C])
	lw x5, 0x40(x1)

	# load something in D (L1: [C, D], L2 <- [B, D], EWB <- A)
	lw x6, 0x60(x1)

	# load something in E (L1: [E, D], L2 <- [E, D], EWB <- B, A -> MEM)
	lw x7, 0x80(x1)

	# load something in F (evicts B to EWB)
	# which should halt
	lw x8, 0x80(x1)
	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

halt:
	beq  x0, x0, halt

.section .rodata
.balign 256
DATASTART:
	.word 0xA0000000
	.word 0xA1010101
	.word 0xA2020202
	.word 0xA3030303
	.word 0xA4040404
	.word 0xA5050505
	.word 0xA6060606
	.word 0xA7070707

	.word 0xB0000000
	.word 0xB1010101
	.word 0xB2020202
	.word 0xB3030303
	.word 0xB4040404
	.word 0xB5050505
	.word 0xB6060606
	.word 0xB7070707

	.word 0xC0000000
	.word 0xC1010101
	.word 0xC2020202
	.word 0xC3030303
	.word 0xC4040404
	.word 0xC5050505
	.word 0xC6060606
	.word 0xC7070707

	.word 0xD0000000
	.word 0xD1010101
	.word 0xD2020202
	.word 0xD3030303
	.word 0xD4040404
	.word 0xD5050505
	.word 0xD6060606
	.word 0xD7070707

	.word 0xE0000000
	.word 0xE1010101
	.word 0xE2020202
	.word 0xE3030303
	.word 0xE4040404
	.word 0xE5050505
	.word 0xE6060606
	.word 0xE7070707

	.word 0xF0000000
	.word 0xF1010101
	.word 0xF2020202
	.word 0xF3030303
	.word 0xF4040404
	.word 0xF5050505
	.word 0xF6060606
	.word 0xF7070707


