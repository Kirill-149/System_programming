format ELF64
public _start

section '.data' writeable
    prompt db "Введите команду (например, ./lab5): ", 0
    prompt_len = $ - prompt

    error_msg db "Ошибка: не удалось запустить программу", 10, 0
    error_len = $ - error_msg

    input_buffer rb 256

    ; argv[0] - имя файла, argv[1] - NULL
    argv dq 0, 0

    ; Сюда сохраним настоящий указатель на окружение
    envp_addr dq 0

    status dd 0

section '.text' executable
_start:
    ; Получаем указатель на переменные окружения со стека.
    ; Структура стека при старте: [argc] [argv0] ... [argvN] [NULL] [envp0] ...

    pop rcx                 ; RCX = argc. Теперь RSP указывает на argv[0]

    ; Нам нужно перепрыгнуть через весь массив argv, чтобы найти envp.
    ; Размер argv = (argc * 8) байт + 8 байт (завершающий NULL).
    ; Адрес envp = RSP + (RCX * 8) + 8

    lea rdi, [rsp + rcx*8 + 8]
    mov [envp_addr], rdi    ; Сохраняем найденный адрес массива окружения

main_loop:
    ; Вывод приглашения
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    lea rsi, [prompt]
    mov rdx, prompt_len
    syscall

    ; Чтение ввода
    mov rax, 0              ; sys_read`
    mov rdi, 0              ; stdin
    lea rsi, [input_buffer]
    mov rdx, 255
    syscall

    ; Если нажали только Enter (1 байт), повторить
    cmp rax, 1
    jle main_loop

    ; Замена \n на 0
    mov byte [input_buffer + rax - 1], 0

    ; Fork
    mov rax, 57             ; sys_fork
    syscall

    test rax, rax
    js fork_error       ; если rax < 0
    jz child_process    ; если rax == 0

    ; Родитель
    jmp parent_process

child_process:
    ; Подготовка аргументов
    lea rbx, [input_buffer]
    mov [argv], rbx         ; argv[0] = имя файла

    mov rax, 59             ; sys_execve
    lea rdi, [input_buffer] ; filename
    lea rsi, [argv]         ; argv

    ; Мы берем значение, которое сохранили в envp_addr
    mov rdx, [envp_addr]    ; envp (передаем системное окружение: TERM, PATH и т.д.)
    syscall

    ; Обработка ошибки execve
    mov rax, 1
    mov rdi, 1
    lea rsi, [error_msg]
    mov rdx, error_len
    syscall

    mov rax, 60             ; sys_exit
    mov rdi, 1
    syscall

parent_process:
    ; Ожидание
    mov rdi, rax            ; PID
    mov rax, 61             ; sys_wait4
    lea rsi, [status]
    mov rdx, 0
    mov r10, 0
    syscall

    ; Возвращаемся в начало цикла
    jmp main_loop

fork_error:
    jmp main_loop           ; При ошибке fork тоже лучше вернуться в цикл
