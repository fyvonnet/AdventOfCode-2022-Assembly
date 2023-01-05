; day04.asm

extern open_input_file
extern print_int
extern parse_int
extern read_line

section .data

    filename    db  "inputs/day04",0
    counter1    dq   0
    counter2    dq   0
    SYS_READ    equ  0
    SYS_WRITE   equ  1
    SYS_CLOSE   equ  3   
    SYS_EXIT    equ 60

section .bss

    fd          resq     1
    buffer      resb    20
    values      resb     4

section .text

global main

main:
    mov         rdi, filename
    call        open_input_file
    mov         [fd], rax

loop:
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line
    test        rax, rax
    jz          end

    inc         qword [counter2]

    ; load all 4 values in memory
    mov         rbx, values
    mov         rcx, 4
    mov         rdi, buffer
loop_load:
    push        rbx
    push        rcx
    call        parse_int
    pop         rcx
    pop         rbx
    mov         byte [rbx], al
    inc         rbx
    inc         rdi
    loop        loop_load
    
    xor         r8, r8
    xor         r9, r9
    xor         r10, r10
    xor         r11, r11

    mov         r8b,  byte [values + 0]
    mov         r9b,  byte [values + 1]
    mov         r10b, byte [values + 2]
    mov         r11b, byte [values + 3]

    ; part 1

    ; case 1: 
    ;  A-B
    ; C---D
    ; (A >= C) && (B <= D)
    cmp         r8b, r10b
    jl          next_case1
    cmp         r9b, r11b
    jg          next_case1
    jmp         fully_contains
next_case1:
    ; case 2: 
    ;  C-D
    ; A---B
    ; (A <= C) && (B >= D)
    cmp         r8b, r10b
    jg          end_part1
    cmp         r9b, r11b
    jl          end_part1
    jmp         fully_contains
fully_contains:
    inc         qword [counter1]
end_part1:

    ; part 2
    ; test for *non-overlaping* ranges

    ; case 1:
    ; A-B C-D
    ; (B < C)
    cmp         r9b, r10b
    jge         next_test2
    jmp         non_overlapping
next_test2:
    ; case 2:
    ; C-D A-B
    ; (D < A)
    cmp         r11b, r8b
    jge         end_tests2
non_overlapping:
    dec         qword[counter2] ; deduct from total count
end_tests2:
    jmp         loop


end:
    mov         rax, SYS_CLOSE
    mov         rdi, [fd]
    syscall

    mov         rdi, [counter1]
    call        print_int
    
    mov         rdi, [counter2]
    call        print_int

    mov         rax, SYS_EXIT
    mov         rdi, 0
    syscall

