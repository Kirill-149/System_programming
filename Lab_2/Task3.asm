format ELF64

public _start

section '.bss' writable
  buf rb 1

section '.text' executable
_start:
    mov rcx, 66
    mov rbx, 1
    mov rax, 0

    .loop:
        cmp rax, rcx
        jge .exit

        mov rdx, 0

        .row_loop:
            cmp rdx, rbx
            jge .end_row

            mov [buf], byte '+'
            push rax
            push rbx
            push rcx
            push rdx
            mov rax, 1
            mov rdi, 1
            mov rsi, buf
            mov rdx, 1
            syscall
            pop rdx
            pop rcx
            pop rbx
            pop rax

            inc rax
            cmp rax, rcx
            jge .exit

            inc rdx
            jmp .row_loop

        .end_row:
        push rax
        push rbx
        push rcx
        mov [buf], byte 10
        mov rax, 1
        mov rdi, 1
        mov rsi, buf
        mov rdx, 1
        syscall
        pop rcx
        pop rbx
        pop rax

        inc rbx
        jmp .loop

    .exit:
        mov [buf], byte 10
        mov rax, 1
        mov rdi, 1
        mov rsi, buf
        mov rdx, 1
        syscall

        mov rax, 60
        xor rdi, rdi
        syscall
