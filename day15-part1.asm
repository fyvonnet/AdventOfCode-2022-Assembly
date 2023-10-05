	.global main

        .macro  INC reg
        addi \reg, \reg, 1
        .endm

        .macro  DEC reg
        addi \reg, \reg, -1
        .endm

	.set	SYS_EXIT, 93
	.set	EXIT_SUCCESS, 0
	.set	TARGET_ROW, 2000000

	.section .rodata

filename:
	.string "inputs/day15"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1
	
	mv	s6, zero					# input lines counter
	mv	s7, zero					# min
	mv	s8, zero					# max
	li	s9, TARGET_ROW

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

	mv	s4, a0

	sub	a0, s0, s2
	call	abs
	mv	s5, a0

	sub	a0, s1, s3
	call	abs
	add	s5, s5, a0					# manhattan distance sensor <=> beacon

	li	t0, TARGET_ROW
	sub	a0, s1, t0
	call	abs						# distance sensor <=> target row

	blt	s5, a0, skip_sensor				# skip if sensor doesn't reach target row

	sub	t0, s5, a0					# remaining distance along the target row
	sub	t1, s0, t0
	add	t2, s0, t0
	sub	t3, s3, s9					# beacon distance from target row in Y

	addi	sp, sp, -16
	sw	t1, 0(sp)					# first X value
	sw	t2, 4(sp)					# last X value
	sw	t3, 8(sp)
	sw	s2, 12(sp)					# beacon X coordinate

	inc	s6						# increment counter

	# check for new minimum
	bge	t1, s7, skip1
	mv	s7, t1
skip1:

	# check for new maximum
	blt	t2, s8, skip2
	mv	s8, t2
skip2:


skip_sensor:

	mv	a0, s4
	inc	a0						# skip '\n'

	blt	a0, s11, read_loop				# loop if EOF no reached

	mv	s0, sp						# save pointer to input data array

	# compute number of elements for the booleans array
	sub	s1, s8, s7
	inc	s1

	sub	sp, sp, s1					# allocate booleans array
	sub	s2, sp, s7					# compute address of element 0

	# zero boolean array
	mv	t0, sp
loop_zero:
	sw	zero, 0(t0)
	inc	t0
	ble	t0, s0, loop_zero

	mv	t3, s0						# data pointer
	mv	t4, s6						# countdown
	li	t2, 1
loop_line:
	lw	t0, 0(t3)
	lw	t1, 4(t3)
	add	t5, s2, t0
loop_elm:
	sb	t2, 0(t5)
	inc	t0
	inc 	t5
	ble	t0, t1, loop_elm
	dec	t4
	addi	t3, t3, 16
	bnez	t4, loop_line


	mv	t3, s0						# data pointer
	mv	t4, s6						# countdown
loop_line2:
	lw	t0, 8(t3)
	bnez	t0, skip_loop_line2
	lw	t0, 12(t3)
	add	t5, s2, t0
	sb	zero, 0(t5)
skip_loop_line2:
	addi    t3, t3, 16
	dec	t4
	bnez    t4, loop_line2


stop_here:

	mv	a0, zero					# initialize counter
loop_count:
	lb	t0, 0(sp)
	add	a0, a0, t0
	inc	sp
	dec	s1
	bnez	s1, loop_count

	call	print_int

#	li	s0, 1						# counter
#	lw	s1, 0(sp)
#loop_count:
#	dec	s10
#	addi	sp, sp, 4
#	lw	t0, 0(sp)
#	beq	t0, s1, skip_loop_count
#	inc	s0
#	mv	s1, t0
#skip_loop_count:
#	bgtz	s10, loop_count

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

compar:
	lw	t0, 0(a0)
	lw	t1, 0(a1)
	sub	a0, t0, t1
	ret

abs:
	bgez	a0, abs_skip
	sub	a0, zero, a0
abs_skip:
	ret

