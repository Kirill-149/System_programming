format elf64
public _start

section '.data' writable
    consonants db "BCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz", 0
    usage_msg db "Usage: ./program <input_file> <output_file>", 10
    usage_len = $ - usage_msg
    error_open db "Error opening file", 10
    error_open_len = $ - error_open
    error_read db "Error reading file", 10
    error_read_len = $ - error_read
    error_write db "Error writing file", 10
    error_write_len = $ - error_write

section '.bss' writable
    input_fd dq 0
    output_fd dq 0
    buffer rb 1
    out_buf rb 2

section '.text' executable

_start:
    pop rcx
    cmp rcx, 3
    jne usage_error

    pop rsi
    pop rsi
    mov rdi, rsi
    call open_input

    pop rsi
    mov rdi, rsi
    call open_output

read_loop:
    call read_char
    test rax, rax
    jz close_files

    mov al, [buffer]
    call is_consonant
    test rax, rax
    jz write_single

    mov al, [buffer]
    mov [out_buf], al
    mov [out_buf+1], al
    mov rsi, out_buf
    mov rdx, 2
    jmp write_chars

write_single:
    mov al, [buffer]
    mov [out_buf], al
    mov rsi, out_buf
    mov rdx, 1

write_chars:
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

is_consonant:
    push rsi
    push rcx
    mov rsi, consonants
    mov rcx, 42
check_consonant:
    cmp al, [rsi]
    je found_consonant
    inc rsi
    dec rcx
    jnz check_consonant
    xor rax, rax
    jmp consonant_done
found_consonant:
    mov rax, 1
consonant_done:
    pop rcx
    pop rsi
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
