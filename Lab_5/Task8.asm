format elf64
public _start

section '.data' writable
    error_args db "Error: Usage: ./program file1.txt file2.txt output.txt", 10, 0
    error_open_msg db "Error: Cannot open file", 10, 0
    error_read_msg db "Error: Cannot read file", 10, 0
    error_write_msg db "Error: Cannot write file", 10, 0
    buffer1 db 0
    buffer2 db 0
    charset db 256 dup(0)

section '.text' executable

_start:
    pop rcx
    cmp rcx, 4
    jne error_arguments

    mov rdi, [rsp+8]
    mov rax, 2
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl error_open
    mov r8, rax

read_file1_loop:
    mov rax, 0
    mov rdi, r8
    mov rsi, buffer1
    mov rdx, 1
    syscall
    cmp rax, 1
    jne file1_done
    mov bl, [buffer1]
    movzx rbx, bl
    mov byte [charset + rbx], 1
    jmp read_file1_loop

file1_done:
    cmp rax, 0
    jl error_read_file1
    mov rax, 3
    mov rdi, r8
    syscall

    mov rdi, [rsp+16]
    mov rax, 2
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl error_open_file2
    mov r9, rax

    mov rdi, [rsp+24]
    mov rax, 2
    mov rsi, 0x241
    mov rdx, 644o
    syscall
    cmp rax, 0
    jl error_open_output
    mov r10, rax

read_file2_loop:
    mov rax, 0
    mov rdi, r9
    mov rsi, buffer2
    mov rdx, 1
    syscall
    cmp rax, 1
    jne file2_done
    mov bl, [buffer2]
    movzx rbx, bl
    cmp byte [charset + rbx], 1
    jne skip_write
    mov rax, 1
    mov rdi, r10
    mov rsi, buffer2
    mov rdx, 1
    syscall
    cmp rax, 1
    jne error_write_file

skip_write:
    jmp read_file2_loop

file2_done:
    cmp rax, 0
    jl error_read_file2
    mov rax, 3
    mov rdi, r9
    syscall
    mov rax, 3
    mov rdi, r10
    syscall
    jmp exit_success

error_arguments:
    mov rsi, error_args
    call print_string
    jmp exit_error

error_open:
    mov rsi, error_open_msg
    call print_string
    jmp exit_error

error_read_file1:
    mov rax, 3
    mov rdi, r8
    syscall
    mov rsi, error_read_msg
    call print_string
    jmp exit_error

error_open_file2:
    mov rax, 3
    mov rdi, r8
    syscall
    mov rsi, error_open_msg
    call print_string
    jmp exit_error

error_open_output:
    mov rax, 3
    mov rdi, r9
    syscall
    mov rsi, error_open_msg
    call print_string
    jmp exit_error

error_read_file2:
    mov rax, 3
    mov rdi, r9
    syscall
    mov rax, 3
    mov rdi, r10
    syscall
    mov rsi, error_read_msg
    call print_string
    jmp exit_error

error_write_file:
    mov rax, 3
    mov rdi, r9
    syscall
    mov rax, 3
    mov rdi, r10
    syscall
    mov rsi, error_write_msg
    call print_string
    jmp exit_error

print_string:
    push rdi
    push rdx
    push rax
    push rcx
    push rsi
    mov rdi, rsi
    call strlen
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    pop rsi
    syscall
    pop rcx
    pop rax
    pop rdx
    pop rdi
    ret

strlen:
    push rcx
    xor rcx, rcx
.strlen_loop:
    cmp byte [rdi + rcx], 0
    je .strlen_done
    inc rcx
    jmp .strlen_loop
.strlen_done:
    mov rax, rcx
    pop rcx
    ret

exit_success:
    mov rax, 60
    xor rdi, rdi
    syscall

exit_error:
    mov rax, 60
    mov rdi, 1
    syscall
