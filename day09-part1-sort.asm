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
	addi	sp, sp, -4
	sh	s3, 0(sp)
	sh	s4, 2(sp)

	DEC	t3	
	bnez	t3, loop_move		# loop if countdown not null

	bne	a0, s11, loop		# loop if eof not reached

	mv	s1, a7			# move coordinates counter to s1
	mv	s2, sp			# store tail coordinates pointer to s2

	mv	a0, s2
	mv	a1, s1
	li	a2, 4			# pairs of 16-bits coordinates are sorted as single 32-bits values
	la	a3, compar
	call	quicksort

stop_here:
	li	s3, 1			# initialize unique coordinates counter
	lw	s4, 0(s2)		# load first coordinate as reference coordinate
	addi	s2, s2, 4		# start counting at second coordinate
	dec	s1
loop_count:
	lw	s5, 0(s2)
	beq	s5, s4, not_new
	inc	s3
	mv	s4, s5
not_new:
	addi	s2, s2, 4
	dec	s1
	bnez	s1, loop_count
	

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

compar:
	lw	a0, 0(a0)
	lw	a1, 0(a1)
	sub	a0, a0, a1
	ret
	
	.end

