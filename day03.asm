; day03.asm

extern open_input_file
extern read_line
extern print_int

section .data

    filename    db  "inputs/day03",0
    SYS_READ    equ  0
    SYS_WRITE   equ  1
    SYS_CLOSE   equ  3   
    SYS_EXIT    equ 60
    ASCII_A     equ 97
    ASCII_CAP_A equ 65
    NONE        equ  0
    FIRST       equ  1
    BOTH        equ  2

section .bss

    fd          resq    1
    half_len    resq    1
    buffer      resb    100
    invent      resb    52

section .text

global main

main:
    mov         rdi, filename
    call        open_input_file
    mov         [fd], rax

    xor         r8, r8
main_loop:
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line
    test        rax, rax
    jz          end

    mov         rcx, 52
    mov         rbx, invent
reset_loop:
    mov         [rbx], byte NONE
    inc         rbx
    loop        reset_loop
   
    xor         rdx, rdx
    mov         rbx, 2
    div         rbx
    mov         [half_len], rax

    mov         rbx, buffer

    mov         r14b, NONE
    mov         r15b, FIRST
    call        update_inventory

    mov         r14b, FIRST
    mov         r15b, BOTH
    call        update_inventory

    mov         rcx, 52
    mov         rbx, invent
    mov         rdx, 1
score_loop:
    cmp         [rbx], byte BOTH
    jne         skip
    add         r8, rdx
skip:
    inc         rbx 
    inc         rdx
    loop        score_loop

    jmp         main_loop

end:
    mov         rdi, r8
    call        print_int

    mov         rax, SYS_EXIT
    mov         rdi, 0
    syscall


get_index:
    mov         rax, rdi
    cmp         rax, ASCII_A
    jge         lowercase
    sub         rax, ASCII_CAP_A
    add         rax, 26
    ret
lowercase:
    sub         rax, ASCII_A
    ret

    
update_inventory:
    mov         rcx, [half_len]
loop_update:
    xor         rdi, rdi
    mov         dil, byte [rbx]
    call        get_index
    xor         rdx, rdx
    mov         dl, byte [invent + rax]
    cmp         dl, r14b
    jne         skip_update
    mov         [invent + rax], byte r15b
skip_update:
    inc         rbx
    loop        loop_update
    ret

