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

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	la	s10, tail_move

	mv	s1, zero		# head X
	mv	s2, zero		# head Y
	mv	s3, zero		# tail X
	mv	s4, zero		# tail Y

	mv	s6, zero		# min X
	mv	s7, zero		# max X
	mv	s8, zero		# min Y
	mv	s9, zero		# max Y

	li	a6, 5			# width of tail moves matrix
	mv	a7, zero		# coordinates counter

loop:
	lb	s5, 0(a0)		# load direction
	addi	a0, a0, 2		# move input pointer to number of steps
	call	parse_integer
	mv	t3, a1			# copy number of steps to t3
	add	a7, a7, t3		# add number of steps to coordinates counter
	inc	a0			# skip final \n

	li	t1, ASCII_U
	beq	s5, t1, move_up
	li	t1, ASCII_D
	beq	s5, t1, move_down
	li	t1, ASCII_L
	beq	s5, t1, move_left
	j	move_right

loop_move:
	# new head coordinate
	add	s1, s1, t1
	add	s2, s2, t2

	# diff between head and tail coordinates
	sub	t4, s1, s3
	sub	t5, s2, s4

	# -2,2 => 0,4
	addi	t4, t4, 2
	addi	t5, t5, 2

	# compute movment address
	mul	t6, t5, a6 		# index = y * 5
	add	t6, t6, t4		# index = index + x
	add	t6, t6, t6		# offset = index * 2 (16 bits data)
	add	t6, t6, s10		# address = offset + matrix address

	# load tail movements
	lb	t4, 0(t6)
	lb	t5, 1(t6)

	# new tail coordinates
	add	s3, s3, t4
	add	s4, s4, t5

	# store tail coordinates
	addi	sp, sp, -16
	sd	s3, 0(sp)
	sd	s4, 8(sp)

	# check if new coordinates bounds
	bge	s3, s6, skip1		# new min X ?
	mv	s6, s3
	j	skip2
skip1:
	ble	s3, s7, skip2		# new max X ?
	mv	s7, s3
skip2:
	bge	s4, s8, skip3		# new min Y ?
	mv	s8, s4
	j	skip4
skip3:
	ble	s4, s9, skip4		# new max Y ?
	mv	s9, s4
skip4:
	

	DEC	t3	
	bnez	t3, loop_move		# loop if countdown not null

	bne	a0, s11, loop		# loop if eof not reached

	mv	s1, a7			# move coordinates counter to s1
	mv	s2, sp			# store tail coordinates pointer to s2
	mv	s3, zero		# initialize unique coordinates counter

	# store array bounds in the stack
	addi	sp, sp, -32
	sd	s6,  0(sp)
	sd	s7,  8(sp)
	sd	s8, 16(sp)
	sd	s9, 24(sp)

	# create visited coordinates matrix
	li	a0, 2			# rank 2
	mv	a1, sp			# bounds stored in stack
	li	a2, 1			# 1-byte elements
	call	create_array
	mv	s4, a0

loop_count:
	mv	a0, s4			# array address
	mv	a1, s2			# coordinates
	call	array_addr_safe
	lb	t0, 0(a0)		# read visited flag
	bnez	t0, skip_new_unique	# skip if visited
	INC	s3			# increase unique coordinates counter
	li	t1, 1			
	sb	t1, 0(a0)		# set visited flag
skip_new_unique:
	addi	s2, s2, 16		# move to next coordinates
	DEC	s1			# decrement countdown
	bnez	s1, loop_count		# loop in countdown not null

	mv	a0, s3
	call	print_int
	
	li      a7, 93                  # exit
	li      a0, 0                   # EXIT_SUCCESS
	ecall

move_up:
	li	t1,  0			# x = x
	li	t2, -1			# y = y - 1
	j	loop_move
move_left:
	li	t1, -1			# x = x - 1
	li	t2,  0			# y = y
	j	loop_move
move_down:
	li	t1,  0			# x = x
	li	t2,  1			# y = y + 1
	j	loop_move
move_right:
	li	t1,  1			# x = x + 1
	li	t2,  0			# y = y
	j	loop_move
	
	.end

