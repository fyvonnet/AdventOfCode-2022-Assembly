    .global main

    .section .rodata
filename:
    .string "inputs/day06"

    .section .text
main:
    la      a0, filename
    call    map_input_file

    mv      s0, a0
    addi    s1, a0, 4               # checks can only start when 4 characters have been received

    lb      t0, 0(s0)
    lb      t1, 1(s0)
    lb      t2, 2(s0)
    lb      t3, 3(s0)
loop:
    beq     t0, t1, check_failed
    beq     t0, t2, check_failed
    beq     t0, t3, check_failed
    beq     t1, t2, check_failed
    beq     t1, t3, check_failed
    beq     t2, t3, check_failed
    j       loop_end
check_failed:
    mv      t0, t1
    mv      t1, t2
    mv      t2, t3
    lb      t3, 0(s1)
    addi    s1, s1, 1
    j       loop
loop_end:
    sub     a0, s1, s0
    call    print_int
    
    li      a7, 93                  # exit
    li      a0, 0                   # EXIT_SUCCESS
    ecall

