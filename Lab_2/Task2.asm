format ELF64

public _start

section '.bss' writable
  buf rb 1

section '.text' executable
_start:
    mov rcx, 66
    mov rbx, 6
    mov rax, 0

    .loop:
        ; Проверяем, не достигли ли лимита перед выводом символа
        cmp rax, rcx
        jge .exit

        mov [buf], byte '+'
        push rax
        push rbx
        push rcx
        mov rax, 1
        mov rdi, 1
        mov rsi, buf
        mov rdx, 1
        syscall
        pop rcx
        pop rbx
        pop rax

        inc rax

        ; Проверяем, не достигли ли лимита перед выводом разделителя
        cmp rax, rcx
        jge .exit

        ; Проверяем конец строки
        push rax
        push rdx
        xor rdx, rdx
        div rbx         ; rdx = позиция в строке (0..M-1)
        cmp rdx, 0      ; если rdx == 0, значит мы только что вывели последний символ строки
        pop rdx
        pop rax

        jne .space

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
        jmp .loop

    .space:
        push rax
        push rbx
        push rcx
        mov [buf], byte ' '
        mov rax, 1
        mov rdi, 1
        mov rsi, buf
        mov rdx, 1
        syscall
        pop rcx
        pop rbx
        pop rax
        jmp .loop

    .exit:
        ; Перенос перед выходом
        mov [buf], byte 10
        mov rax, 1
        mov rdi, 1
        mov rsi, buf
        mov rdx, 1
        syscall

        mov rax, 60
        xor rdi, rdi
        syscall
