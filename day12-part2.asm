	.global main

	.set	ASCII_A,	97
	.set	ASCII_Z, 122
	.set	ASCII_NL,	10
	.set	ASCII_CAP_E, 69
	.Set	ASCII_CAP_S, 83
	.set	VISITED, 95
	.set	NODE_SIZE, 13
	.set	SYS_EXIT, 93
	.set	EXIT_SUCCESS, 0

        .macro  INC reg
        addi \reg, \reg, 1
        .endm

        .macro  DEC reg
        addi \reg, \reg, -1
        .endm

        .macro  ZERO reg
        mv \reg, zero
        .endm

	.section .rodata

filename:
	.string "inputs/day12"

moves:
	.byte 	 0, -1		# up
	.byte	 0,  1		# down
	.byte	-1,  0		# left
	.byte	 1,  0		# right
moves_end:

	.section .text

main:
	la      a0, filename
	call    map_input_file

	# measure row length, \n included
	mv	s0, a0
	mv	t0, a0
	li	t1, ASCII_NL
line_length_loop:
	inc	t0
	lb	t2, 0(t0)
	bne	t2, t1, line_length_loop
	inc	t0
	sub	s1, t0, a0

	div	s2, a1, s1			# compute rows count
	dec	s1				# exclude \n from the row length

	mv	s11, a0
	addi	sp, sp, -32			# allocate stack space for array bounds
	sd	zero,  0(sp)
	addi	t0, s1, -1
	sd	t0,  8(sp)
	sd	zero, 16(sp)
	addi	t0, s2, -1
	sd	t0, 24(sp)
	li	a0, 2
	mv	a1, sp
	li	a2, 1
	call	create_array
	mv	s0, a0
	ld	s4, 24(a0)			# load address of array's vector


	addi	sp, sp, -16			# allocate space for coordinates


	# copy input in the array
	zero	s10				# Y-coord
	li	t2, ASCII_CAP_E
	li	t3, ASCII_CAP_S
copy_input_loop:
	zero	s9				# X-coord
	mv	t0, s1				# row length countdown
copy_rows_loop:
	lb	t1, 0(s11)			# load input char
	beq	t1, t2, map_end			# read 'E'
	beq	t1, t3, map_start		# read 'S'
	j	copy_continue			# default
map_end:
	li	t1, VISITED
	sd	s9, 0(sp)
	sd	s10, 1(sp)
	j	copy_continue
map_start:
	li	t1, ASCII_A
copy_continue:
	sb	t1, 0(s4)
	inc	s11				# increment input pointer
	inc	s4				# increment heights matrix's vector pointer
	inc	s9				# increment X coordinate
	dec	t0				# decrement rows length countdown
	bnez	t0, copy_rows_loop		# loop if countdown not null
	inc	s11				# skip NL
	inc	s10				# increment Y coordinate
	dec	s2				# decrement rows count countdown
	bnez	s2, copy_input_loop		# loop if countdown not null


	# create first queue node
	li	a0, NODE_SIZE
	call	malloc
	li	t0, ASCII_Z
	sb	t0, 0(a0)			# height
	lb	t0, 0(sp)			# load X-coord of end square
	sb	t0, 1(a0)			# save x-coordinate in node
	lb	t0, 1(sp)			# load Y-coord of end square
	sb	t0, 2(a0)			# save y-coordinate in node
	sh	zero, 3(a0)			# steps
	sd	zero, 5(a0)			# pointer to next node (null)
	mv	s11, a0


	# initialize queue and add first node
	li	a0, 16
	call	malloc
	mv	s1, a0
	sd	s11, 0(s1)
	sd	s11, 8(s1)
	
	li	s3, ASCII_A
	la	s9, moves_end

explore_loop:
	ld	a0, 0(s1)			# load address of first node
	ld	t1, 5(a0)			# load address of next node
	sd	t1, 0(s1)			# set next node as first node
	
	lb	s4, 0(a0)			# height
	lb	s5, 1(a0)			# x-coord
	lb	s6, 2(a0)			# y-coord
	lh	s7, 3(a0)			# steps
stop:
	call	free				# delete node from memory

	inc	s7				# one more step

	la	s8, moves			# point to start of moves vector
	dec	s4				# min height allowed is current height - 1
moves_loop:
	lb	t0, 0(s8)			# load X move
	lb	t1, 1(s8)			# load Y move
	add	t0, t0, s5			# add X move to X coordinate
	add	t1, t1, s6			# add Y move to Y coordinate
	sd	t0, 0(sp)			# save X coordinate to coordinates vector
	sd	t1, 8(sp)			# save Y coordinate to Coordinates vector
	mv	a0, s0
	mv	a1, sp
	call	array_addr_safe	
	beqz	a0, skip_move			# out of bounds
	lb	s10, 0(a0)			# load height from matrix
	blt	s10, s4, skip_move		# too low
	beq	s10, s3, explore_end		# lowest altitude reached?

explore_continue:

	# mark current square as visited
	li	t0, VISITED
	sb	t0, 0(a0)
	
	# add square to queue
	li	a0, NODE_SIZE
	call	malloc
	sb	s10, 0(a0)			# height
	ld	t0, 0(sp)
	sb	t0, 1(a0)			# X coord
	ld	t0, 8(sp)
	sb	t0, 2(a0)			# Y coord
	sh	s7, 3(a0)			# steps
	sd	zero, 5(a0)			# pointer to next node (null)
	ld	t0, 0(s1)			# load pointer to first node
	bnez	t0, queue_not_empty		
	sd	a0, 0(s1)			# queue empty: new node is new first node
	j	queue_next
queue_not_empty:
	ld	t0, 8(s1)			# load pointer to last node
	sd	a0, 5(t0)			# last node points to new node
queue_next:
	sd	a0, 8(s1)			# new node is new last node
	
skip_move:
	addi	s8, s8, 2
	bne	s8, s9, moves_loop
	j	explore_loop
	
explore_end:
	
	mv	a0, s7
	call	print_int
	
	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall
	

