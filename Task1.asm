format ELF64

public main

extrn initscr
extrn endwin
extrn start_color
extrn init_pair
extrn attron
extrn attroff
extrn addch
extrn refresh
extrn getch
extrn printw
extrn move
extrn clear
extrn napms

section '.data' writable
    filename db "text.txt", 0
    buffer_size equ 4096
    delay_time dd 50

section '.bss' writable
    fd          dq 0
    buffer      rb buffer_size
    bytes_read  dq 0
    cur_y       dq 0
    cur_x       dq 0
    color_idx   dq 0
    char        dq 0

section '.text' executable

main:
    push rbp
    mov rbp, rsp

    mov rax, 2
    mov rdi, filename
    xor rsi, rsi
    syscall

    cmp rax, 0
    jl .error
    mov [fd], rax

    call initscr
    call start_color

    mov rdi, 1
    mov rsi, 1
    xor rdx, rdx
    call init_pair

    mov rdi, 2
    mov rsi, 2
    xor rdx, rdx
    call init_pair

    mov rdi, 3
    mov rsi, 3
    xor rdx, rdx
    call init_pair

    mov rdi, 4
    mov rsi, 4
    xor rdx, rdx
    call init_pair

    mov rdi, 5
    mov rsi, 5
    xor rdx, rdx
    call init_pair

    call clear

    mov qword [cur_y], 0
    mov qword [cur_x], 0
    mov qword [color_idx], 1

.read_loop:
    mov rax, 0
    mov rdi, [fd]
    mov rsi, buffer
    mov rdx, buffer_size
    syscall

    cmp rax, 0
    jle .close_file

    mov [bytes_read], rax
    xor rbx, rbx

.print_buffer:
    cmp rbx, [bytes_read]
    jge .read_loop

    movzx rax, byte [buffer + rbx]
    mov [char], rax

    cmp rax, 10
    je .handle_newline
    cmp rax, 13
    je .handle_carriage_return

    mov rdi, [cur_y]
    mov rsi, [cur_x]
    call move

    mov rax, [color_idx]
    shl rax, 8
    mov rdi, rax
    call attron

    mov rdi, [char]
    call addch

    mov rax, [color_idx]
    shl rax, 8
    mov rdi, rax
    call attroff

    mov rax, [color_idx]
    inc rax
    cmp rax, 6
    jl .store_color
    mov rax, 1
.store_color:
    mov [color_idx], rax

    inc qword [cur_x]

    mov edi, [delay_time]
    call napms

    call refresh
    jmp .next_char

.handle_newline:
    inc qword [cur_y]
    mov qword [cur_x], 0
    mov rax, [color_idx]
    inc rax
    cmp rax, 6
    jl .store_color_nl
    mov rax, 1
.store_color_nl:
    mov [color_idx], rax
    jmp .next_char

.handle_carriage_return:
    jmp .next_char

.next_char:
    inc rbx
    jmp .print_buffer

.close_file:
    mov rax, 3
    mov rdi, [fd]
    syscall

    mov rdi, [cur_y]
    add rdi, 2
    mov rsi, 0
    call move

    mov rdi, 0
    call attron
    mov rdi, message
    call printw
    mov rdi, 0
    call attroff

    call refresh
    call getch
    call endwin

    xor rax, rax
    pop rbp
    ret

.error:
    mov rax, 60
    mov rdi, 1
    syscall

section '.data' writable
    message db "Press any key to exit...", 0
