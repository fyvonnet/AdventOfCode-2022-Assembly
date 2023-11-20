	.global main

        .macro  INC reg
        addi \reg, \reg, 1
        .endm

        .macro  DEC reg
        addi \reg, \reg, -1
        .endm

	.macro	CLR reg
	mv \reg, zero
	.endm

	.set	SYS_EXIT, 93
	.set	EXIT_SUCCESS, 0

	.section .rodata

filename:
	.string "inputs/day18"

adjacent:
	.byte	-1,  0,  0
	.byte	 1,  0,  0
	.byte	 0, -1,  0
	.byte	 0,  1,  0
	.byte	 0,  0, -1
	.byte	 0,  0,  1
	

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1
	clr	s0				# initialize counter


	# parse input file and store coordinates on the stack

parse_input_loop:
	inc	s0				# increment counter
	addi	sp, sp, -24
	.rept 3
	call	parse_integer
	sd	a1, 0(sp)
	addi	sp, sp, 8
	inc	a0				# skip separator
	.endr
	addi	sp, sp, -24
	blt	a0, s11, parse_input_loop


	mv	s1, sp				# save input pointer
	addi	sp, sp, -48			# allocate space for bounds vector
	mv	s2, sp				# save bounds vector pointer
	
	# initialize bounds vector with first set of coordinates
	mv	t1, s1				# initialize input pointer
	mv	t2, s2				# initialize bounds vector pointer
	.rept 3
	ld	t0, 0(t1)
	sd	t0, 0(t2)
	sd	t0, 8(t2)
	addi	t1, t1, 8
	addi	t2, t2, 16
	.endr

	# get coordinates bounds
	addi	t0, s0, -1			# initialize countdown
get_bounds_loop:
	mv	t2, s2				# initialize bounds vector pointer
	li	s11, 3				# initialize coordinates coutdown
foreach_coordinate:
	ld	a1, 0(t1)			# load coordinate from input vector
	ld	a0, 0(t2)			# load current minimum
	bgt	a1, a0, skip_min
	sd	a1, 0(t2)			# store new minimum
skip_min:
	ld	a0, 8(t2)			# load current maximum
	blt	a1, a0, skip_max
	sd	a1, 8(t2)			# store new maximum
skip_max:
	addi	t1, t1, 8			# point to next coordinate
	addi	t2, t2, 16			# point to next pair of bounds
	dec	s11
	bnez 	s11, foreach_coordinate
	dec	t0				# decrement countdown
	bnez	t0, get_bounds_loop		# loop if countdown not null


	# enlarge bounds to leave space around the droplet
	mv	s3, s2
	.rept	3
	ld	t0, 0(s3)			# load min bound
	dec	t0				# decrement min bound
	sd	t0, 0(s3)			# store min bound
	ld	t0, 8(s3)			# load max bound
	inc	t0				# increment max bound
	sd	t0, 8(s3)			# store max bound
	addi	s3, s3, 16			# move to next bounds
	.endr

	li	a0, 3				# rank 3
	mv	a1, s2				# pointer to bounds
	li	a2, 1				# all elements are 1 byte
	call	create_array
	mv	s2, a0				# copy pointer to array

	
	# mark the cubes in the grid

	mv	s3, s0				# initialize countdown
	mv	s4, s1				# input pointer
	li	s5, -1				# constant -1 (cube present)
fill_grid_loop:
	mv	a0, s2
	mv	a1, s4
	call	array_addr
	sb	s5, 0(a0)			# mark cube as present
	addi	s4, s4, 24			# move to next input line
	dec	s3
	bnez	s3, fill_grid_loop


	######                           #   
	#     #   ##   #####  #####     ##   
	#     #  #  #  #    #   #      # #   
	######  #    # #    #   #        #   
	#       ###### #####    #        #   
	#       #    # #   #    #        #   
	#       #    # #    #   #      ##### 


	mv	s3, s0				# initialize countdown
	mv	s4, s1				# input pointer
	clr	s5				# initialize free sides counter
	addi	sp, sp, -24			# allocate space for set of coordinates
	mv	s6, sp
count_free_sides_loop:
	la	s7, adjacent			# pointer to relative adjacent coordinates
	li	s11, 6				# initialize countdown
foreach_adjacent:
	.rept 3					# for each coordinate in the set
	ld	t0, 0(s4)			# load input cube coordinate
	lb	t1, 0(s7)			# load relative adjacent coordinate
	add	t0, t0, t1			# compute absolute adjacent coordinate
	sd	t0, 0(s6)			# store absolute adjacent coordinate on the stack
	addi	s4, s4, 8			# move to next input cube coordinate
	addi	s7, s7, 1			# move to next relative adjacent coordinate
	addi	s6, s6, 8			# move to next absolute adjacent coordinate
	.endr
	addi	s6, s6, -24			# reset relative adjacent coordinates vector pointer
	addi	s4, s4, -24			# reset input cube coordinate
	mv	a0, s2
	mv	a1, sp
	call    array_addr
	lb	t0, 0(a0)			# load cube status
	bltz	t0, skip_adjacent		# if status is negative, an adjacent cube is present
	inc	t0				# increase the adjacent cubes count for the adjacent empty space
	sb	t0, 0(a0)			# store count back
	inc	s5				# increase counter
skip_adjacent:
	dec	s11
	bgtz	s11, foreach_adjacent
	addi	s4, s4, 24			# move to next input cube
	dec	s3
	bgtz	s3, count_free_sides_loop

end:
	mv	a0, s5
	call	print_int
 

	######                          #####  
	#     #   ##   #####  #####    #     # 
	#     #  #  #  #    #   #            # 
	######  #    # #    #   #       #####  
	#       ###### #####    #      #       
	#       #    # #   #    #      #       
	#       #    # #    #   #      ####### 

	
	clr	s5				# initialize counter

	addi	sp, sp, -24			# allocate space for current coordinate
	mv	s9, sp

	addi	sp, sp, -25			# allocate space for bottom stack element
	li	t0, 1
	sb	t0, 24(sp)			# store 1 to mark bottom of DFS stack

	# initialize DFS queue with corner coordinates

	addi	sp, sp, -25
	sb	zero, 24(sp)			# store 0 to mark element as not-bottom
	ld	t0, 8(s2)			# load pointer to bounds vector from the array struct
	mv	t2, sp
	.rept	3
	ld	t1, 0(t0)			# load min coordinate
	sd	t1, 0(t2)			# save min coordinate
	addi	t0, t0, 16
	addi	t2, t2, 8
	.endr

	# mark corner coordinate as explored
	mv	a0, s2
	mv	a1, sp
	call	array_addr_safe
	li	t2, -1
	sb	t2, 0(a0)

loop_dfs:
	lb	t0, 24(sp)			# load bottom marker
	bnez	t0, loop_dfs_end		# end if bottom reached


	# copy current coordinates from the top of the stack
	mv	t0, sp
	mv	t1, s9
	.rept 3
	ld	t2, 0(t0)
	sd	t2, 0(t1)
	addi	t0, t0, 8
	addi	t1, t1, 8
	.endr

	addi	sp, sp, 25			# free top stack element


	la	s7, adjacent
	li	s6, 6				# initialize countdown
loop_adjacent:
	addi	sp, sp, -25			# allocate new stack element

	# compute coordinates of adjacent cube and store result to the stack
	mv	t0, s9				# copy current coordinates pointer
	mv	t1, sp				# copy new element pointer
	.rept 3
	ld	t2, 0(t0)			# load current coordinate
	lb	t3, 0(s7)			# load relative adjacent coordinate
	add	t2, t2, t3			# compute absolute adjacent coordinate
	sd	t2, 0(t1)			# store absolute adjacent coordinate to new stack element
	addi	t0, t0, 8
	addi	t1, t1, 8
	addi	s7, s7, 1
	.endr

	mv	a0, s2
	mv	a1, sp
	call	array_addr_safe

	beqz	a0, loop_adjacent_skip		# adjecent coordinate is out of bounds, skip
	lb	t0, 0(a0)			# load cube value on matrix
	bltz	t0, loop_adjacent_skip		# coordinate already explored, skip
	add	s5, s5, t0

	li	t0, -1
	sb	t0, 0(a0)			# mark cube as explored
	sb	zero, 24(sp)			# mark new stack element as non-bottom
	j	loop_adjacent_next

loop_adjacent_skip:
	addi	sp, sp, 25			# free new coordinate from the stack
loop_adjacent_next:
	dec	s6				# decrement countdown
	bnez	s6, loop_adjacent		# loop if countdown not null
	j	loop_dfs

	

loop_dfs_end:

	mv	a0, s5
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall
