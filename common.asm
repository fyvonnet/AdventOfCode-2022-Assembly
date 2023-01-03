; common.asm

section .data

    ASCII_ZERO      equ 48
    ASCII_NINE      equ 57
    ASCII_NL        equ 10
    SYS_READ        equ 0
    SYS_WRITE       equ 1
    SYS_OPEN        equ 2
    STDOUT          equ 1
    O_RDONLY        equ 0

section .bss

    buffer          resb 100

section .text

    global open_input_file
    global print_int
    global parse_int
    global read_int
    global read_line
    global read_one_char

open_input_file:
    mov         rax, SYS_OPEN
    mov         rsi, O_RDONLY
    mov         rdx, 0
    syscall
    ret

read_one_char:
    mov         rax, SYS_READ
    mov         rsi, buffer
    mov         rdx, 1
    syscall
    test        rax, rax
    jz          read_one_char_eof
    xor         rax, rax
    mov         al, byte [buffer]
    ret
read_one_char_eof:
    mov         rax, -1
    ret

parse_int:
    push        rbp
    mov         rbp, rsp
    sub         rsp, 16

    mov         qword [rbp - 8], 0
parse_int_loop:
    xor         rax, rax
    mov         al, byte [rdi]
    cmp         rax, ASCII_ZERO
    jb          parse_int_end
    cmp         rax, ASCII_NINE
    ja          parse_int_end
    sub         rax, ASCII_ZERO

    mov         rbx, rax
    mov         rax, qword [rbp - 8]
    mov         rcx, 10
    mul         rcx
    add         rax, rbx
    mov         qword [rbp - 8], rax
    inc         rdi
    jmp         parse_int_loop

parse_int_end:
    mov         rax, [rbp - 8]

    leave
    ret


read_int:
    push        rbp
    mov         rbp, rsp
    sub         rsp, 16

    mov         qword [rbp - 8], 0
read_int_loop:
    call        read_one_char
    cmp         rax, -1
    je          read_int_eof
    cmp         rax, ASCII_ZERO
    jb          read_int_end
    cmp         rax, ASCII_NINE
    ja          read_int_end
    sub         rax, ASCII_ZERO

    mov         rbx, rax
    mov         rax, [rbp - 8]
    mov         rcx, 10
    mul         rcx
    add         rax, rbx
    mov         [rbp - 8], rax
    jmp         read_int_loop

read_int_eof:
    mov         QWORD [rbp - 8], -1

read_int_end:
    mov         rax, [rbp - 8]

    leave
    ret

print_int:
    xor         rcx, rcx
    mov         rax, rdi

divide_loop:
    inc         rcx
    xor         rdx, rdx
    mov         rbx, 10
    div         rbx
    add         rdx, ASCII_ZERO
    push        rdx
    test        rax, rax
    jnz         divide_loop

    mov         rax, buffer
    mov         rdx, rcx
    inc         rdx
string_loop:
    pop         rbx
    mov         [rax], byte bl
    inc         rax
    loop        string_loop

    ;mov         [rax], byte 10
    mov         byte [rax], 10
    mov         rax, SYS_WRITE
    mov         rdi, STDOUT
    mov         rsi, buffer
    syscall
    ret


read_line:
    push        r8
    xor         r8, r8
read_line_loop:
    push        rsi
    call        read_one_char
    pop         rsi
    cmp         rax, ASCII_NL
    je          read_line_end
    cmp         rax, -1
    je          read_line_end
    mov         BYTE [rsi], al
    inc         r8
    inc         rsi
    jmp         read_line_loop
read_line_end:
    ;inc         rsi
    mov         BYTE [rsi], 0
    mov         rax, r8
    pop         r8
    ret
