riscv_mp0test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.


start: 
	lw   x1, LVAL4
    lw   x3, LVAL6	

next2:
	beq  x3, x2, goodend
	lw   x1, LVAL4
    lw   x2, LVAL5
    lw   x3, LVAL6
	addi x7, x0, 4
	addi x4, x0, -1

loop:
	lw   x1, LVAL1
    lw   x2, LVAL2
    lw   x3, LVAL3
	addi x6, x0, 6

	add  x7, x7, x4
	bne  x7, x0, loop
	lw   x2, LVAL6
	jal  x0, start 
    

goodend:
	addi x1, x0, 1
	addi x2, x0, 2
    j    goodend

.section .rodata

bad:        .word 0xdeadbeef
LVAL1:	    .word 0x00000020
LVAL2:	    .word 0x000000D5
LVAL3:	    .word 0x0000000F
LVAL4:	    .word 0x00000F0F
LVAL5:	    .word 0x000000FF
LVAL6:	    .word 0x00000004
SVAL1:	    .word 0x00000000
SVAL2:	    .word 0x00000000
SVAL3:	    .word 0x00000000
SVAL4:	    .word 0x00000000
SVAL5:	    .word 0x00000000
SVAL6:	    .word 0x00000000
SVAL7:	    .word 0x00000000
good:       .word 0x600d600d

