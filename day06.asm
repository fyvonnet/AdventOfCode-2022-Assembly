; day06.asm

extern open_input_file
extern print_int
extern read_one_char
extern malloc

section .data

    filename    db  "inputs/day06",0
    array       times 26 db 0
    nuniques    db 0
    SYS_READ    equ  0
    SYS_WRITE   equ  1
    SYS_CLOSE   equ  3   
    SYS_EXIT    equ 60
    ASCII_A     equ 97
    ASCII_NL    equ 10
    ADD_CHAR    equ  1
    REM_CHAR    equ -1

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

    mov         rax, SYS_CLOSE
    mov         rdi, [fd]
    syscall

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

; PART 1

    mov         r9, [input]
    dec         r9
loop_part1:
    inc         r9
    mov         r10b, byte [r9 + 0]
    mov         r11b, byte [r9 + 1]
    mov         r12b, byte [r9 + 2]
    mov         r13b, byte [r9 + 3]

    cmp         r10b, r11b
    je          loop_part1
    cmp         r10b, r12b
    je          loop_part1
    cmp         r10b, r13b
    je          loop_part1
    cmp         r11b, r12b
    je          loop_part1
    cmp         r11b, r13b
    je          loop_part1
    cmp         r12b, r13b
    je          loop_part1
    
    mov         rdi, r9
    sub         rdi, [input]
    add         rdi, 4 ; end of packet *after* the marker
    call        print_int


; PART 2

    mov         rcx, 14
    mov         r8, [input]
loop_fill_array:
    mov         rdi, r8
    mov         rsi, ADD_CHAR
    call        update_array
    inc         r8
    loop        loop_fill_array

    mov         r8, [input]
loop_part2:
    cmp         byte [nuniques], 14
    je          end_part2
    mov         rdi, r8
    mov         rsi, REM_CHAR
    call        update_array
    mov         rdi, r8
    add         rdi, 14
    mov         rsi, ADD_CHAR
    call        update_array
    inc         r8
    jmp         loop_part2

end_part2:

    mov         rdi, r8
    sub         rdi, [input]
    add         rdi, 14
    call        print_int

    mov         rax, SYS_EXIT
    mov         rdi, 0
    syscall

update_array:
    push        r8
    xor         r8, r8
    mov         r8b, byte [rdi]
    lea         r8, [array + r8]
    xor         rax, rax
    mov         al, byte [r8]
    cmp         rax, 1
    jne         skip_rem
    dec         byte [nuniques]
skip_rem:
    add         rax, rsi
    cmp         rax, 1
    jne         skip_add
    inc         byte [nuniques]
skip_add:
    mov         byte [r8], al
    pop         r8
    ret
