	.global main

        .macro  INC reg
        addi \reg, \reg, 1
        .endm

        .macro  DEC reg
        addi \reg, \reg, -1
        .endm

	.macro	ZERO reg
	mv \reg, zero
	.endm

	.macro	READ_TWO_LINES
	addi	sp, sp, -16
	addi	s5, s5, 2
	call	decode
	sd	a1, 0(sp)
	call	decode
	sd	a1, 8(sp)
	inc	a0					# skip empty line
	.endm

	.set	SYS_EXIT, 93
	.set	EXIT_SUCCESS, 0
	.set	ASCII_LBRACK, 91
	.set	ASCII_RBRACK, 93
	.set	ASCII_COMMA, 44
	.set	NODE_SIZE, 17

	.section .bss

one_element:
	.zero	NODE_SIZE

	.section .rodata

divider_packets:
	.string	"[[2]]\n[[6]]\n\n"

func_ptrs:
	.quad 	int_vs_int, int_vs_list, list_vs_int, list_vs_list

filename:
	.string "inputs/day13"

	.section .text

main:
	la      a0, filename
	call    map_input_file

	add	s11, a0, a1
	li	s1, 1					# initialize index
	zero	s3					# initialize sum
	mv	s4, sp					# save stack pointer
	zero	s5					# initialize counter

loop_read:
	read_two_lines
	blt	a0, s11, loop_read

loop_compare:
	addi	s4, s4, -16
	ld	a0, 0(s4)
	ld	a1, 8(s4)
	call	compare
	bltz	a0, skip_add
	add	s3, s3, s1
skip_add:
	inc	s1
	bne	s4, sp, loop_compare
	

	mv	a0, s3
	call	print_int

	la	a0, divider_packets
	read_two_lines
	ld	s10, 0(sp)
	ld	s11, 8(sp)

	# sort packets
	mv	a0, sp
	mv	a1, s5
	li	a2, 8
	la	a3, sort_compare
	call	quicksort

	# search divider packets in sorted list and solve part 2
	mv	a0, s10
	call	search
	mv	s9, a0
	mv	a0, s11
	call	search
	mul	a0, s9, a0
	call	print_int

	li      a7, SYS_EXIT
	li      a0, EXIT_SUCCESS
	ecall

search:
	mv	t0, sp
	li	t2, 1
search_loop:
	ld	t1, 0(t0)
	beq	t1, a0, search_end
	addi	t0, t0, 8
	inc	t2
	j	search_loop
search_end:
	mv	a0, t2
	ret


sort_compare:
	addi	sp, sp, -8
	sd	ra, 0(sp)
	ld	t0, 0(a0)
	ld	t1, 0(a1)
	mv	a0, t1
	mv	a1, t0
	call	compare
	ld	ra, 0(sp)
	addi	sp, sp, 8
	ret


compare:
	addi	sp, sp, -24
	sd	ra,  0(sp)
	sd	a0,  8(sp)
	sd	a1, 16(sp)

	# check for empty lists
	bnez	a0, left_not_null
	bnez	a1, right_not_null
	# left and right both empty, order not yet decided
	li	a0, 0
	addi	sp, sp, 24
	ret
right_not_null:
	# only left empty => right order
	li	a0, 1
	addi	sp, sp, 24
	ret
left_not_null:
	bnez	a1, both_not_null
	# only right empty => wrong order
	li	a0, -1
	addi	sp, sp, 24
	ret
both_not_null:
	# none are empty, keep comparison

	# load values
	ld	t5, 1(a0)
	ld	t6, 1(a1)

	# check for type of data
	lb	t0, 0(a0)
	lb	t1, 0(a1)
	slli	t0, t0, 1
	add	t0, t0, t1
	li	t1, 8
	mul	t0, t0, t1
	la	t1, func_ptrs
	add	t1, t1, t0
	ld	t0, 0(t1)
	jr	t0
int_vs_int:
	sub	t0, t6, t5				# compare the two integers
	beqz	t0, compare_next_ints			# if they are equal compare the next elements
	mv	a0, t0					# if they are different, return the differences
	j	compare_end
compare_next_ints:
	ld	a0, 9(a0)
	ld	a1, 9(a1)
	call	compare
	ld	ra,  0(sp)
	addi	sp, sp, 24
	ret
int_vs_list:
	ld	a1, 1(a1)
	la	a0, one_element
	sd	t5, 1(a0)
	j	call_compare
list_vs_int:
	ld	a0, 1(a0)
	la	a1, one_element
	sd	t6, 1(a1)
	j	call_compare
list_vs_list:
	mv	a0, t5
	mv	a1, t6
call_compare:
	call	compare
	bnez	a0, compare_end
	ld	a0,  8(sp)
	ld	a1, 16(sp)

compare_next:
	ld	a0, 9(a0)
	ld	a1, 9(a1)
	call	compare

compare_end:
	ld	ra,  0(sp)
	addi	sp, sp, 24
	ret

decode:
	addi	sp, sp, -8
	sd	ra, 0(sp)
	call	decode_
	addi	a0, a0, 2				# skip "]\n"
	ld	ra, 0(sp)
	addi	sp, sp, 8
	ret

decode_:
	addi	sp, sp, -32
	sd	s0,  0(sp)
	sd	s1,  8(sp)
	sd	ra, 16(sp)
	zero	s0
	lb	t0, 1(a0)
	li	t1, ASCII_RBRACK			# list start with a closing bracket, empty list
	bne	t0, t1, decode_loop
	mv	a1, zero				# return null pointer
	inc	a0
	j	decode_ret
decode_loop:
	inc	a0					# skip [
	sd	a0, 24(sp)				# save input pointer
	li	a0, NODE_SIZE
	call	malloc
	sd	zero, 9(a0)				# null next pointer
	bnez	s0, skip1
	mv	s0, a0
	mv	s1, a0
	j	skip2
skip1:
	sd	a0, 9(s1)				# attach new node to tail node
	mv	s1, a0					# new node is now tail node
skip2:
	ld	a0, 24(sp)				# restore input pointer
	lb	t0, 0(a0)
	li	t1, ASCII_LBRACK
	beq	t0, t1, decode_list			# check if list or integer
	call	parse_integer
	sb	zero, 0(s1)				# content type is integer
	sd	a1, 1(s1)				# store integer in tail node
decode_back:
	# check if end of list reached
	lb	t0, 0(a0)
	li	t1, ASCII_COMMA
	beq	t0, t1, decode_loop
	mv	a1, s0
decode_ret:
	ld	s0,  0(sp)
	ld	s1,  8(sp)
	ld	ra, 16(sp)
	addi	sp, sp, 32
	ret
decode_list:
	li	t0, 1
	sb	t0, 0(s1)
	call	decode_
	sd	a1, 1(s1)
	inc	a0
	j	decode_back
