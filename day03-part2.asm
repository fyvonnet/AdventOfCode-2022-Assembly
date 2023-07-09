	.globl _start

	.section .rodata
filename:
	.string "inputs/day03"

	.section .bss
found:
	.zero	52

	.section .text

_start:
	la	a0, filename
	call	map_input_file
	mv	s0, a0
	add	s11, a0, a1			# save EOF address
	li	s1, 0				# initialize sum
	la	s4, found
loop_group:
	li	s2, 3				# lines countdown
	li	s5, 0b001			# "letter found" bit
loop_line:
	lb	s3, 0(s0)
	li	t0, 10				# '\n'
	beq	s3, t0, loop_line_end		# EOL reached
	li	t0, 97				# 'a'
	blt	s3, t0, capital			# letter is capital
	j	skip_capital
capital:
	li	t0, 39				# 'A' - 26
skip_capital:
	sub	s3, s3, t0			# turn ascii code to index
	add	t0, s4, s3			# add index to address
	lb	t1, 0(t0)			# load "found letter" bits
	or	t1, t1, s5			# raise bit for the current line
	sb	t1, 0(t0)			# save back bits
	addi	s0, s0, 1			# move to next letter
	j	loop_line
loop_line_end:
	addi	s2, s2, -1
	beqz	s2, loop_group_end		# exit loop if countdown reach 0
	addi	s0, s0, 1			# skip \n
	sll	s5, s5, 1			# move "found letter" bit to the left
	j	loop_line
loop_group_end:
	la	t0, found
	la	t1, found
	li	t2, 0b111			# search for all 3 found bits raised
loop_search:
	lb	t3, 0(t1)			# load "found" bits
	beq	t3, t2, loop_search_end		# exit loop if all bits raised
	addi	t1, t1, 1			# move to next letter
	j	loop_search
loop_search_end:
	sub	t1, t1, t0			# compute index of found letter
	addi	t1, t1, 1			# add 1 to get priority
	add	s1, s1, t1			# add priority to sum
	addi	s0, s0, 1			# skip \n
	bge	s0, s11, loop_exit		# exit loop if EOF reached

	# reset found vector
	la	t0, found
	li	t1, 52
loop_reset:
	sb	zero, 0(t0)
	addi	t0, t0, 1
	addi	t1, t1, -1
	bnez	t1, loop_reset

	j	loop_group

loop_exit:
	mv	a0, s1
	call	print_int

	li	a7, 93				# exit
	li	a0, 0				# EXIT_SUCCESS
	ecall

