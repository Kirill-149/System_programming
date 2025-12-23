format ELF64
public _start

; Константы
AF_INET = 2
SOCK_STREAM = 1
SERVER_IP = 0x0100007F  ; 127.0.0.1
PORT_NET = 0x3d9        ; 5555 в сетевом порядке

; Системные вызовы
SYS_SOCKET = 41
SYS_CONNECT = 42
SYS_CLOSE = 3
SYS_READ = 0
SYS_WRITE = 1
SYS_EXIT = 60

section '.data' writeable
    msg_connecting    db 'Подключение к серверу localhost:5555...',0xA,0
    msg_connected     db 'Подключено! Ход сервера. Ждите...',0xA,0
    msg_error         db 'Ошибка подключения',0xA,0
    msg_turn          db 'Ваш ход: ',0
    msg_waiting       db 'Ожидание хода сервера...',0xA,0
    msg_hit           db 'Попадание!',0xA,0
    msg_miss          db 'Промах!',0xA,0
    msg_server_down   db 'Сервер отключился',0xA,0
    msg_server_move   db 'Сервер сделал ход: ',0
    msg_your_result   db 'Результат вашего хода: ',0
    msg_game_over     db 'Игра завершена',0xA,0
    msg_you_win       db 'Вы выиграли!',0xA,0
    msg_you_lose      db 'Вы проиграли!',0xA,0
    newline           db 0xA,0

    socket_fd dq 0
    buffer    rb 100

    ; Адрес сервера
    server_addr:
        .sin_family dw AF_INET
        .sin_port   dw PORT_NET
        .sin_addr   dd SERVER_IP
        .sin_zero   dq 0

section '.text' executable

; Функция вывода строки
print_str:
    ; rsi = указатель на строку
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

    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rdx, rcx        ; длина
    syscall

    pop rax
    pop rdi
    pop rdx
    pop rcx
    ret

; Ввод с клавиатуры
input_keyboard:
    ; rsi = буфер
    push rdx
    push rdi

    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rdx, 100        ; размер
    syscall

    ; Заменяем \n на 0
    cmp rax, 0
    jle .no_input
    mov byte [rsi + rax - 1], 0

.no_input:
    pop rdi
    pop rdx
    ret

; Выход из программы
exit:
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; код 0
    syscall

_start:
    ; Сообщение о подключении
    mov rsi, msg_connecting
    call print_str

    ; Создание сокета
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    mov rax, SYS_SOCKET
    syscall

    cmp rax, 0
    jl .error_exit
    mov [socket_fd], rax

    ; Подключение к серверу
    mov rdi, [socket_fd]
    mov rsi, server_addr
    mov rdx, 16
    mov rax, SYS_CONNECT
    syscall

    cmp rax, 0
    jl .connect_error

    mov rsi, msg_connected
    call print_str

    ; Игровой цикл
    call play_game

    ; Закрытие сокета
    mov rdi, [socket_fd]
    mov rax, SYS_CLOSE
    syscall

    call exit

.connect_error:
    mov rsi, msg_error
    call print_str
    jmp .error_exit

.error_exit:
    mov rdi, [socket_fd]
    test rdi, rdi
    jz .exit
    mov rax, SYS_CLOSE
    syscall
.exit:
    call exit

; Игровой процесс
play_game:
.game_loop:
    ; 1. Ожидание хода сервера
    mov rsi, msg_waiting
    call print_str

    ; Получение хода от сервера
    mov rdi, [socket_fd]
    mov rsi, buffer
    mov rdx, 3
    mov rax, SYS_READ
    syscall

    cmp rax, 0
    jle .server_disconnected

    ; Вывод хода сервера
    mov rsi, msg_server_move
    call print_str
    mov rsi, buffer
    call print_str
    mov rsi, newline
    call print_str

    ; 2. Отправка результата по ходу сервера
    mov rsi, buffer
    mov byte [rsi], 'M'
    mov byte [rsi + 1], 0
    mov rdi, [socket_fd]
    mov rdx, 2
    mov rax, SYS_WRITE
    syscall

    ; 3. Ход клиента
    mov rsi, msg_turn
    call print_str

    ; Чтение ввода клиента
    mov rsi, buffer
    call input_keyboard

    cmp byte [buffer], 'q'
    je .client_quit

    ; Проверка формата ввода
    cmp byte [buffer + 1], 0
    je .client_turn

    ; 4. Отправка хода серверу
    mov rdi, [socket_fd]
    mov rsi, buffer
    mov rdx, 3
    mov rax, SYS_WRITE
    syscall

    ; 5. Получение результата своего хода
    mov rdi, [socket_fd]
    mov rsi, buffer
    mov rdx, 2
    mov rax, SYS_READ
    syscall

    cmp rax, 0
    jle .server_disconnected

    ; Вывод результата
    mov rsi, msg_your_result
    call print_str

    cmp byte [buffer], 'H'
    je .hit
    cmp byte [buffer], 'M'
    je .miss

    ; Возврат к ожиданию хода сервера
    jmp .game_loop

.client_turn:
    ; Повторный запрос хода при неверном формате
    jmp .game_loop

.hit:
    mov rsi, msg_hit
    call print_str
    jmp .game_loop

.miss:
    mov rsi, msg_miss
    call print_str
    jmp .game_loop

.client_quit:
    ; Отправляем серверу команду выхода
    mov rdi, [socket_fd]
    mov rsi, buffer
    mov rdx, 3
    mov rax, SYS_WRITE
    syscall

    mov rsi, msg_game_over
    call print_str
    ret

.server_disconnected:
    mov rsi, msg_server_down
    call print_str
    ret
