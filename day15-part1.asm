	.global main

        .macro  INC reg
        addi \reg, \reg, 1
        .endm

        .macro  DEC reg
        addi \reg, \reg, -1
        .endm

	.set	SYS_EXIT, 93
	.set	EXIT_SUCCESS, 0
	#.set	TARGET_ROW, 10
	.set	TARGET_ROW, 2000000

	.section .rodata

filename:
	#.string "inputs/day15-test"
	.string "inputs/day15"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1
	
	mv	s6, zero					# input lines counter
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

	mv	s4, a0						# save input pointer

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

	addi	sp, sp, -8
	sw	t1, 0(sp)					# first X value
	sw	t2, 4(sp)					# last X value

	inc	s6						# increment counter

skip_sensor:

	mv	a0, s4						# restore input pointer
	inc	a0						# skip '\n'

	blt	a0, s11, read_loop				# loop if EOF no reached

	mv	s0, sp						# save pointer to input data array

before_sort:

	mv 	a0, sp
	mv	a1, s6
	li	a2, 8
	la	a3, compar
	call	quicksort

end_sort:

	# pointer to end of input
	mv	t1, s6
	li	t2, 8
	mul	t1, t1, t2
	add	s11, sp, t1

	# marge ranges

	mv	s1, sp						# copy input pointer
	mv	s2, zero					# initialize counter
merge_loop:
	inc	s2
	lw	t0, 0(s1)					# load first range start
	lw	t1, 4(s1)					# load first range end
	mv	t2, s1						# pointer to next range
merge_loop_in:
	addi	t2, t2, 8					# move pointer to next next range
	bge	t2, s11, merge_loop_in_end			# end if next range pointer is beyond the end of input
	lw	t3, 0(t2)					# load next range start
	lw	t4, 4(t2)					# load next range end
	bgt	t3, t1, merge_loop_next				# next range start is beyond first range end
	ble	t4, t1, merge_loop_in				# next range end is lower than current end
	mv	t1, t4						# next range end is new first range end
	j	merge_loop_in					# loop back
merge_loop_next:
	addi	sp, sp, -8					# store new range on the stack
	sw	t0, 0(sp)
	sw	t1, 4(sp)
	mv	s1, t2						# next range is new first range
	j	merge_loop					# loop beck
merge_loop_in_end:
	addi	sp, sp, -8					# end of input reached, store current range
	sw	t0, 0(sp)
	sw	t1, 4(sp)
merge_loop_end:


	# sum size of all ranges

	mv	s3, zero					# initialize accumulator
count_loop:
	lw	t0, 0(sp)
	lw	t1, 4(sp)
	sub	t2, t1, t0
	inc 	t2
	add	s3, s3, t2
	addi	sp, sp, 8
	dec	s2
	bnez	s2, count_loop

	dec	s3						# beacon present on the target row
	
	mv	a0, s3
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

compar:
	lw	t0, 0(a0)
	lw	t1, 0(a1)
	bne	t0, t1, compar_end
	lw	t0, 4(a0)
	lw	t1, 4(a1)
compar_end:
	sub	a0, t0, t1
	ret

abs:
	bgez	a0, abs_skip
	sub	a0, zero, a0
abs_skip:
	ret

