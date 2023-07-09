	.global _start

	.macro  INC reg
	addi \reg, \reg, 1
	.endm

	.macro  DEC reg
	addi \reg, \reg, -1
	.endm


	.section .rodata

filename:
	.string "inputs/day10"

cycles:
	.half	20, 60, 100, 140, 180, 220, 0

lit_pixel:
	.ascii	"##"

dark_pixel:
	.ascii	"  "

nl:	.ascii	"\n"

	.section .text
_start:
	la      a0, filename
	call    map_input_file

	mv	s0, a0
	add	s11, a0, a1
	
	li	s1, 1			# initialize X

	addi	sp, sp, -240
	mv	s2, sp
	#addi	s2, sp, 1

read_loop:
	sb	s1, 0(s2)		# write X in the stack
	inc	s2
	lb	t0, 0(a0)
	li	t1, 110			# ASCII 'n'
	addi	a0, a0, 5		# advance input pointer to next line or add value
	beq	t0, t1, noop
	sb	s1, 0(s2)		# write X in the stack a second time
	inc	s2
	call	parse_integer		# read addx value
	add	s1, s1, a1		# update X value
	inc	a0			# skip '\n'
noop:
	bne	a0, s11, read_loop

	mv	s1, zero
	la	s2, cycles
	addi	s3, sp, -1		# cycle numbers start at 1
strength_loop:
	lh	t0, 0(s2)		# read cycle number
	beqz	t0, strength_loop_end 	# stop loop if cycle number is null
	add	t1, s3, t0		# compute cycle address
	lb	t2, 0(t1)		# load X value
	mul	t3, t0, t2		# multiply cycle number by X
	add	s1, s1, t3		# add to strength
	addi	s2, s2, 2		# point to next cycle number
	j	strength_loop
strength_loop_end:

	mv	a0, s1
	call	print_int
	



	li	a7, 64			# write
	li	a0,  1			# stdout

	mv	s0, sp
	li	s1, 6			# 6 lines
lines_loop:
	li	s2, 40			# 40 pixels/line
	li	s3, 0			# pixel number
	li	a2, 2			# 1 characters / pixel
pixels_loop:
	lb	s4, 0(s0)		# load sprite position
stop_here:
	addi	t0, s4, -1		# left sprite pixel position
	blt	s3, t0, print_dark	# crt pixel out of sprite
	addi	t0, s4, 1		# right sprite pixel position
	bgt	s3, t0, print_dark	# crt pixel out of sprite
	la	a1, lit_pixel
	j	next_pixel
print_dark:
	la	a1, dark_pixel
next_pixel:
	ecall
	inc	s3
	inc	s0
	dec	s2
	bnez	s2, pixels_loop

	la	a1, nl
	li	a2,  1			# one character
	ecall

	dec	s1
	bnez	s1, lines_loop
	

end:

	li      a7, 93                  # exit
	li      a0, 0                   # EXIT_SUCCESS
	ecall

