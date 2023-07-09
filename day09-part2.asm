	.global main

	.set	ASCII_ZERO, 	48
	.set	ASCII_U, 	85
	.set	ASCII_D,	68
	.set	ASCII_L,	76
	.set	ASCII_R,	82

	.macro  INC reg
	addi \reg, \reg, 1
	.endm

	.macro  DEC reg
	addi \reg, \reg, -1
	.endm

	.section .rodata

filename:
	.string "inputs/day09"

tail_move:
	.byte -1, -1,    -1, -1,    0, -1,     1, -1,    1, -1
	.byte -1, -1,     0,  0,    0,  0,     0,  0,    1, -1
	.byte -1,  0,     0,  0,    0,  0,     0,  0,    1,  0
	.byte -1,  1,     0,  0,    0,  0,     0,  0,    1,  1
	.byte -1,  1,    -1,  1,    0,  1,     1,  1,    1,  1

	.section .bss

rope_tail:
	.zero	36 			# allocate space for the 9 tail knot's coordinates

	.section .text

main:
	la      a0, filename
	call    map_input_file
	mv	s0, a0
	add	s11, a0, a1

	call	set_new
	mv	s6, a0

	la	s10, tail_move

	mv	s1, zero		# head X
	mv	s2, zero		# head Y
	mv	s5, zero		# unique coordinates counter

loop:
	lb	t2, 0(s0)		# load direction
	li	t1, ASCII_U
	beq	t2, t1, move_up
	li	t1, ASCII_D
	beq	t2, t1, move_down
	li	t1, ASCII_L
	beq	t2, t1, move_left
	j	move_right
back:

	addi	a0, s0, 2		# move input pointer to number of steps
	call	parse_integer
	mv	s9, a1			# copy number of steps to s9
	addi	s0, a0, 1		# skip final \n

loop_move:
	# new head coordinate
	add	s1, s1, s7
	add	s2, s2, s8

	# copy the head coordinates as previous knot coordinates
	mv	t2, s1
	mv	t3, s2

	la	s3, rope_tail		# point to the tail of the rope
	li	s4, 9			# initialize countdown (9 tail knots)

loop_knots:
	# copy previous knot's coordinates
	mv	t0, t2
	mv	t1, t3

	# load current knot's old coordinates
	lh	t2,  0(s3)
	lh	t3,  2(s3)

	# compute previous knot's relative coordinates
	sub	t4, t0, t2
	sub	t5, t1, t3

	# convert relative coordinates as matrix coordinates
	# ([-2,2] => [0,4])
	addi	t4, t4, 2
	addi	t5, t5, 2

	# compute knot's movement values address
	li	t0, 5
	mul	t6, t5, t0 		# index = y * 5
	add	t6, t6, t4		# index = index + x
	add	t6, t6, t6		# offset = index * 2 (16 bits data)
	add	t6, t6, s10		# address = offset + matrix address

	# load knot movements
	lb	t4, 0(t6)
	lb	t5, 1(t6)

	# new knot coordinates
	add	t2, t2, t4
	add	t3, t3, t5

	# save new coordinates
	sh	t2, 0(s3)
	sh	t3, 2(s3)

	addi	s3, s3, 4		# point to next knot
	dec	s4			# decrease countdown
	bnez	s4, loop_knots		# loop if countdown not null

	# insert coordinates of the last knot in the set
	# set_insert returns 1 if the coordinate is inserted successfully or 0 if already present
	mv	a0, s6
	mv	a1, t2
	mv	a2, t3
	call	set_insert
	add	s5, s5, a0

	DEC	s9	
	bnez	s9, loop_move		# loop if countdown not null

	bne	s0, s11, loop		# loop if eof not reached

	mv	a0, s5
	call	print_int

	li      a7, 93                  # exit
	li      a0, 0                   # EXIT_SUCCESS
	ecall

move_up:
	li	s7,  0			# x = x
	li	s8, -1			# y = y - 1
	j	back
move_left:
	li	s7, -1			# x = x - 1
	li	s8,  0			# y = y
	j	back
move_down:
	li	s7,  0			# x = x
	li	s8,  1			# y = y + 1
	j	back
move_right:
	li	s7,  1			# x = x + 1
	li	s8,  0			# y = y
	j	back
	
	.end

