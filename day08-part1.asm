	.global _start

	.set	ASCII_0, 48
	.set	ASCII_LF, 10
	.set	VERT, 0
	#.set	HORIZ, 1
	.set	HORIZ, 0b00000001
	.set	LEFT_OR_UP, 0
	.set	RIGHT_OR_DOWN, 1

	.macro	vec_index dr xr yr
	mv	\dr, \yr
	mul	\dr, \dr, a2
	add	\dr, \dr, \xr
	.endm

	.section .rodata

filename:
	.string "inputs/day08"
	#.string "inputs/day08-test"

	.section .text
_start:
	la      a0, filename
	call    map_input_file
	mv	s0, a0
	add	s11, a0, a1

	# copy input as a single vector in the stack and count the number of lines

	addi	a0, sp, -1		# a0 points to the first element of the input
	mv	a2, zero		# initialize rows counter
	li	t1, ASCII_LF
read_loop:
	lb	t0, 0(s0)
	beq	t0, t1, reached_eol
	addi	t0, t0, -ASCII_0
	addi	sp, sp, -1
	sb	t0, 0(sp)
	addi	s0, s0, 1
	j 	read_loop
reached_eol:
	addi	a2, a2, 1
	addi	s0, s0, 1
	blt	s0, s11, read_loop

	# create a null-initialized visible tree vector the same size of the input

	addi	a1, sp, -1		# a1 points to the first element of the vector
	mul	t0, a2, a2		# number of trees is the square of the side of the forest
vector_loop:
	addi	sp, sp, -1
	sb	zero, 0(sp)
	addi	t0, t0, -1
	bnez	t0, vector_loop

	li	a3, HORIZ
	li	a4, RIGHT_OR_DOWN
	call	check_visible
	li	a4, LEFT_OR_UP
	call	check_visible

	li	a3, VERT
	li	a4, RIGHT_OR_DOWN
	call	check_visible
	li	a4, LEFT_OR_UP
	call	check_visible

	mul	t0, a2, a2		# countdown
	mv	t1, a1			# pointer
	mv	t2, zero		# counter
loop_count:
	lb	t3, 0(t1)
	add	t2, t2, t3
	addi	t1, t1, -1
	addi	t0, t0, -1
	bnez	t0, loop_count

	mv	a0, t2
	call	print_int

end:
	li      a7, 93                  # exit
	li      a0, 0                   # EXIT_SUCCESS
	ecall



check_visible:
	addi	sp, sp, -8
	sd	s0, 0(sp)
	# if moving to the right or downward through lines of trees:
	#	- inner coord starts at 0
	#	- inner coord increases by 1
	#	- movement stops at inner coord side
	# if moving to the left or upward through lines of trees:
	#	- inner coord starts at (side - 1)
	#	- inner coord increases by -1
	#	- movement stops at inner coord -1
	li	t0, 0
	li	t1, 1
	mv	t2, a2
	li	t6, LEFT_OR_UP
	bne	a4, t6, skip1
	addi	t0, a2, -1
	li	t1, -1
	li	t2, -1
skip1:

	li	t3, 0		 	# outer coordinate always start at 0
check_visible_outer:
	mv	t5, t0			# initialize inner coordinate
	li	t6, -1			# initialize highest tree below min value of 0
check_visible_inner:
	# when moving horizontally between the lines, outer coordinate is Y and inner coordinate is X
	# when moving vertically between the lines, outer coordinate is X and inner coordinate is Y
	li	a5, VERT
	beq	a3, a5, coord_vert
	VEC_INDEX a5, t3, t5		
	j	end_index
coord_vert:
	VEC_INDEX a5, t5, t3
end_index:
	sub	a6, a0, a5		# pointer to the tree height
	lb	a6, 0(a6)		# tree height
stop_here:
	ble	a6, t6, not_visible	# tree is of lesser or equal size as the tallest tree
	sub	a7, a1, a5		# pointer to the visible tree flag
	li	s0, 1
	sb	s0, 0(a7)		# mark tree as visible
	mv	t6, a6			# new tallest tree
not_visible:
	add	t5, t5, t1		# increase / decrease inner coordinate
	bne	t5, t2, check_visible_inner
	addi	t3, t3, 1		# increase outer coord
	bne	t3, a2, check_visible_outer
	
	ld	s0, 0(sp)
	addi	sp, sp, 8
	ret

