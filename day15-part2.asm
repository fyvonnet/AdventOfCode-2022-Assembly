	.global main

        .macro  INC reg
        addi \reg, \reg, 1
        .endm

        .macro  DEC reg
        addi \reg, \reg, -1
        .endm

	.set	SYS_EXIT, 93
	.set	EXIT_SUCCESS, 0
	.set	LIMIT, 4000000

	.section .rodata

filename:
	.string "inputs/day15"

moves:
	.byte	-1, +1
	.byte	-1, -1
	.byte	+1, -1
	.byte	+1, +1
	.byte	 0

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1
	
	addi	sp, sp, -12
	li	t0, -1
	sw	t0, 0(sp)

read_loop:

	addi	a0, a0, 12					# skip "Sensor at..."
	call	parse_integer
	mv	s0, a1						# sensor X

	addi	a0, a0, 4
	call	parse_integer
	mv	s1, a1						# sensor Y

	addi	a0, a0, 25					# skip ": closest beacon..."
	call	parse_integer
	mv	s2, a1						# beacon X

	addi	a0, a0, 4
	call	parse_integer
	mv	s3, a1						# beacon Y

	mv	s4, a0						# save input pointer

	sub	a0, s0, s2
	call	abs
	mv	s5, a0

	sub	a0, s1, s3
	call	abs
	add	s5, s5, a0					# manhattan distance sensor <=> beacon

	# sotre values on stack
	addi	sp, sp, -12
	sw	s5, 0(sp)
	sw	s0, 4(sp)
	sw	s1, 8(sp)

	mv	a0, s4						# restore input pointer
	inc	a0						# skip '\n'

	blt	a0, s11, read_loop				# loop if EOF no reached


	mv	s0, sp						# copy input pointer

	li	s11, LIMIT


loop_sensors_out:
	lw	t0, 4(s0)
	lw	t1, 8(s0)
	lw	t2, 0(s0)
	inc	t2
	add	t0, t0, t2


	la	s1, moves
loop_movements:
	lb	t3, 0(s1)
	beqz	t3, loop_movements_end
	lb	t4, 1(s1)

	mv	s2, t2						# initialize countdown
loop_steps:							# steps along one border
	bltz	t0, next_step
	bltz	t1, next_step
	bgt	t0, s11, next_step
	bgt	t1, s11, next_step
	mv	s3, sp						# copy sensors pointer
loop_sensors_in:
	lw	t5, 0(s3)
	bltz	t5, end						# not in range of any sensor, end search
	lw	s8, 4(s3)
	lw	s9, 8(s3)
	sub	a0, t0, s8
	call	abs
	mv	s10, a0
	sub	a0, t1, s9
	call	abs
	add	s10, s10, a0
	ble	s10, t5, loop_sensors_in_end			# candidate in range of a sensor, skip other sensors
	addi	s3, s3, 12
	j	loop_sensors_in
loop_sensors_in_end:
next_step:
	add	t0, t0, t3					# X move 1 step
	add	t1, t1, t4					# Y move 1 step
	dec	s2						# decrement countdown
	bgtz	s2, loop_steps					# loop in countdown not zero
	addi	s1, s1, 2
	j	loop_movements
loop_movements_end:
	addi	s0, s0, 12
	j	loop_sensors_out

end:
	
	li	t3, 4000000
	mul	t0, t0, t3
	add	a0, t0, t1
	call	print_int

	li	a7, SYS_EXIT
	li	a0, EXIT_SUCCESS
	ecall

abs:
	bgez	a0, abs_skip
	sub	a0, zero, a0
abs_skip:
	ret

