format elf64
public _start

section '.data' writable
    usage_msg db "Usage: ./decrypt <input> <output> <k>", 10
    usage_len = $ - usage_msg
    error_open db "Error opening file", 10
    error_open_len = $ - error_open
    error_read db "Error reading file", 10
    error_read_len = $ - error_read
    error_write db "Error writing file", 10
    error_write_len = $ - error_write
    error_k db "Error: k must be a number", 10
    error_k_len = $ - error_k

section '.bss' writable
    input_fd dq 0
    output_fd dq 0
    buffer rb 1
    k_value db 0

section '.text' executable

_start:
    pop rcx
    cmp rcx, 4
    jne usage_error

    pop rsi
    pop rsi
    mov rdi, rsi
    call open_input

    pop rsi
    mov rdi, rsi
    call open_output

    pop rsi
    call parse_k
    mov [k_value], al

read_loop:
    call read_char
    test rax, rax
    jz close_files

    mov al, [buffer]
    call decrypt_char
    mov [buffer], al

    mov rsi, buffer
    mov rdx, 1
    call write_buf
    jmp read_loop

close_files:
    mov rax, 3
    mov rdi, [input_fd]
    syscall

    mov rax, 3
    mov rdi, [output_fd]
    syscall

    jmp exit

usage_error:
    mov rsi, usage_msg
    mov rdx, usage_len
    call print_error
    jmp exit

open_input:
    mov rax, 2
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl open_error
    mov [input_fd], rax
    ret

open_output:
    mov rax, 2
    mov rsi, 0x41
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl open_error
    mov [output_fd], rax
    ret

open_error:
    mov rsi, error_open
    mov rdx, error_open_len
    call print_error
    jmp exit

read_char:
    mov rax, 0
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, 1
    syscall
    cmp rax, 0
    jl read_error
    ret

read_error:
    mov rsi, error_read
    mov rdx, error_read_len
    call print_error
    jmp exit

write_buf:
    mov rax, 1
    mov rdi, [output_fd]
    syscall
    cmp rax, 0
    jl write_error
    ret

write_error:
    mov rsi, error_write
    mov rdx, error_write_len
    call print_error
    jmp exit

parse_k:
    xor rax, rax
    xor rcx, rcx
parse_loop:
    mov cl, [rsi]
    cmp cl, 0
    je parse_done
    cmp cl, '0'
    jb k_error
    cmp cl, '9'
    ja k_error
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp parse_loop
parse_done:
    ret

k_error:
    mov rsi, error_k
    mov rdx, error_k_len
    call print_error
    jmp exit

decrypt_char:
    cmp al, 'A'
    jb decrypt_done
    cmp al, 'Z'
    ja check_lower
    ; Заглавная буква
    sub al, 'A'
    sub al, [k_value]
    jns .no_wrap_upper
    add al, 26
.no_wrap_upper:
    add al, 'A'
    jmp decrypt_done
check_lower:
    cmp al, 'a'
    jb decrypt_done
    cmp al, 'z'
    ja decrypt_done
    ; Строчная буква
    sub al, 'a'
    sub al, [k_value]
    jns .no_wrap_lower
    add al, 26
.no_wrap_lower:
    add al, 'a'
decrypt_done:
    ret

print_error:
    mov rax, 1
    mov rdi, 2
    syscall
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
