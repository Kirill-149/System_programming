format ELF64

public _start

section '.data' writable
    number dq 5277616985

section '.bss' writable
    buf rb 16
    sum dq 0

section '.text' executable
_start:
    mov rax, [number]
    mov rbx, 10
    mov qword [sum], 0

    .sum_loop:
        xor rdx, rdx
        div rbx
        add [sum], rdx
        test rax, rax
        jnz .sum_loop

    mov rax, [sum]
    mov rbx, 10
    mov rdi, buf + 15
    mov byte [rdi], 10
    dec rdi

    .convert_loop:
        xor rdx, rdx
        div rbx
        add dl, '0'
        mov [rdi], dl
        dec rdi
        test rax, rax
        jnz .convert_loop

    inc rdi
    mov rsi, rdi
    mov rdx, buf + 16
    sub rdx, rsi

    mov rax, 1
    mov rdi, 1
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall
