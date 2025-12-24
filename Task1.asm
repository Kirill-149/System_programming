format ELF64 executable 3
entry _start

segment readable writeable
    ; Константы
    SYS_EXIT    = 60
    SYS_FORK    = 57
    SYS_EXECVE  = 59
    SYS_WRITE   = 1
    SYS_READ    = 0
    SYS_WAITPID = 61

    STDIN       = 0
    STDOUT      = 1

    ; Сообщения
    prompt      db 'shell> ', 0
    prompt_len  = $-prompt

    newline     db 10
    error_msg   db 'Ошибка выполнения команды', 10, 0
    error_len   = $-error_msg

    ; Буферы
    cmd_buffer  rb 256        ; Буфер для команды
    args        rq 64         ; Массив аргументов (макс 64 аргумента)

segment readable executable

; Точка входа
_start:
    mov rbp, rsp

main_loop:
    ; Вывод приглашения
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [prompt]
    mov rdx, prompt_len
    syscall

    ; Чтение команды
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [cmd_buffer]
    mov rdx, 256
    syscall

    ; Проверка на EOF (Ctrl+D)
    cmp rax, 0
    jle exit_program

    ; Замена перевода строки на 0
    lea rdi, [cmd_buffer]
    add rdi, rax
    dec rdi
    cmp byte [rdi], 10
    jne .no_newline
    mov byte [rdi], 0

.no_newline:
    ; Проверка на пустую команду
    lea rsi, [cmd_buffer]
    cmp byte [rsi], 0
    je main_loop

    ; Проверка на команду выхода
    mov rdi, cmd_buffer
    call check_exit_command
    test rax, rax
    jnz exit_program

    ; Запуск команды
    call execute_command
    jmp main_loop

; Проверка команды выхода (exit или quit)
check_exit_command:
    ; Проверка "exit"
    lea rsi, [exit_str]
    call strcmp
    test rax, rax
    jz .exit_found

    ; Проверка "quit"
    lea rsi, [quit_str]
    call strcmp
    ret

.exit_found:
    mov rax, 1
    ret

exit_str db 'exit', 0
quit_str db 'quit', 0

; Сравнение строк
strcmp:
    mov al, [rdi]
    cmp al, [rsi]
    jne .not_equal
    test al, al
    jz .equal
    inc rdi
    inc rsi
    jmp strcmp

.equal:
    xor rax, rax
    ret

.not_equal:
    mov rax, 1
    ret

; Разбор команды на аргументы
parse_arguments:
    lea rsi, [cmd_buffer]
    lea rdi, [args]
    xor rcx, rcx            ; Счетчик аргументов

.skip_spaces:
    lodsb
    test al, al
    jz .done
    cmp al, ' '
    je .skip_spaces

    ; Нашли начало аргумента
    dec rsi
    mov [rdi], rsi
    add rdi, 8
    inc rcx

.find_end:
    lodsb
    test al, al
    jz .done
    cmp al, ' '
    jne .find_end

    ; Конец аргумента
    mov byte [rsi-1], 0
    jmp .skip_spaces

.done:
    mov qword [rdi], 0      ; NULL в конце массива
    mov rax, rcx            ; Возвращаем количество аргументов
    ret

; Выполнение команды
execute_command:
    ; Разбор аргументов
    call parse_arguments
    test rax, rax
    jz .invalid_command

    ; Сохранение количества аргументов
    push rax

    ; Создание дочернего процесса
    mov rax, SYS_FORK
    syscall

    test rax, rax
    jz .child_process       ; В дочернем процессе

    ; Родительский процесс
    pop rbx                 ; Восстановление количества аргументов

    ; Ожидание завершения дочернего процесса
    push rax                ; Сохраняем PID
    mov rdi, rax            ; PID
    xor rsi, rsi            ; status
    xor rdx, rdx            ; options
    mov r10, 0              ; rusage
    mov rax, SYS_WAITPID
    syscall

    pop rdi                 ; Восстанавливаем PID
    ret

.child_process:
    ; В дочернем процессе
    pop rbx                 ; Восстановление количества аргументов

    ; Подготовка аргументов для execve
    lea rdi, [args]
    mov rsi, [rdi]          ; Путь к исполняемому файлу
    lea rdx, [args]         ; Массив аргументов
    xor rcx, rcx            ; Окружение (NULL)

    ; Вызов execve
    mov rax, SYS_EXECVE
    syscall

    ; Если execve вернул ошибку
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [error_msg]
    mov rdx, error_len
    syscall

    ; Завершение дочернего процесса
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

.invalid_command:
    ret

; Завершение программы
exit_program:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
