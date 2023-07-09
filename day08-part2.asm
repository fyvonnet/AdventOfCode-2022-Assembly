	.global _start

	.set	ASCII_0, 48
	.set	ASCII_LF, 10
	.set	SYS_EXIT, 93
	.set	EXIT_SUCCESS, 0


	# movement along the tree line:
	#
	# 0bAB
	#
	# A = 0 : horizontal (left or right)
	#     1 : vertical (up or down)
	# B = 0 : forward (right or down)
	#     1 : backward (left or up)
	#
	.set	RIGHT,	0b00
	.set	LEFT,	0b01
	.set	DOWN,	0b10
	.set	UP,	0b11
	#
	.set	VERT,	0b10
	.set	BACK,	0b01

	.macro	TREE_HEIGHT dr xr yr
	mv	\dr, \yr
	mul	\dr, \dr, a1
	add	\dr, \dr, \xr
	sub	\dr, a0, \dr
	lb	\dr, 0(\dr)
	.endm

	.macro	INC reg
	addi \reg, \reg, 1
	.endm

	.macro	DEC reg
	addi \reg, \reg, -1
	.endm

	.section .rodata

filename:
	.string "inputs/day08"

	.section .text
_start:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	# copy input as a single vector in the stack and count the number of lines

	mv	t2, a0
	addi	s0, sp, -1		# s0 points to the first element of the input
	mv	a1, zero		# initialize rows counter
	li	t1, ASCII_LF
read_loop:
	lb	t0, 0(t2)
	beq	t0, t1, reached_eol
	addi	t0, t0, -ASCII_0
	DEC	sp
	sb	t0, 0(sp)
	INC	t2
	j 	read_loop
reached_eol:
	INC	a1
	INC	t2
	blt	t2, s11, read_loop

	# scan all the trees to find the largest scenic score
	# skip trees at the edge that have a null scenic score

	addi	s2, a1, -1		# s2 is (side - 1)
	mv	s3, zero		# initialize largest score

	li	a3, 1
loop_y:
	li	a2, 1
loop_x:
	li	a4, 3			# initialize direction
	li	s1, 1			# initialize scenic score
loop_dir:
	mv	a0, s0			# copy input pointer
	call	count_visible
	beqz	a0, skip_new_score	# whole score is zero if no visible trees in one direction
	mul	s1, s1, a0		# multiply visible trees count to score
	DEC	a4
	bge	a4, zero, loop_dir
	ble	s1, s3, skip_new_score	# last score <= largest score?
	mv	s3, s1			# last score is new largest score
skip_new_score:
	INC	a2
	blt	a2, s2, loop_x
	INC	a3
	blt	a3, s2, loop_y	

	mv	a0, s3
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

	
	# a0 : input pointer
	# a1 : side
	# a2 : x
	# a3 : y
	# a4 : direction
	# returns count of visible trees
	#
	# t0 : variable coordinate change
	# t1 : variable coordinate stop
	# t2 : 0 if X variable, non-0 if Y variable
	# t3 : variable coordinate
	# t4 : constant coordinate
	# t5 : count
	# t6 : current tree size
	# a5 : reference tree size
count_visible:
	TREE_HEIGHT a5 a2 a3
	li	t0, BACK
	and	t0, t0, a4		# check for backward bit
	beqz	t0, go_forw
	# moving backward
	# coordinate changes by -1, stop at -1
	li	t0, -1
	li	t1, -1
	j	skip_forw
go_forw:
	# moving forward
	# coordinate changes by 1, stop at (side)
	li	t0, 1
	mv	t1, a1
skip_forw:

	li	t2, VERT
	and	t2, t2, a4		# check for horizontal bit
	beqz	t2, go_hori
	# move vertically
	mv	t3, a3			# variable coord is Y
	mv	t4, a2			# constant coord is X
	j	skip_hori
go_hori:
	# move horizontally
	mv	t3, a2			# variable coord is X
	mv	t4, a3			# constant coord is Y
skip_hori:

	mv	t5, zero		# initialize count
loop_count:
	add	t3, t3, t0		# increase / decrease variable coordinate
	beq	t3, t1, loop_count_end	# check if edge reached
	addi	t5, t5, 1		# edge not yet reached, one more tree visible
	beqz	t2, x_var
	TREE_HEIGHT t6 t4 t3
	j	skip
x_var:
	TREE_HEIGHT t6 t3 t4
skip:
	bge	t6, a5, loop_count_end	# exit if new tree is at least as high as the ref tree
	j	loop_count
loop_count_end:
	mv	a0, t5
	ret

	.end


