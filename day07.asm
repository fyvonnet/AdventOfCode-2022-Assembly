	.global _start

	.set	IN,   		  0
	.set	OUT,  		  1
	.set	FILE, 		  2
	.set	END,  		  3
	.set	ASCII_DOLLAR,	 36
	.set	ASCII_d, 	100
	.set 	ASCII_DOT, 	 46

	.section .rodata

filename:
	.string "inputs/day07"

	.section .text

_start:
	la	a0, filename
	call	map_input_file
	add	s11, a0, a1


	##########################################################
	# Parse input and create list of commands and file sizes #
	##########################################################

	mv	s0, sp			# commands vector address
	li	s1, 0			# directories counter
parse_loop:
	bge	a0, s11, parse_loop_end
	lb	t0, 0(a0)
	li	t1, ASCII_DOLLAR	# found "$ cd [...]" ("$ ls" lines are skipped)
	beq	t0, t1, found_dir
	li	t1, ASCII_d
	beq	t0, t1, skip_and_loop	# "dir" lines are skipped
fond_file:
	call	parse_integer
	li	t0, FILE
	addi	sp, sp, -5
	sb	t0, 4(sp)		# store FILE command
	sw	a1, 0(sp)		# store file size
	j	skip_and_loop
found_dir:
	lb	t0, 5(a0)
	li	t1, ASCII_DOT		# "$ cd .."
	beq	t0, t1, dir_out
dir_in:
	li	t0, IN
	addi	sp, sp, -1
	sb	t0, 0(sp)
	addi	s1, s1, 1		# increase directories counter
	call	skip_to_next_line	# skip followin "$ ls" line
	j	skip_and_loop
dir_out:
	li	t0, OUT
	addi	sp, sp, -1
	sb	t0, 0(sp)
skip_and_loop:
	call	skip_to_next_line
	j	parse_loop

parse_loop_end:
	li      t0, END
	addi	sp, sp, -1
	sb      t0, 0(sp)

	li	t0, 4
	mul	s2, s1, t0
	sub	sp, sp, s2		# allocate 32 bits for every dir 

	mv	s2, sp			# pointer to dirs size vector
	mv	a0, s0			# pointer to commands vector
	

	#########################################
	# recursively compute directories sizes #
	#########################################

	addi	a0, a0, -1		# skip the first IN command
	call	compute_dirs_size	# a1 contains total size of root directory


	###################################################
	# scan the directory sizes list and solve problem #
	###################################################

	li	t4, 70000000		# total filesystem size
	sub	t4, t4, a1		# unused filesystem space
	li	t5, 30000000		# required space
	sub	t4, t5, t4		# remaining missing space
	
	li	t0, 100000		# max size of directories for part 1
	mv	t1, zero		# part 1 answer
	li	t2, -1			# part 2 answer (initialized to max possible value)

loop_solve:
	lw	t3, 0(sp)		# load dir size

	# part 1
	bgt	t3, t0, skip_add	# don't add dir size if > 100000
	add	t1, t1, t3
skip_add:

	# part 2
	bltu	t3, t4, skip		# skip if size insufficient 
	bgtu	t3, t2, skip		# skip if bigger than temporary answer
	mv	t2, t3			# set current dir size as new temporary answer
skip:

	addi	sp, sp, 4		# move pointer to next dir size
	addi	s1, s1, -1		# decrease countdown
	bnez	s1, loop_solve		# loop if countdown not zero


	############################
	# display results and quit #
	############################

	mv	s2, t2

	mv	a0, t1
	call	print_int

	mv	a0, s2
	call	print_int

	li	a7, 93			# exit
	li	a0, 0			# EXIT_SUCCESS
	ecall



compute_dirs_size:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	sd	s0, 8(sp)

	mv	s0, zero		# initialize dir size to 0

compute_dirs_size_loop:
	addi	a0, a0, -1
	lb	t0, 0(a0)		# load command

	li	t1, IN
	beq	t0, t1, command_in
	li	t1, OUT
	beq	t0, t1, command_out
	li	t1, FILE
	beq	t0, t1, command_file

command_end:
	addi	a0, a0, 1		# stay on the END command
	j	command_out

command_file:
	addi	a0, a0, -4
	lw	t0, 0(a0)		# load file size
	add	s0, s0, t0		# add to dir size
	j	compute_dirs_size_loop

command_in:
	call	compute_dirs_size	# compute size of subdir
	add	s0, s0, a1		# add size of subdir to total dir size
	j	compute_dirs_size_loop

command_out:
	sw	s0, 0(s2)		# save dir size
	addi	s2, s2, 4		# increase dir size vector pointer by 32 bits

	mv	a1, s0			# return dir size

	ld	ra, 0(sp)
	ld	s0, 8(sp)
	addi	sp, sp, 16

	ret


