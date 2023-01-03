; day01-part1.asm

extern open_input_file
extern print_int
extern read_int

section .data

    filename    db      "inputs/day01", 0
    SYS_EXIT    equ     60

section .bss

    fd          resq    1

section .text

    global main

main:
    mov     rdi, filename
    call    open_input_file
    mov     [fd], rax
    xor     r8, r8

loop:
    mov     rdi, [fd]
    call    read_group
    test    rax, rax
    jz      end
    cmp     rax, r8
    jb      loop
    mov     r8, rax
    jmp     loop

end:
    mov     rdi, r8
    call    print_int

    mov     rax, SYS_EXIT
    mov     rdi, 0
    syscall


read_group:
    xor     r9, r9
read_group_loop:
    call    read_int
    cmp     rax, 0
    jng     read_group_end
    add     r9, rax
    jmp     read_group_loop
read_group_end:
    mov     rax, r9
    ret

