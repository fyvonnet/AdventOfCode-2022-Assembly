	.global _start

	.section .rodata
filename:
	.string "inputs/day04"

	.section .text
_start:
	la	a0, filename
	call	map_input_file
	add	s11, a0, a1
	li	s5, 0

loop:
	call	parse_integer
	mv	s1, a1
	addi	a0, a0, 1
	call	parse_integer
	mv	s2, a1
	addi	a0, a0, 1
	call	parse_integer
	mv	s3, a1
	addi	a0, a0, 1
	call	parse_integer
	mv	s4, a1
	addi	a0, a0, 1

	li	t0, 1

	# testing for WRONG cases!

	# s1---s2 s3---s4
	ble 	s3, s2, next_case
	ble	s4, s1, next_case
	li	t0, 0
	j	end_tests

next_case:
	# s3---s4 s1---s2
	ble	s2, s3, end_tests
	ble	s1, s4, end_tests
	li	t0, 0
	
end_tests:
	add	s5, s5, t0
	blt	a0, s11, loop
	mv	a0, s5
	call	print_int

	li	a7, 93				# exit
	li	a0,  0				# EXIT_SUCCESS
	ecall

