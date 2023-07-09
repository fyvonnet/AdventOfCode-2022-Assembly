    .global main

    .section .rodata
filename:
    .string "inputs/day05"
    #.string "inputs/day05-test"

    .section .text

main:
    la      a0, filename
    call    map_input_file
    mv      s0, a0
    add     s11, a0, a1

    # compute number of stacks from first line length 
    # (all start stacks input lines have the same length)
    call    line_length
    addi    a0, a0, 1
    li      t0, 4
    div     s1, a0, t0              # s1 contains number of stacks
    mv      s3, a0                  # s3 contains line length

    # allocate a vector of pointers for the stacks
    mv      a0, s1
    li      a1, 8
    call    calloc
    mv      s2, a0                  # s2 contains the vector's address

    # store line start addresses on The Stack to process lines in reverse order
    addi    sp, sp, -8
    sd      zero, 0(sp)
    addi    s0, s0, 1               # skip first character
    li      t1, 49                  # '1'
loop_store:
    lb      t0, 0(s0)
    beq     t0, t1, loop_store_end  # stacks number line reached
    addi    sp, sp, -8
    sd      s0, 0(sp)
    add     s0, s0, s3              # add line length to pointer
    j       loop_store
loop_store_end:

    # build stacks as linked lists
loop_lines:
    mv      s3, s2                  # stacks vector pointer
    mv      s4, s1                  # stacks countdown
    ld      s6, 0(sp)               # pop line address from The Stack
    addi    sp, sp, 8
    beqz    s6, loop_lines_end      # null address poped, no more lines to process
loop_stacks:
    lb      s5, 0(s6)               # read crate letter or space if no crate
    li      t0, 32                  # ' '
    beq     s5, t0, skip_push       # no stack element here
    li      a0, 9                   # allocate linked list node
    call    malloc
    ld      t0, 0(s3)               # load addr of head linked list node
    sb      s5, 0(a0)               # store stack element on node
    sd      t0, 1(a0)               # store head node addr as current node's next node addr
    sd      a0, 0(s3)               # current node is new head node
skip_push:
    addi    s4, s4, -1              # decrement countdown
    beqz    s4, loop_lines          # countdown reached 0, move on to next line
    addi    s3, s3, 8               # point to next stack's ll head
    addi    s6, s6, 4               # skip to next stack element
    j       loop_stacks
loop_lines_end:

    # move input pointer to the movements part
    mv      a0, s0
    call    skip_to_next_line
    addi    a0, a0, 1

    # apply movements
    li      s8, 8
loop_movements:
    addi    a0, a0, 5               # skip "move "
    call    parse_integer
    mv      s3, a1                  # s3 contains number of crates to move
    addi    a0, a0, 6               # skip " from "
    call    parse_integer
    mv      s4, a1
    addi    s4, s4, -1              # convert stack number to index
    mul     s4, s4, s8
    add     s4, s4, s2              # s4 points to "from" stack
    addi    a0, a0, 4               # skip " to "
    call    parse_integer
    mv      s5, a1
    addi    s5, s5, -1              # convert stack number to index
    mul     s5, s5, s8
    add     s5, s5, s2              # s5 points to "to" stack
    addi    a0, a0, 1               # skip "\n"

    ld      t0, 0(s4)               # load address of top crate in "from" stack
    ld      t1, 0(s5)               # load address of top crate in "to" stack
    mv      t2, t0
loop_select:
    addi    s3, s3, -1              # one less crate to move
    beqz    s3, loop_select_end     # exit loop if no more crate to move
    ld      t2, 1(t2)               # load address of next crate
    j       loop_select
loop_select_end:
    ld      t3, 1(t2)               # load address of the crate under the last moved one
    sd      t3, 0(s4)               # crate now becomes top crate in the "from" stack
    sd      t1, 1(t2)               # put moved crates on top of "to" stack
    sd      t0, 0(s5)               # top moved crate is the new top crate in the "to" stack

    blt     a0, s11, loop_movements

    # display answer
    addi    sp, sp, -2
    sb      zero, 1(sp)
    li      t0, 10                  # '\n'
    sb      t0, 0(sp)
    sub     sp, sp, s1              # allocate one char per stack in The Stack
    li      a7, 64                  # write
    li      a0, 0                   # stdout
    mv      a1, sp                  # point to start of string
    addi    a2, s1, 1               # one char per stack + '\n'
loop_char:
    ld      t1, 0(s2)               # load address of top crate
    lb      t0, 0(t1)               # load letter
    sb      t0, 0(sp)               # copy letter to The Stack
    addi    s2, s2, 8               # move to next stack
    addi    sp, sp, 1               # move to next character 
    addi    s1, s1, -1              # decrease stacks countdown
    bnez    s1, loop_char

    ecall

    li      a7, 93                  # exit
    li      a0, 0                   # EXIT_SUCCESS
    ecall
    
