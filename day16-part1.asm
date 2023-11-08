	.global main

        .macro  INC reg
        addi \reg, \reg, 1
        .endm

        .macro  DEC reg
        addi \reg, \reg, -1
        .endm

        .macro  CLR reg
        mv \reg, zero
        .endm

	.set	SYS_EXIT, 93
	.set	EXIT_SUCCESS, 0
	.set	ASCII_SPACE, 32
	.set	ASCII_COMMA, 44
	.set	SIZEOF_INPUT, 23
	.set	SIZEOF_STACK, 12

	.section .rodata

filename:
	.string "inputs/day16"

	.section .text

main:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	# parse input file into input vector

	clr	s0						# clear input lines counter
	li	s2, ASCII_COMMA
foreach_input_line:
	add	sp, sp, -SIZEOF_INPUT				# allocate stack space for inputline
	inc	s0						# increment counter
	add	a0, a0, 6					# skip "Valve "
	lh	t0, 0(a0)					# read 2 letters as single 16-bits value
	sh	t0, 0(sp)
	add	a0, a0, 17					# skip "XX has flow rate="
	call	parse_integer
	sb	a1, 2(sp)
	add	a0, a0, 24					# skip "; tunnels leads to...."
	lb	t0, 0(a0)
	li	t1, ASCII_SPACE
	bne	t0, t1, skip
	inc	a0
skip:
	add	s1, sp, 3
foreach_input_valve:
	lh	t0, 0(a0)					# load valve letters as single 16-bits value
	sh	t0, 0(s1)					# store value in stack
	lb	t1, 2(a0)
	bne	s2, t1, foreach_input_valve_end			# exit loop if end of input line reached
	addi	s1, s1, 2					# move valves vector pointer
	addi	a0, a0, 4					# move input file pointer
	j	foreach_input_valve				
foreach_input_valve_end:
	li	t0, -1
	sh	t0, 2(s1)					# terminate valves vector
	addi	a0, a0, 3					# skip to next line
	blt	a0, s11, foreach_input_line			# loop if end of input file not reached
	mv	s1, sp						# save input vector pointer

	# sort input vector for binary search

	mv	a0, s1
	mv	a1, s0
	li	a2, SIZEOF_INPUT
	la	a3, compar
	call	quicksort


	# replace destination valves numbers with index numbers

	mv	s2, s0						# initialize countdown
	mv	s3, s1						# initialize valves pointer
replace_foreach_valve:
	addi	s4, s3, 3					# initilize destination pointer
replace_foreach_destination:
	lh	s5, 0(s4)					# load destination number
	bltz	s5, replace_foreach_destination_end		# end loop if number negative
	li	t0, 0						# initialize first index
	addi	t1, s0, -1					# initilize last index
binsearch_loop:
	sub	t2, t1, t0
	srli	t2, t2, 1					# middle index
	add	t2, t2, t0					# middle index
	li	t3, SIZEOF_INPUT
	mul	t5, t2, t3					# offset
	add	t5, t5, s1					# address
	lh	t3, 0(t5)					# load candidate number
	blt	s5, t3, binsearch_left
	bgt	s5, t3, binsearch_right
	j	binsearch_loop_end				# index found
binsearch_left:
	addi	t1, t2, -1
	j	binsearch_loop
binsearch_right:
	addi	t0, t2, 1
	j	binsearch_loop
binsearch_loop_end:
	sh	t2, 0(s4)					# store index in place of the number
	addi	s4, s4, 2					# move pointer to next destination valve
	j	replace_foreach_destination			# loop
replace_foreach_destination_end:
	dec	s2						# decrease countdown
	addi	s3, s3, SIZEOF_INPUT				# move pointer to next valve
	bgtz	s2, replace_foreach_valve			# loop if countdown not null
	

	
	# Use BFS to measure travel time from every valve to every other valve
	# Store times on matrix


	# allocate matrix
	mul	t0, s0, s0
	sub 	sp, sp, t0
	mv	s3, sp						# matrix pointer

	# align stack to 16 bytes (RISC-V standard) to avoid bus error when calling malloc
	li	t0, 16
	remu	t1, sp, t0
	sub	sp, sp, t1


	clr	s4						# index of first valve
	mv	s5, s0						# initilize countdown
	mv	s6, s3						# copy of matrix pointer

matrix_foreach_valve:

	mv	t0, s1						# reuse input vector 16-bit number
	mv	t1, s0						# initilize countdown
clear_visited_loop:
	sb	zero, 0(t0)					# set visited to zero (not visited)
	addi	t0, t0, SIZEOF_INPUT				# move to next input line
	dec	t1						# decrement countdown
	bgtz	t1, clear_visited_loop				# loop if countdown not null

	# initialize queue with starting valve
	li	a0, 10
	call	malloc
	mv	s7, a0						# head of queue
	mv	s8, a0						# tail of queue
	sb	s4, 0(a0)					# current valve
	sb	zero, 1(a0)					# time to same valve is zero
	sd	zero, 2(a0)					# null pointer
	li	t0, SIZEOF_INPUT
	mul	t0, t0, s4
	add	t0, t0, s1					# adress of valve in input vector
	li	t1, 1
	sb	t1, 0(t0)					# current valve marked as visited
	add	t2, s6, s4					# address of valve in the matrix
	sb	zero, 0(t2)					# mark time to itself as 0

matrix_explore_tunnels:
	lb	t0, 0(s7)					# load valve index
	lb	t1, 1(s7)					# load time
	add	t4, s6, t0					# pointer to matrix cell
	addi	s9, t1, 1					# new time
	li	s11, SIZEOF_INPUT
	mul	s11, s11, t0
	add	s11, s11, s1					# pointer to input data
	inc	t1						# add 1 minute to open the valve
	sb	t1, 0(t4)					# store time in matrix
	addi	s11, s11, 3					# move pointer to destinations vector
matrix_forall_destinations:
	lh	s10, 0(s11)					# read index of tunnel destination
	bltz	s10, matrix_forall_destinations_end		# end loop if tunnel index negative
	li	t5, SIZEOF_INPUT
	mul	t1, s10, t5
	add	t3, t1, s1
	lb	t4, 0(t3)					# load visited status
	bnez	t4, matrix_forall_destinations_skip		# destination already visited
	li	t4, 1
	sb	t4, 0(t3)					# mark as visited
	li	a0, 10
	call	malloc
	sb	s10, 0(a0)					# store destination index
	sb	s9, 1(a0)					# store time to destination
	sd	zero, 2(a0)					# no next element in queue
	sd	a0, 2(s8)					# attach new element to last element
	mv	s8, a0						# new element is new queue tail
matrix_forall_destinations_skip:
	addi	s11, s11, 2					# move pointer to next destination
	j	matrix_forall_destinations
matrix_forall_destinations_end:
	# remove head of queue
	mv	a0, s7
	ld	s7, 2(a0)
	call	free
	bnez	s7, matrix_explore_tunnels
	inc	s4						# next valve
	dec	s5						# decrement countdown
	add	s6, s6, s0					# point to next matrix row
	bnez	s5, matrix_foreach_valve			# loop if countdown not null


	# Solve problem using DFS to explore tunnels


	# put 0 in the stack to mark end of DFS stack
	addi	sp, sp, -1
	sb	zero, 0(sp)
	clr	s4						# initialize maxiumum total flow

	# initialize stack with valve AA
	addi	sp, sp, -SIZEOF_STACK
	li	t0, 1
	sb	t0, 0(sp)					# move formward
	sb	x0, 1(sp)					# valve AA has number 0
	sb	x0, 2(sp)					# valve AA has null flow rate
	sb	x0, 3(sp)					# zero total flow rate
	sw	x0, 4(sp)					# zero total pressure released
	li	t1, 30
	sb	t1, 8(sp)					# remaining time

loop_open_valves:
	lb	t0, 0(sp)					# read command
	bgtz	t0, move_forward				# move forward if command is 1 
	bltz	t0, move_back					# move back if command is -1
	j	loop_open_valves_end				# end if command is 0

move_forward:
	li	t0, -1
	sb	t0, 0(sp)					# turn move forward command to move back
	lb	t0, 1(sp)					# load current valve number
	lb	t6, 3(sp)					# load total flow rate
	lw	t4, 4(sp)					# load total released pressure
	lb	a6, 8(sp)					# load remaining time
	mul	t2, t0, s0					# offset to matrix row corresponding to current valve
	add	t2, t2, s3					# address of matrix row
	li	t1, SIZEOF_INPUT
	mul	t1, t1, t0
	add	t1, t1, s1					# line of input corresponding to current valve
	lb	a1, 2(t1)					# load current valve flow rate
	sb	a1, 2(sp)					# save valve flow rate
	sb	x0, 2(t1)					# set current valve flow rate to zero
	mv	t3, s0						# initialize countdown
	clr	t5						# first destination
	mv	t1, s1						# pointer to input vector
loop_stack_destinations:
	# filter out invalid destinations
	beq	t0, t5, skip_destination			# skip if destination valve is same as current valve
	lb	a0, 2(t1)					# load flow rate
	beqz	a0, skip_destination				# skip destination if flow rate null
	add	a1, t2, t5					# address of matrix element corresponding to destination
	lb	a1, 0(a1)					# load time to destination
	blt	a6, a1, skip_destination			# skip destination if not enough remaining time

	# add destination to stack
	addi	sp, sp, -SIZEOF_STACK
	li	a5, 1
	sb	a5,  0(sp)					# move forward
	sb	t5,  1(sp)					# destination valve number
	sb	a0,  2(sp)					# flow rate of destination valve
	add	a5, a0, t6					# update total flow rate
	sb	a5,  3(sp)					# store new total flow rate
	mul	a4, t6, a1					# pressure released during trip to destination
	add	a4, a4, t4					# total pressure released after trip
	sw	a4, 4(sp)					# store total pressure released
	sub	a5, a6, a1					# update remaining time
	sb	a5, 8(sp)					# store remaining time
	
skip_destination:
	addi	t1, t1, SIZEOF_INPUT				# next input line
	inc	t5						# next destination candidate
	dec	t3						# decrease countdown
	bnez	t3,loop_stack_destinations			# loop if countdown not null
	lb	t0, 0(sp)					# load command from top of stack
	bgtz	t0, loop_open_valves				# loop if a move forward command is present on top of the stack
	# no move forward is present on top of the stack, no destination has been added
	mul	t0, t6, a6					# pressure released during remaining time
	add	t0, t0, t4					# add to total released pressure
	blt	t0, s4, skip_new_max_flow			# check if new maximum found
	mv	s4, t0
skip_new_max_flow:
	j	loop_open_valves

move_back:
	lb	t0, 1(sp)					# load current valve number
	lb	t1, 2(sp)					# load flow rate
	li	t2, SIZEOF_INPUT
	mul	t2, t2, t0					
	add	t2, t2, s1					# pointer to input line
	sb	t1, 2(t2)					# restore flow rate
	addi	sp, sp, SIZEOF_STACK
	j	loop_open_valves

loop_open_valves_end:

	mv	a0, s4
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

compar:
	lh	t0, 0(a0)
	lh	t1, 0(a1)
	sub	a0, t0, t1
	ret
