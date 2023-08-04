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

	.section .rodata

filename:
	.string "inputs/day14"

moves_x:
	.byte	0				# straight down
	.byte  -1				# down-left
	.byte   1				# down-right

array_limits:
	.dword	0, 999, 0, 499

	.section .bss

coordinates:
	.zero	16

	.section .text

main:
	li	a0, 2
	la	a1, array_limits
	li	a2, 1
	call	create_array
	mv	s0, a0

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
	mv	a0, s0
	la	a1, coordinates
	jr	s8
lir_return:
	ble	a2, s10, not_deeper_rock
	mv	s10, a2
not_deeper_rock:
	call	array_addr
	li	t0, 1
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


	li	s7, 0				# grains counter
loop_grains:
	li	s1, START_X
	li	s2, START_Y
loop_move_down:
	beq	s2, s10, move_failed		# grain has reached the floor and can't go lower
	la	s5, moves_x
	addi	s4, s2, 1
	li	s6, 3
	
loop_try_moves:
	lb	t0, 0(s5)
	add	s3, s1, t0
	mv	a0, s0
	la	a1, coordinates
	sd	s3, 0(a1)
	sd	s4, 8(a1)
	call	array_addr
	lb	t0, 0(a0)
	bnez	t0, move_failed
	mv	s1, s3
	mv	s2, s4
	j	loop_move_down
move_failed:
	inc	s5
	dec	s6
	bnez	s6, loop_try_moves
	# all moves attempts failed, grain of sand comes to rest
	inc	s7
	li	t1, START_X
	li	t2, START_Y
	bne	t1, s1, next2
	bne	t2, s2, next2
	j	end
next2:
	mv	a0, s0
	la	a1, coordinates
	sd	s1, 0(a1)
	sd	s2, 8(a1)
	call	array_addr
	li	t0, 1
	sb	t0, (a0)
	j	loop_grains

end:
	mv	a0, s7
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

x_is_variable:
	sd	s1, 0(a1)
	sd	s7, 8(a1)
	j	lir_return

y_is_variable:
	sd	s7, 0(a1)
	sd	s1, 8(a1)
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

