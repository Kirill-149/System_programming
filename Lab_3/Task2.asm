format ELF64

section '.data' writeable
    usage db 'Usage: ./program a b c', 10, 0
    error_msg db 'Error: Division by zero or invalid number', 10, 0
    result_msg db 'Result: ', 0
    newline db 10, 0

section '.bss' writeable
    num_buffer rb 20
    a_val rq 1
    b_val rq 1
    c_val rq 1

section '.text' executable
public _start

_start:
    ; Проверяем количество аргументов
    pop rcx
    cmp rcx, 4
    jne .show_usage

    ; Пропускаем имя программы
    pop rdi

    ; Получаем параметр a
    pop rdi
    call parse_int
    mov [a_val], rax

    ; Получаем параметр b
    pop rdi
    call parse_int
    mov [b_val], rax

    ; Получаем параметр c
    pop rdi
    call parse_int
    mov [c_val], rax

    ; Проверяем, что b не равен 0
    mov rax, [b_val]
    test rax, rax
    jz .division_error

    ; Вычисляем выражение: (((b - c) / b) + a)
    mov rax, [b_val]    ; rax = b
    sub rax, [c_val]    ; rax = b - c

    ; Проверяем знак для корректного деления
    test rax, rax
    jns .positive
    neg rax             ; делаем положительным для деления
    mov rcx, 1          ; флаг отрицательного результата
    jmp .divide
.positive:
    mov rcx, 0          ; флаг положительного результата

.divide:
    xor rdx, rdx        ; обнуляем rdx для деления
    div qword [b_val]   ; rax = (b - c) / b, rdx = остаток

    ; Восстанавливаем знак если нужно
    test rcx, rcx
    jz .add_a
    neg rax

.add_a:
    ; Добавляем a: rax = ((b - c) / b) + a
    add rax, [a_val]

.print_result:
    ; Выводим сообщение "Result: "
    mov rsi, result_msg
    call print_str

    ; Преобразуем результат в строку и выводим
    call int_to_string
    mov rsi, rdi
    call print_str

    ; Новая строка
    mov rsi, newline
    call print_str

    ; Успешное завершение
    mov rdi, 0
    call exit

.show_usage:
    mov rsi, usage
    call print_str
    mov rdi, 1
    call exit

.division_error:
    mov rsi, error_msg
    call print_str
    mov rdi, 1
    call exit

; Преобразует строку в число
; Вход: RDI - строка
; Выход: RAX - число
parse_int:
    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx

    ; Проверяем знак
    mov bl, [rdi]
    cmp bl, '-'
    jne .parse_loop
    inc rdi             ; пропускаем минус
    mov rcx, 1          ; флаг отрицательного числа

.parse_loop:
    mov bl, [rdi]
    test bl, bl
    jz .finish

    ; Проверяем что символ цифра
    cmp bl, '0'
    jb .invalid
    cmp bl, '9'
    ja .invalid

    sub bl, '0'
    imul rax, 10
    add rax, rbx
    inc rdi
    jmp .parse_loop

.finish:
    test rcx, rcx
    jz .done
    neg rax
.done:
    ret

.invalid:
    mov rsi, error_msg
    call print_str
    mov rdi, 1
    call exit

; Преобразует число в RAX в строку
; Результат в RDI
int_to_string:
    mov rdi, num_buffer + 19
    mov byte [rdi], 0
    mov rbx, 10

    test rax, rax
    jns .convert_loop
    neg rax
    mov rcx, 1          ; флаг отрицательного
    jmp .convert_start

.convert_loop:
    mov rcx, 0          ; флаг положительного

.convert_start:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    test rax, rax
    jnz .convert_start

    ; Добавляем минус если нужно
    test rcx, rcx
    jz .done
    dec rdi
    mov byte [rdi], '-'

.done:
    ret

; Функция вычисления длины строки
; Вход: RDI - строка
; Выход: RAX - длина
strlen:
    mov rax, rdi
.loop:
    cmp byte [rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    sub rax, rdi
    ret

; Функция печати строки
; Вход: RSI - строка
print_str:
    push rax
    push rdi
    push rdx

    mov rdi, rsi
    call strlen
    mov rdx, rax

    mov rax, 1
    mov rdi, 1
    syscall

    pop rdx
    pop rdi
    pop rax
    ret

; Функция выхода
; Вход: RDI - код возврата
exit:
    mov rax, 60
    syscall
