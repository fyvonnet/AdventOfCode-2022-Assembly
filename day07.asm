; day07.asm

extern open_input_file
extern print_int
extern read_line
extern malloc
extern parse_int
extern quicksort

section .data

    filename    db   "inputs/day07",0
    ndirs       dw    1 ; start at 1 for root dir
    dirs_i      dw    0
    disk_space  dq  70000000
    needed      dq  30000000

    SYS_READ    equ   0
    SYS_WRITE   equ   1
    SYS_CLOSE   equ   3   
    SYS_LSEEK   equ   8
    SYS_EXIT    equ  60
    SEEK_SET    equ   0
    ASCII_D     equ 100
    ASCII_DOT   equ  46
    ASCII_DOLLAR    equ 36
    MAX_SIZE    equ 100000

section .bss

    fd          resq     1
    buffer      resb    50
    dirs_sz     resq     1

section .text

global main

main:

    mov         rdi, filename
    call        open_input_file
    mov         [fd], rax

loop_count_dirs:
    ; count directories
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line
    test        rax, rax
    jz          end_count_dirs
    cmp         byte [buffer], ASCII_D
    jne         skip_count
    inc         word [ndirs]
skip_count:
    jmp         loop_count_dirs
end_count_dirs:

    ; rewind the file
    mov         rax, SYS_LSEEK
    mov         rdi, [fd]
    mov         rsi, 0
    mov         rdx, SEEK_SET
    syscall

    ; allocate array for directories sizes
    mov         rax, 8
    mul         word [ndirs]
    mov         rdi, rax
    call        malloc
    mov         [dirs_sz], rax

    ; skip "$ cd /"
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line

    call        dir_size

    ; substract total size of root dir from disk size
    ; to obtain remaining free disk space
    sub         [disk_space], rax

    ; substract free disk space from
    ; total space needed for the update
    mov         rax, [disk_space]
    sub         [needed], rax

    ; sort directories sizes 
    mov         rdi, dirs_sz
    xor         rsi, rsi
    mov         si, [ndirs]
    mov         rdx, 8
    mov         rcx, compar
    call        quicksort

    ; PART 1:
    ; sum all directories no larger than MAX_SIZE
    xor         r8, r8
    xor         r9, r9
loop_part1:
    lea         r10, [dirs_sz + r8 * 8]
    cmp         qword [r10], MAX_SIZE
    jg          end_part1
    add         r9, qword [r10]
    inc         r8
    jmp         loop_part1
end_part1:
    mov         rdi, r9
    call        print_int

    ; PART 2:
    ; find directory at least as big as the 
    ; remaining space needed for update
    xor         r8, r8
loop_part2:
    lea         r9, [dirs_sz + r8 * 8]
    mov         r10, qword [r9]
    cmp         r10, [needed]
    jge         end_part2
    inc         r8
    jmp         loop_part2
end_part2:
    mov         rdi, r10
    call        print_int

    mov         rax, SYS_EXIT
    mov         rdi, 0
    syscall


    ; recursively compute the size of directories
dir_size:
    push        rbp
    mov         rbp, rsp
    sub         rsp, 16
    
    mov         qword [rbp - 8], 0

    ; skip "$ ls"
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line

next_line:
    mov         rdi, [fd]
    mov         rsi, buffer
    call        read_line

    test        rax, rax
    jz          end_dir_size
    
    cmp         byte [buffer], ASCII_DOLLAR
    je          command
    cmp         byte [buffer], ASCII_D
    je          next_line
    mov         rdi, buffer
    call        parse_int
    add         qword [rbp - 8], rax
    jmp         next_line
command: ; either '$ cd ..' or '$ cd <dir>'
    cmp         byte [buffer + 5], ASCII_DOT
    je          end_dir_size
    call        dir_size
    add         qword [rbp - 8], rax
    jmp         next_line
end_dir_size:
    mov         rax, qword [rbp - 8]
    lea         rbx, [dirs_sz]
    xor         rcx, rcx
    mov         cx, [dirs_i]
    lea         r8, [rbx + 8 * rcx + 0]
    mov         qword [r8], rax
    inc         word [dirs_i]
    leave
    ret

compar:
    mov         rax, [rdi]
    sub         rax, [rsi]
    ret

