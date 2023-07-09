	.global _start

	.set	ASCII_COMMA, 	 44
	.set	ASCII_NL, 	 10
	.set	ASCII_ADD,	 43
	.set	ASCII_MUL, 	 42
	.set	ASCII_O,	111
	.set	SYS_EXIT,	 93
	.set	EXIT_SUCCESS,	  0
	.set	MONKEY_SIZE,	 39
	.set	ROUNDS,		 20

	.macro  INC reg
	addi \reg, \reg, 1
	.endm

	.macro  DEC reg
	addi \reg, \reg, -1
	.endm

	.section .rodata

filename:
	.string "inputs/day11"

	.section .text

_start:
	la      a0, filename
	call    map_input_file
	add	s11, a0, a1

	addi	sp, sp, -8
	mv	gp, sp				

	addi	s0, sp, -MONKEY_SIZE		# save address of first monkey
	mv	s1, zero			# initialize monkeys counter

	#################
	# Parsing input	#
	#################

	li	s2, MONKEY_SIZE
parse_input_loop:
	addi	sp, sp, -MONKEY_SIZE		# allocate space for monkey
	inc	s1				# increase counter
	addi	a0, a0, 26			# skip first line + label of second one, minus 2
	sd	a0, 0(sp)			# temporarily store input's items address minus 2
	sd	zero, 8(sp)
	sw	zero, 35(sp)

	# skip the starting items list
	li	t0, ASCII_NL
	li	t3, ASCII_MUL
skip_line_loop:
	lb	t2, 0(a0)
	inc	a0
	bne	t0, t2, skip_line_loop

	addi	a0, a0, 23			# move pointer to operator
	lb	t1, 0(a0)
	sub	t1, t1, t3			# store 0 for multiplication or 1 for addition
	sb	t1, 16(sp)
	addi	a0, a0, 2			# move pointer to operation value
	
	li	t2, ASCII_O
	lb	t1, 0(a0)
	beq	t1, t2, square
	call	parse_integer
	j	skip1
square:
	li	a1, 0
	addi	a0, a0, 3
skip1:
	sb	a1, 17(sp)
	addi	a0, a0, 22			# move pointer to divisor
	call	parse_integer
	sb	a1, 18(sp)
	addi	a0, a0, 30

	# monkeys vector is in reverse order, indices are negative
	call	parse_integer
	mul	t0, a1, s2
	sub	t0, s0, t0
	sd	t0, 19(sp)
	addi	a0, a0, 31
	call	parse_integer
	mul	t0, a1, s2
	sub	t0, s0, t0
	sd	t0, 27(sp)

	addi	a0, a0, 2			# move input pointer to next monkey
	blt	a0, s11, parse_input_loop

	sd	sp, 0(gp)			# save adress of the beginning of the monkeys vector

	#######################
	# parsing items lines #
	#######################

	mv	s2, s0				# initialize monkey pointer
	mv	s3, s1				# initialize countdown
	li	s10, ASCII_COMMA
parse_items_loop_m:
	ld	a0, 0(s2)			# load input pointer
	sd	zero, 0(s2)			# reset FIRST pointer

parse_items_loop_i:
	addi	a0, a0, 2		
	call	parse_integer
	addi	sp, sp, -12			# allocate stack space for list node
	sw	a1, 0(sp)			# store item value
	mv	s11, a0
	mv	a0, s2
	mv	a1, sp
	call	enqueue_item
	mv	a0, s11
	lb	t0, 0(a0)
	beq	t0, s10, parse_items_loop_i	# comma detected, another item to add
	

	addi	s2, s2, -MONKEY_SIZE		# move to next monkey
	dec	s3				# decrease countdown
	bnez	s3, parse_items_loop_m


	###############
	# throw items #
	###############

	li	s11, ROUNDS			# initialize turns countdown
		
# start turns loop
turns_loop:
	mv	s2, s0				# initialize monkeys pointer
	mv	s3, s1				# initialize monkeys countdown
# start monkeys loop
monkeys_loop:
	lb	s4, 16(s2)			# load operator
	lb	s5, 17(s2)			# load modifier value
	lb	s6, 18(s2)			# load test divisor value
	ld	s7, 19(s2)			# load ptr to destination monkey for test true
	ld	s8, 27(s2)			# load ptr to destination monkey for test false
	lw	s9, 35(s2)			# load inspected items counter
# start items loop
items_loop:
	ld	t0, 0(s2)			# load address of first item
	beqz	t0, items_loop_end		# end of queue reached
	ld	t1, 4(t0)			# load address of second item
	sd	t1, 0(s2)			# second item is now first item
	lw	t2, 0(t0)			# load worry level of the item
	inc	s9				# increment inspected items counter

	# apply worry level modifier
	beqz	s4, mult
	add	t2, t2, s5
	j	skip_mult
mult:
	bnez	s5, not_square
	mul	t2, t2, t2
	j	skip_mult
not_square:
	mul	t2, t2, s5
skip_mult:
	li	t4, 3
	div	t2, t2, t4			# lower worry level
	sw	t2, 0(t0)			# store new worry level
	
	# check if worry level divisible, select destination monkey for item
	rem	t3, t2, s6
	mv	a0, s7
	beqz	t3, test_success
	mv	a0, s8
test_success:
	mv	a1, t0
	call	enqueue_item			# item sent to other monkey
	j	items_loop
items_loop_end:

	sw	s9, 35(s2)			# store inspected items counter
	addi	s2, s2, -MONKEY_SIZE
	dec	s3
	bnez	s3, monkeys_loop

	dec	s11
	bnez	s11, turns_loop


	##################
	# analyze result #
	##################

	# sort monkeys vector in reverse order of the number of items examined
	ld	a0, 0(gp)
	mv	a1, s1
	li	a2, MONKEY_SIZE
	la	a3, compar
	call	quicksort

	# multiply two largest numbers of items examined
	ld	t0, 0(gp)
	lw	t1, 35(t0)
	addi	t0, t0, MONKEY_SIZE
	lw	t2, 35(t0)
	mul	a0, t1, t2
	call	print_int

	li      a7, SYS_EXIT                  	# exit
	li      a0, EXIT_SUCCESS               	# EXIT_SUCCESS
	ecall


compar:
	lw	t0, 35(a0)
	lw	t1, 35(a1)
	sub	a0, t1, t0
	ret


	# a0: pointer to queue
	# a1: pointer to new item node
enqueue_item:
	sd	zero, 4(a1)			# new element is last and points to nothing
	ld	t0, 0(a0)
	bnez	t0, queue_not_empty		# check if pointer to first element is null
	# queue is empty, the new item is both first and last
	sd	a1, 0(a0)
	sd	a1, 8(a0)
	ret
queue_not_empty:
	ld	t0, 8(a0)			# load pointer to last element
	sd	a1, 4(t0)			# current last element points to new element
	sd	a1, 8(a0)			# new element is now last element
	ret

