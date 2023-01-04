; day03.asm

extern open_input_file
extern read_line
extern print_int

section .data

    filename    db  "inputs/day03",0
    score       dq   0
    SYS_READ    equ  0
    SYS_WRITE   equ  1
    SYS_CLOSE   equ  3   
    SYS_EXIT    equ 60
    ASCII_A     equ 97
    ASCII_CAP_A equ 65

section .bss

    fd          resq    1
    len         resq    1
    buffer      resb    100
    invent      resb    52

section .text

global main

main:
    mov         rdi, filename
    call        open_input_file
    mov         [fd], rax

main_loop:
    ; reset the inventory
    mov         rcx, 52
    mov         rbx, invent
reset_loop:
    mov         byte [rbx], 0
    inc         rbx
    loop        reset_loop
   
    ; process strings 3 by 3
    mov         rcx, 3
    xor         r15, r15
loop_strings:
    push        rcx 

    ; read a string
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line
    test        rax, rax
    jz          end
    mov         [len], rax

    ; update inventory with the string
    mov         rbx, buffer
    call        update_inventory
    inc         r15
    pop         rcx
    loop        loop_strings

    ; compute score from inventory
    mov         rcx, 52
    mov         rbx, invent
    mov         rdx, 1
score_loop:
    ; value of 3 means the letter is
    ; present on all 3 strings
    cmp         byte [rbx], 3
    jne         skip
    add         [score], rdx
skip:
    inc         rbx 
    inc         rdx
    loop        score_loop

    jmp         main_loop

end:
    mov         rdi, [score]
    call        print_int

    mov         rax, SYS_CLOSE
    mov         rdi, [fd]
    syscall

    mov         rax, SYS_EXIT
    mov         rdi, 0
    syscall


    ; returns the inventory index for a given letter:
    ;  0-25 for a-z
    ; 26-51 for A-Z
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

    
    ; update the inventory with letters from the string:
    ; increase the inventory element if it's equal to value in r15
update_inventory:
    mov         rcx, [len]
loop_update:
    xor         rdi, rdi
    mov         dil, byte [rbx]
    call        get_index
    xor         rdx, rdx
    lea         rax, [invent + rax]
    mov         dl, byte [rax]
    cmp         dl, r15b
    jne         skip_update
    inc         byte [rax]
skip_update:
    inc         rbx
    loop        loop_update
    ret

