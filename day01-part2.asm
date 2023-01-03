; day01-part1.asm

extern open_input_file
extern print_int
extern parse_int
extern read_line
extern malloc
extern quicksort

section .data

    filename    db      "inputs/day01", 0
    SYS_EXIT    equ     60
    SYS_CLOSE   equ      3
    count       dq      0

section .bss

    fd          resq    1
    buffer      resq    10
    list_addr   resq    1

section .text

    global main

main:

    ; read elements and put them on the strack
    mov     rdi, filename
    call    open_input_file
    mov     [fd], rax
read_loop:
    call    read_group
    test    rax, rax
    jz      read_end
    push    rax
    inc     qword [count]
    jmp     read_loop
read_end:
    mov     rax, SYS_CLOSE
    mov     rdi, [fd]
    syscall

    ; allocate array
    mov     rax, 4
    mul     qword [count]
    mov     rdi, rax
    call    malloc
    mov     [list_addr], rax

    ; move elements form the stack to the array
    mov     rcx, qword [count]
    mov     rbx, qword [list_addr]
list_loop:
    pop     rdx
    mov     dword [rbx], edx
    add     rbx, 4
    loop    list_loop

    ; sort array in decreasing order
    mov     rdi, [list_addr]
    mov     rsi, [count]
    mov     rdx, 4
    mov     rcx, compar
    call    quicksort

    ; sum the 3 first elements of the array
    mov     rcx, 3
    xor     rax, rax
    mov     rbx, [list_addr]
sum_loop:
    add     eax, dword [rbx]
    add     rbx, 4
    loop    sum_loop

    ; print sum
    mov     rdi, rax
    call    print_int

    mov     rax, SYS_EXIT
    mov     rdi, 0
    syscall


    ; sum numbers from the input file until a empty line is reached
    ; returns the sum, or 0 if trying to read after EOF is reached
read_group:
    xor     r8, r8
read_group_loop:
    mov     rdi, [fd]
    mov     rsi, buffer
    call    read_line
    test    rax, rax
    jz      read_group_end
    mov     rdi, buffer
    call    parse_int
    add     r8, rax
    jmp     read_group_loop
read_group_end:
    mov     rax, r8
    ret

compar:
    xor     rax, rax
    mov     eax, dword [rsi]
    xor     rbx, rbx
    mov     ebx, dword [rdi]
    sub     rax, rbx
    ret

