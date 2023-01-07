; day06.asm

extern open_input_file
extern print_int
extern read_one_char
extern malloc

section .data

    filename    db  "inputs/day06",0
    SYS_READ    equ  0
    SYS_WRITE   equ  1
    SYS_CLOSE   equ  3   
    SYS_EXIT    equ 60
    ASCII_A     equ 97
    ASCII_NL    equ 10

section .bss

    fd          resq     1
    input       resq     1

section .text

global main

main:

    mov         rdi, filename
    call        open_input_file
    mov         [fd], rax

    xor         r8, r8
loop_read:
    mov         rdi, [fd]
    call        read_one_char
    cmp         rax, ASCII_NL
    je          end_read
    inc         r8
    sub         rax, ASCII_A
    push        rax
    jmp         loop_read
end_read:

    mov         rdi, r8
    push        r8
    call        malloc
    pop         r8
    mov         [input], rax
    mov         r9, rax
    add         r9, r8
    dec         r9
    mov         rcx, r8

loop_fill:
    pop         rax
    mov         byte [r9], al
    dec         r9
    loop        loop_fill

    mov         r8, 0
    mov         r9, [input]
    dec         r9
loop:
    inc         r8
    inc         r9
    mov         r10b, byte [r9 + 0]
    mov         r11b, byte [r9 + 1]
    mov         r12b, byte [r9 + 2]
    mov         r13b, byte [r9 + 3]

    cmp         r10b, r11b
    je          loop
    cmp         r10b, r12b
    je          loop
    cmp         r10b, r13b
    je          loop
    cmp         r11b, r12b
    je          loop
    cmp         r11b, r13b
    je          loop
    cmp         r12b, r13b
    je          loop
    
    add         r8, 3 ; end of packet *after* the marker

    mov         rdi, r8
    call        print_int

    mov         rax, SYS_EXIT
    mov         rdi, 0
    syscall

