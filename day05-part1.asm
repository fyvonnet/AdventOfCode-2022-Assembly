; day05.asm

extern open_input_file
extern read_line
extern print_int
extern parse_int
extern malloc
extern free

section .data

    filename    db  "inputs/day05",0
    ASCII_BRKT  equ 91
    ASCII_SPACE equ 32
    ASCII_ONE   equ 49
    SYS_READ    equ  0
    SYS_WRITE   equ  1
    SYS_CLOSE   equ  3   
    SYS_EXIT    equ 60
    BUFFSIZE    equ 50
    nstacks     dq   0
    nlayers     dq   0

section .bss

    buffer      resb    BUFFSIZE
    fd          resq    1
    stacks      resq    1

section .text

global main

main:

    mov         rdi, filename
    call        open_input_file
    mov         [fd], rax

    ; read the crate layers from the
    ; input file and put them on the stack
    xor         r9, r9
loop_read_stacks:
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line
    cmp         byte [buffer + 1], ASCII_ONE
    je          end_read_stacks
    inc         qword [nlayers]
    mov         r8, rax
    mov         rdi, BUFFSIZE
    push        r8
    call        malloc
    pop         r8
    mov         rbx, rax
    mov         rcx, BUFFSIZE
loop_fill_str:
    mov         byte [rbx], ASCII_SPACE
    inc         rbx
    loop        loop_fill_str
    mov         rsi, buffer
    mov         rdi, rax
    mov         rcx, r8
    rep         movsb
    push        rax
    jmp         loop_read_stacks

end_read_stacks:

    call        pop_layer

    ; count stacks
    xor         rsi, rsi
    mov         rbx, buffer
    mov         rcx, BUFFSIZE
loop_count_stacks:
    cmp         byte [rbx], ASCII_BRKT
    jne         skip
    inc         qword [nstacks]
skip:
    inc         rbx
    loop        loop_count_stacks

    ; allocate array of stacks
    mov         rax, 8
    mul         qword [nstacks]
    mov         rdi, rax
    call        malloc
    mov         [stacks], rax

    ; fill stacks array with null pointers
    xor         r8, r8
    mov         rcx, [nstacks]
loop_zero_stacks:
    mov         qword [stacks + r8 * 8], 0
    inc         r8
    loop        loop_zero_stacks
    
    ; build stacks as linked lists
loop_build_layers:
    mov         rbx, buffer
    inc         rbx ; skip to first digit
    mov         r8, 1  ; stack numbering starts at 1

loop_build_stacks:
    cmp         byte [rbx], ASCII_SPACE
    je          skip_stack
    mov         rdi, 9 ; one byte for the letter, 8 for the pointer
    push        r8
    call        malloc
    pop         r8
    mov         rdi, rax
    mov         rsi, r8
    call        push_crate
    ; copy letter
    mov         r9b, byte [rbx]
    mov         byte [rax + 0], r9b
skip_stack:
    add         rbx, 4 ; skip to next digit
    inc         r8 ; next stack
    cmp         r8, [nstacks]
    jg          next_layer
    jmp         loop_build_stacks
next_layer:
    dec         byte[nlayers]
    cmp         byte[nlayers], 0
    je          end_build_stacks
    call        pop_layer
    jmp         loop_build_layers

end_build_stacks:

    ; skip empty line
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line

loop_move_crates:
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line
    test        rax, rax
    jz          end_move_crates
    mov         rdi, buffer
    add         rdi, 5 ; skip "move "
    call        parse_int
    mov         r8, rax
    add         rdi, 6 ; skip " from "
    call        parse_int
    mov         r9, rax
    add         rdi, 4 ; skip " to "
    call        parse_int
    mov         r10, rax
    nop
move:
    mov         rdi, r9
    call        pop_crate
    mov         rdi, rax
    mov         rsi, r10
    call        push_crate
    dec         r8
    jnz         move
    jmp         loop_move_crates
end_move_crates:

    mov         r8, buffer
    mov         r9, 1
loop_display:
    mov         rdi, r9
    call        pop_crate
    mov         r10b, byte [rax]
    mov         byte [r8], r10b
    inc         r8
    inc         r9
    cmp         r9, [nstacks]
    jle         loop_display

    mov         byte [r8], 10
    inc         r8
    mov         byte [r8], 0
        
    mov rax,    SYS_WRITE
    mov rdi,    1
    mov rsi,    buffer
    mov rdx,    [nstacks]
    inc rdx
    syscall

    mov         rax, SYS_EXIT
    mov         rdi, 0
    syscall

pop_crate:
    ; pop a create from the stack
    ; rdi: stack number
    ; returns crate address
    dec         rdi
    lea         rcx, [stacks + rdi * 8]
    mov         rax, [rcx]
    mov         rbx, [rax + 1]
    mov         [rcx], rbx
    ret

push_crate:
    ; push a crate on a stack:
    ; rdi: crate address
    ; rsi: stack number
    ; no return value
    push        r9
    dec         rsi
    ; copy ptr to previous top crate
    lea         rcx, [stacks + rsi * 8]
    mov         r9, [rcx]
    mov         [rdi + 1], r9
    ; copy ptr to new crate to stacks array
    mov         [rcx], rdi
    pop         r9
    ret


pop_layer:
    ; pop a layer from the stack
    ; and copy it to the buffer
    ; no parameters
    ; no return value
    pop         rdi ; pop return address
    pop         rsi ; pop layer address
    push        rdi ; push return address
    push        rsi ; push layer address
    mov         rdi, buffer
    mov         rcx, BUFFSIZE
    rep         movsb
    pop         rdi ; pop layer address
    call        free
    ret
    

