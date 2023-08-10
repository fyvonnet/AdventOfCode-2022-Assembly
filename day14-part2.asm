	.global main

        .macro  INC reg
        addi \reg, \reg, 1
        .endm

        .macro  DEC reg
        addi \reg, \reg, -1
        .endm

	.set	SYS_EXIT, 93
	.set	EXIT_SUCCESS, 0
	.set	ASCII_SPACE, 32
	.set	START_X, 500
	.set	START_Y, 0
	.set	EMPTY, 0
	.set	ROCK, 1
	.set	SAND, 2

	.section .rodata

filename:
	.string "inputs/day14"

moves_x:
	.byte	0				# straight down
	.byte  -1				# down-left
	.byte   1				# down-right

	.section .bss

matrix:
	#500x1000
	.zero	500000

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1
	
	mv	s10, zero			# max depth before floor

loop_read_input:


	call	read_pair
	mv 	s1, a1
	mv	s2, a2
loop_read_line:
	addi	a0, a0, 4			# skip " => "
	call	read_pair
	mv 	s3, a1
	mv	s4, a2

	sub	t0, s3, s1
	bgtz	t0, x_in_order
	bltz	t0, x_in_reverse
	# x is constant
	sub	t0, s4, s2
	bgtz	t0, y_in_order
	bltz	t0, y_in_reverse

x_in_order:
	mv	s5, s1
	mv	s6, s3
	mv	s7, s2
	la	s8, x_is_variable
	j	next

x_in_reverse:
	mv	s5, s3
	mv	s6, s1
	mv	s7, s2
	la	s8, x_is_variable
	j	next

y_in_order:
	mv	s5, s2
	mv	s6, s4
	mv	s7, s3
	la	s8, y_is_variable
	j	next

y_in_reverse:
	mv	s5, s4
	mv	s6, s2
	mv	s7, s3
	la	s8, y_is_variable

	# s1 and s2 are now free until next cycle

next:
	mv	s9, a0				# save input pointer
	mv	s1, s5				# copy start coordinate
loop_insert_rocks:
	jr	s8
lir_return:
	ble	a2, s10, not_deeper_rock
	mv	s10, a2
not_deeper_rock:
	call	array_addr
	li	t0, ROCK
	sb	t0, 0(a0)
	inc	s1
	ble	s1, s6, loop_insert_rocks

	# end of segment becomes beginning of new segment
	mv	s1, s3
	mv	s2, s4

	mv	a0, s9				# restore input pointer
	lb	t0, 0(a0)
	li	t1, ASCII_SPACE
	beq	t0, t1, loop_read_line

	# end of line reached

	inc	a0				# skip '\n'
	blt	a0, s11, loop_read_input

	# end of input reached

	addi	s10, s10, 1			# last grain of sand one level below the lowest rock



	# build pile of sand from top to bottom instead of simulating the fall of each grain of sand


	li	s7, 1				# grains counter
	li	s1, 1				# initialize depth (Y coordinate)
	li	s2, START_X			# initializing starting X coordinate
	li	s3, START_X			# initializing ending X coordinate

	# insert one grain of sand at the pouring coordinate
	li	a0, START_X
	li	a1, START_Y
	call	array_addr
	li	t1, SAND
	sb	t1, 0(a0)

	li	s9, SAND

depth_loop:
	dec	s2				# decrement lower X limit
	inc	s3				# increment upper X limit
	mv	s4, s2				# start X at lower limit
width_loop:
	# check if rock is present at current coordinate
	mv	a0, s4
	mv	a1, s1
	call	array_addr
	lb	t0, 0(a0)
	bnez	t0, skip_grain

	# count number of grains above the current one
	mv	s6, zero			# initialize above grains count
	li	s8, 3				# initialize countdown
	addi	s11, s1, -1
	addi	s5, s4, -1
above_loop:
	#la	a1, coordinates
	#sd	s5, 0(a1)
	#mv	a0, s0
	mv	a0, s5
	mv	a1, s11
	call	array_addr
	lb	t0, 0(a0)
	bne	t0, s9, skip_inc		# not a grain
	inc	s6				# increase above grains count
skip_inc:
	dec	s8				# decrease countdown
	inc	s5				# increase X ccordinate
	bnez	s8, above_loop

	beqz	s6, skip_grain			# no grains of sand above

	# insert grain of sand
	mv	a0, s4
	mv	a1, s1
	call	array_addr
	li	t0, SAND
	sb	t0, 0(a0)
	inc	s7

skip_grain:

	# end of width loop
	inc	s4
	ble	s4, s3, width_loop

	# end of depth_loop
	inc	s1
	ble	s1, s10, depth_loop
	

	# print result and exit

	mv	a0, s7
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

x_is_variable:
	mv	a0, s1
	mv	a1, s7
	#sd	s1, 0(a1)
	#sd	s7, 8(a1)
	j	lir_return

y_is_variable:
	mv	a0, s7
	mv	a1, s1
	#sd	s7, 0(a1)
	#sd	s1, 8(a1)
	j	lir_return

read_pair:
	addi	sp, sp, -8
	sd	ra, 0(sp)
	call	parse_integer
	mv	a7, a1
	inc	a0				# skip ","
	call	parse_integer
	mv	a2, a1
	mv	a1, a7
	
	ld	ra, 0(sp)
	addi	sp, sp, 8
	ret

array_addr:
	la	t0, matrix
	add	a0, t0, a0
	li	t0, 1000
	mul	a1, a1, t0
	add	a0, a0, a1
	ret
