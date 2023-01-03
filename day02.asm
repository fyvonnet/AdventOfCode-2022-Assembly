; day02.asm

extern open_input_file
extern print_int

section .data

    filename    db  "inputs/day02",0
    SYS_READ    equ  0
    SYS_WRITE   equ  1
    SYS_CLOSE   equ  3   
    SYS_EXIT    equ 60
    ASCII_CAP_A equ 65
    ASCII_CAP_X equ 88
    L           equ 0
    D           equ 3
    W           equ 6
    R           equ 1
    P           equ 2
    S           equ 3
    OP          equ buffer
    PL          equ buffer + 2

    ;                 opponent's shape:
    ;                ROCK PAPER SCISSOR
    result      db   D+R, L+R,   W+R,    ; ROCK  
                db   W+P, D+P,   L+P,    ; PAPER    :player's shape
                db   L+S, W+S,   D+S     ; SCISSOR 
    shape       db   S+L, R+L,   P+L     ; LOSE 
                db   R+D, P+D,   S+D     ; DRAW     :player's result
                db   P+W, S+W,   R+W     ; WIN  

section .bss

    buffer      resb    4
    fd          resq    1

section .text

global main

main:
    mov         rdi, filename
    call        open_input_file
    mov         [fd], rax

    xor         r8, r8
    xor         r9, r9

loop:
    mov         rax, SYS_READ
    mov         rdi, [fd]
    mov         rsi, buffer
    mov         rdx, 4
    syscall

    test        rax, rax
    jz          loop_end

    xor         rbx, rbx
    xor         rcx, rcx

    mov         bl, byte [PL]
    sub         bl, ASCII_CAP_X
    mov         cl, byte [OP]
    sub         cl, ASCII_CAP_A

    mov         rax, 3
    mul         rbx
    add         al, cl

    mov         cl, byte [result + rax]
    add         r8, rcx
    mov         cl, byte [shape + rax]
    add         r9, rcx

    jmp loop


loop_end:

    mov         rdi, r8
    call        print_int
    mov         rdi, r9
    call        print_int

    mov         rax, SYS_CLOSE
    mov         rdi, [fd]
    syscall

    mov         rax, SYS_EXIT
    mov         rdi, 0
    syscall

