	.global set_insert

	.set	RED, 0
	.set	BLACK,	1
	.set	NODE_SIZE,	29
	.set	TREE_SIZE,	16
	.set	TREE_ROOT,	0
	.set	TREE_NIL,	8
	.set	NODE_LEFT,	0
	.set	NODE_RIGHT,	8
	.set	NODE_PREV,	16
	.set	NODE_COLOR,	24
	.set	NODE_KEY,	25

	.section .text

	# a0: tree
	# a1: coordinate X
	# a1: coordinate Y
	# return 1 if the coordinates are successfully inserted
	# or 0 if the coordinates are already present in the tree
set_insert:
	addi	sp, sp, -64
	sd	ra,  0(sp)
	sd	s0,  8(sp)
	sd	s1, 16(sp)
	sd	s3, 32(sp)
	sd	s4, 40(sp)
	sd	s5, 48(sp)

	mv	s0, a0
	
	# combine the couple of coordinates in a single 32-bits value
	slli	a1, a1, 16
	add	s1, a1, a2
	
	ld	s3, TREE_ROOT(s0)	# x = t.root
	ld	s4, TREE_NIL(s0)	# load t.nil
	mv	s5, s4			# y = t.nil

si_while_loop:
	beq	s3, s4, si_while_loop_end
	mv	s5, s3			# y = x
	lw	t0, NODE_KEY(s3)	# x.key
	blt	s1, t0, move_left
	bgt	s1, t0, move_right
	li	a0, 0			# value already present
	j	insert_end
move_left:
	ld	s3, NODE_LEFT(s3)
	j	si_while_loop
move_right:
	ld	s3, NODE_RIGHT(s3)
	j	si_while_loop
si_while_loop_end:
	li	a0, NODE_SIZE
	call	malloc
	sd	s4, NODE_LEFT(a0)	# z.left = T.nil
	sd	s4, NODE_RIGHT(a0)	# z.right = T.nil
	sd	s5, NODE_PREV(a0)	# z.p = y
	li	t0, RED
	sb	t0, NODE_COLOR(a0)	# z.color = RED
	sw	s1, NODE_KEY(a0)

	bne	s5, s4, tree_not_empty	# y != T.nil
	sd	a0, TREE_ROOT(s0)
	j	insert_end_succ
tree_not_empty:
	lw	t0, NODE_KEY(s5)	# y.key
	bgt	s1, t0, store_right	# z.key > y.key
	sd	a0, NODE_LEFT(s5)
	j       insert_end_succ
store_right:
	sd	a0, NODE_RIGHT(s5)

insert_end_succ:	
	mv	a1, a0
	mv	a0, s0
	call	insert_fixup 
	li	a0, 1

insert_end:	
	ld	ra,  0(sp)
	ld	s0,  8(sp)
	ld	s1, 16(sp)
	ld	s3, 32(sp)
	ld	s4, 40(sp)
	ld	s5, 48(sp)
	addi	sp, sp, 64
	ret

