format ELF64

section '.bss' writeable
    num_buffer rb 12   ; буфер для преобразования чисел

section '.data' writeable
    usage db 'Usage: ./program <character>',10,0
    output db 'ASCII code: ',0
    newline db 10,0

section '.text' executable
public _start

_start:
    ; Проверяем количество аргументов
    pop rcx             ; argc
    cmp rcx, 2
    jne .show_usage

    ; Получаем символ из аргумента
    pop rdi             ; argv[0] - имя программы
    pop rsi             ; argv[1] - наш символ

    ; Проверяем длину аргумента
    mov rdi, rsi
    call strlen
    cmp rax, 1
    jne .show_usage

    ; Получаем ASCII код
    mov rsi, rdi        ; восстанавливаем указатель
    movzx rax, byte [rsi] ; получаем ASCII код

    ; Преобразуем число в строку и выводим
    call .print_output

    ; Успешное завершение
    mov rdi, 0          ; код возврата 0
    call exit

.show_usage:
    mov rsi, usage
    call print_str
    mov rdi, 1          ; код возврата 1 (ошибка)
    call exit

.print_output:
    push rax
    ; Выводим "ASCII code: "
    mov rsi, output
    call print_str

    ; Преобразуем ASCII код в строку и выводим
    pop rax
    call .number_to_string
    mov rsi, rdi
    call print_str

    ; Новая строка
    mov rsi, newline
    call print_str
    ret

; Преобразует число в RAX в строку
; Результат в RDI (должен быть буфер)
.number_to_string:
    mov rdi, num_buffer + 11  ; буфер из 12 байт
    mov byte [rdi], 0         ; нулевой терминатор
    mov rbx, 10               ; основание системы

.convert_loop:
    dec rdi
    xor rdx, rdx
    div rbx                   ; rax = quotient, rdx = remainder
    add dl, '0'
    mov [rdi], dl
    test rax, rax
    jnz .convert_loop

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
    call strlen        ; получаем длину строки
    mov rdx, rax       ; длина в RDX

    mov rax, 1         ; sys_write
    mov rdi, 1         ; stdout
    syscall

    pop rdx
    pop rdi
    pop rax
    ret

; Функция выхода
; Вход: RDI - код возврата
exit:
    mov rax, 60        ; sys_exit
    syscall
