    .global main

    .section .rodata

filename:
    .string "inputs/day06"

    .section .text

main:
    la      a0, filename
    call    map_input_file

    mv      s0, a0                  # tail pointer
    mv      s1, a0                  # head pointer

    li      s3, 14                  # constant 14
    li      s4, 0                   # number of unique letters
    mv      s5, s3                  # number of letters received (start at 14)
    li      s6, 1                   # constant 1

    # allocate a 26 bytes letters counter in the stack
    li      t0, 26
loop_alloc:
    addi    sp, sp, -1
    sb      zero, 0(sp)
    addi    t0, t0, -1
    bnez    t0, loop_alloc

    addi    s2, sp, -97             # access letter counter address by adding ascii code to s2

    # initialize the counters with the 14 first letters
    mv      t0, s3
loop_init:
    lb      t1, 0(s1)
    add     t1, t1, s2
    lb      t2, 0(t1)               # load counter value for this letter
    addi    t2, t2, 1               # increase value
    sb      t2, 0(t1)               # store new value
    addi    t0, t0, -1              # decrease countdown
    addi    s1, s1, 1               # increase head letter pointer
    beqz    t0, loop_init_end       # end loop if countdown reached zero
    j       loop_init
loop_init_end:

    # count unique letters in the 14 first letters
    li      t0, 26                  # countdown
    mv      t1, sp                  # counter pointer
    li      t3, 1                   # search value 1
loop_count:
    lb      t2, 0(t1)               # load counter value
    bne     t2, t3, skip_inc        # skip increment counter if not 1
    addi    s4, s4, 1               # increment counter
skip_inc:
    addi    t0, t0, -1              # decrease countdown
    beqz    t0, loop_count_end      # exit loop if countdown null
    addi    t1, t1, 1               # increase counter pointer
    j       loop_count
loop_count_end:

loop_solve:
    beq     s4, s3, loop_solve_end  # exit loop if 14 unique letters

    #remove tail letter
    lb      t1, 0(s0)
    add     t1, t1, s2
    lb      t0, 0(t1)               # load letter counter
    addi    t0, t0, -1              # decrement counter
    sb      t0, 0(t1)               # store back counter
    # if new count for this letter is one, we gain a unique letter
    li      t1, 1
    bne     t0, t1, skip_inc1
    addi    s4, s4, 1
skip_inc1:
    # if new count for this letter is zero, we lose a unique letter
    li      t1, 0
    bne     t0, t1, skip_dec1
    addi    s4, s4, -1
skip_dec1:

    # add head letter
    lb      t1, 14(s0)
    add     t1, t1, s2
    lb      t0, 0(t1)
    addi    t0, t0, 1
    sb      t0, 0(t1)
    # if new count for this letter is one, we gain a unique letter
    li      t1, 1
    bne     t0, t1, skip_inc2
    addi    s4, s4, 1
skip_inc2:
    # if new count for this letter is two, we lose a unique letter
    li      t1, 2
    bne     t0, t1, skip_dec2
    addi    s4, s4, -1
skip_dec2:

    addi    s0, s0, 1
    addi    s5, s5, 1
    j       loop_solve
    

loop_solve_end:

    mv      a0, s5
    call    print_int
    
    li      a7, 93                  # exit
    li      a0, 0                   # EXIT_SUCCESS
    ecall

