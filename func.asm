;; func.asm - общие функции

; Макрос для удобства
macro syscall1 number {
    mov rax, number
    syscall
}

macro syscall2 number, arg1 {
    mov rdi, arg1
    mov rax, number
    syscall
}

macro syscall3 number, arg1, arg2 {
    mov rdi, arg1
    mov rsi, arg2
    mov rax, number
    syscall
}

macro syscall4 number, arg1, arg2, arg3 {
    mov rdi, arg1
    mov rsi, arg2
    mov rdx, arg3
    mov rax, number
    syscall
}

; Вывод строки
print_str:
    push rcx
    push rdx
    push rdi
    push rax

    xor rcx, rcx
.find_end:
    cmp byte [rsi + rcx], 0
    je .found_end
    inc rcx
    jmp .find_end
.found_end:

    syscall4 1, 1, rsi, rcx

    pop rax
    pop rdi
    pop rdx
    pop rcx
    ret

; Вывод новой строки
new_line:
    push rsi
    mov rsi, newline_str
    call print_str
    pop rsi
    ret

; Ввод с клавиатуры
input_keyboard:
    ; rsi = буфер, rdx = размер
    syscall4 0, 0, rsi, rdx
    ; Заменяем \n на 0
    mov byte [rsi + rax - 1], 0
    ret

; Выход
exit:
    syscall2 60, 0
    ret

; Данные для функций
newline_str db 0xA, 0
