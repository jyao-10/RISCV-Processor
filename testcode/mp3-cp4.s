#  mp3-cp4.s version 1.0
.align 4
.section .text
.globl _start
_start:

	# cache-line boundary (Just getting here should cache-miss on the L1 instr and L2 cache)
	lw   x2, 1(x0)    # x2 <- 3 (# of cache miss for L1 instr)
	lw   x3, 5(x0)    # x3 <- 4 (# of cache miss for L2)
	lw   x4, 0(x0)    # x4 <- 28 (# of cache hits for L1 instr) (23 to get to 0x60, 3 to get to this instr, 2 to get to mem stage for this inst)
	beq  x2, x3, gg   # ensure cache miss l1 instr != cache miss l2
	lw   x5, 2(x0)    # x5 <- 0 (# of cache hit for L1 data)
	lw   x6, 4(x0)    # x6 <- 4 (# of cache hit for L2)
	nop
	beq  x0, x0, kek
	
	# register values at this point
	# x1 <- 0x0
	# x2 <- 3
	# x3 <- 4
	# x4 <- 28
	# x5 <- 0
	# x6 <- 4

kek:
	lw   x7, 6(x0) # x7 <- 1 (# of mispredicts)
	lw   x8, 7(x0) # x8 <- 2 (# of branches total)
	lw   x9, 8(x0) # x9 <- (# of cycles stalled)
	
	# cache-line boundary (Just getting here should cache-miss on the L1 instr and L2 cache)	
	nop
	nop
	nop
	nop
	nop
	nop

	# register values at this point
	# x1 <- 0x0
	# x2 <- 3
	# x3 <- 4
	# x4 <- 28
	# x5 <- 0
	# x6 <- 4
	# x7 <- 1
	# x8 <- 2
	# x9 <- (some large number)
halt:
	beq  x0, x0, halt

gg:
	lw   x10, GGFF15

.section .rodata
.balign 256
DataSeg:
	nop
	nop
	nop
	nop
	nop
	nop
GGFF15:    		.word 0xFFBADBAD

