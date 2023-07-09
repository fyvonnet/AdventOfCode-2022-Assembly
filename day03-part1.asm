	.global _start

	.section .rodata

filename:
	.string "inputs/day03"

	.section .text

_start:
	la	a0, filename
	call	map_input_file
	mv	s0, a0			# s0 points to begining of first line
	add	s11, a0, a1		# s11 contains EOF address
	mv	s3, zero		# initialize sum of priorities

loop_line:
	mv	a0, s0
	call	line_length
	add	s2, s0, a0		# s2 points to end of line
	addi	s2, s2, 1		# s2 points to next line
	srli	a0, a0, 1		# compute half length
	add	s1, s0, a0		# s1 points to second half of string
loop_first_half:
	mv	t0, a0			# copy half-length to countdown
loop_second_half:
	lb	t1, 0(s0)		# read character on first half
	lb	t2, 0(s1)		# read character on second half
	beq	t1, t2, match_found	# exit loop if characters equal
	addi	t0, t0, -1		# decrease countdown
	add	s1, s1, 1		# increase second half pointer
	bnez	t0, loop_second_half	# loop if countdown not 0
	sub	s1, s1, a0		# move second half pointer back to half of string
	add	s0, s0, 1		# increase first half pointer
	j	loop_first_half		# loop first half loop
match_found:
	li	t0, 97			# 'a'
	bge	t1, t0, lower_case
	li	t0, 38			# 'A' - 27
	j	next
lower_case:
	li	t0, 96			# 'a' - 1
next:
	sub	t1, t1, t0		# turn ASCII code to priority
	add	s3, s3, t1		# add priority to sum
	bge	s2, s11, end		# end if next line points points to EOF
	mv	s0, s2			# next line is now current line
	j	loop_line
end:
	mv	a0, s3
	call	print_int

	li	a7, 93			# exit
	li	a0, 0			# EXIT_SUCCESS
	ecall


line_length:
	mv	t0, a0
	li	t2, 10			# NL
line_length_loop:
	lb	t3, 0(a0)
	beq	t3, t2, line_length_end
	addi	a0, a0, 1
	j	line_length_loop
line_length_end:
	sub	a0, a0, t0
	ret
