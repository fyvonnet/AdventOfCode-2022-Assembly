	.globl _start

	.set	ROC, 0
	.set	PAP, 1
	.set	SCI, 2

	.set	LOS, 0
	.set	DRA, 1
	.set	WIN, 2

	.section .rodata

filename:
	.string	"inputs/day02"

	#     opponent's shape:
	#     rock  paper scissor
result:
	.byte DRA,  WIN,  LOS # rock
	.byte LOS,  DRA,  WIN # paper	: player's shape
	.byte WIN,  LOS,  DRA # scissor
shape:
	.byte SCI,  ROC,  PAP # lose
	.byte ROC,  PAP,  SCI # draw	: player's result
	.byte PAP,  SCI,  ROC # win

	.section .text
	
_start:
	li	s1, 0			# score for part 1
	li	s2, 0			# score for part 2
	li	s3, 3			# constant 3
	la	s4, result
	la	s5, shape

	la	a0, filename
	call	map_input_file
	add	s0, a0, a1
loop:
	# get opponent's index component
	lb	t0, 0(a0)
	addi	t0, t0, -65		# 'A'
	mul	t0, t0, s3

	# get player's index component
	lb	t2, 2(a0)
	addi	t2, t2, -88		# 'X'

	# add components
	add	t0, t0, t2

	# PART 1
	add	t1, s4, t0
	lb	t1, 0(t1)		# load player's result
	mul	t1, t1, s3		# multiply by three to obtain result score
	add	s1, s1, t1		# add score to total
	addi	t3, t2, 1		# add one to obtain shape score
	add	s1, s1, t3		# add score to total

	# PART 2
	add	t1, s5, t0
	lb	t1, 0(t1)		# load player's shape
	addi	t1, t1, 1		# add one to obtain shape score
	add	s2, s2, t1		# add score to total
	mul	t3, t2, s3		# multiply by 3 to obtain result score
	add	s2, s2, t3		# add score to total

	addi	a0, a0, 4		# skip to next line
	blt	a0, s0, loop 		# loop if eof not reached

	mv	a0, s1
	call	print_int
	mv	a0, s2
	call	print_int

	li	a7, 93			# exit
	li	a0, 0
	ecall

