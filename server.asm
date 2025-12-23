; server.asm - сервер морского боя
format ELF64
public _start

; Константы
AF_INET = 2
SOCK_STREAM = 1
SOL_SOCKET = 1
SO_REUSEADDR = 2
INADDR_ANY = 0
PORT_NET = 0x3d9  ; 5555 в сетевом порядке

; Системные вызовы
SYS_SOCKET = 41
SYS_BIND = 49
SYS_LISTEN = 50
SYS_ACCEPT = 43
SYS_CLOSE = 3
SYS_READ = 0
SYS_WRITE = 1
SYS_EXIT = 60
SYS_SETSOCKOPT = 54

section '.data' writeable
    msg_start       db 'Сервер запущен. Порт: 5555',0xA,0
    msg_wait        db 'Ожидание игрока...',0xA,0
    msg_connect     db 'Игрок подключился! Ход сервера.',0xA,0
    msg_turn        db 'Ваш ход (A1-J10): ',0
    msg_hit         db 'Попадание!',0xA,0
    msg_miss        db 'Промах!',0xA,0
    msg_error       db 'Ошибка привязки сокета',0xA,0
    msg_listen      db 'Ошибка прослушивания',0xA,0
    msg_accept      db 'Ошибка принятия соединения',0xA,0
    msg_wait_opp    db 'Ожидание хода противника...',0xA,0
    msg_opp_move    db 'Противник сделал ход: ',0
    msg_client_quit db 'Клиент отключился',0xA,0
    msg_quit        db 'Завершение работы сервера',0xA,0
    msg_you_win     db 'Вы выиграли!',0xA,0
    msg_you_lose    db 'Вы проиграли!',0xA,0
    msg_game_over   db 'Игра завершена',0xA,0
    newline         db 0xA,0

    sock_fd   dq 0
    client_fd dq 0
    buffer    rb 100
    optval    dd 1

    ; Структура sockaddr_in
    srv_addr:
        .sin_family dw AF_INET
        .sin_port   dw PORT_NET
        .sin_addr   dd INADDR_ANY
        .sin_zero   dq 0

    client_addr rb 16
    addrlen     dd 16

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

; Точка входа
_start:
    ; Вывод сообщения о запуске
    mov rsi, msg_start
    call print_str

    ; Создание сокета
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    mov rax, SYS_SOCKET
    syscall

    cmp rax, 0
    jl .bind_error
    mov [sock_fd], rax

    ; Установка SO_REUSEADDR для повторного использования порта
    mov rdi, [sock_fd]
    mov rsi, SOL_SOCKET
    mov rdx, SO_REUSEADDR
    mov r10, optval
    mov r8, 4
    mov rax, SYS_SETSOCKOPT
    syscall

    ; Привязка сокета
    mov rdi, [sock_fd]
    mov rsi, srv_addr
    mov rdx, 16
    mov rax, SYS_BIND
    syscall

    cmp rax, 0
    jl .bind_error

    ; Прослушивание
    mov rdi, [sock_fd]
    mov rsi, 5
    mov rax, SYS_LISTEN
    syscall

    cmp rax, 0
    jl .listen_error

    ; Основной цикл ожидания подключений
.main_loop:
    mov rsi, msg_wait
    call print_str

    ; Принятие подключения
    mov rdi, [sock_fd]
    mov rsi, client_addr
    mov rdx, addrlen
    mov rax, SYS_ACCEPT
    syscall

    cmp rax, 0
    jl .accept_error
    mov [client_fd], rax

    mov rsi, msg_connect
    call print_str

    ; Игровой цикл
    call play_game

    ; Закрытие клиентского сокета
    mov rdi, [client_fd]
    cmp rdi, 0
    je .clear_client_fd
    mov rax, SYS_CLOSE
    syscall

.clear_client_fd:
    mov qword [client_fd], 0
    jmp .main_loop

.bind_error:
    mov rsi, msg_error
    call print_str
    call exit

.listen_error:
    mov rsi, msg_listen
    call print_str
    call exit

.accept_error:
    mov rsi, msg_accept
    call print_str
    jmp .main_loop

; Игровой процесс
play_game:
    push rbp
    mov rbp, rsp

    ; Сервер начинает первым
    mov rsi, msg_connect
    call print_str

.server_move:
    ; Ход сервера
    mov rsi, msg_turn
    call print_str

    ; Чтение ввода сервера
    mov rsi, buffer
    call input_keyboard

    ; Проверка на выход
    cmp byte [buffer], 'q'
    je .server_quit

    ; Проверка формата ввода
    cmp byte [buffer + 1], 0
    je .server_move

    ; Отправка хода клиенту
    mov rdi, [client_fd]
    mov rsi, buffer
    mov rdx, 3
    mov rax, SYS_WRITE
    syscall

    ; Получение результата от клиента
    mov rdi, [client_fd]
    mov rsi, buffer
    mov rdx, 2
    mov rax, SYS_READ
    syscall

    cmp rax, 0
    jle .client_disconnected

    ; Вывод результата своего хода
    cmp byte [buffer], 'H'
    je .server_hit
    cmp byte [buffer], 'M'
    je .server_miss

.server_hit:
    mov rsi, msg_hit
    call print_str
    jmp .wait_client_move

.server_miss:
    mov rsi, msg_miss
    call print_str

.wait_client_move:
    ; Ожидание хода клиента
    mov rsi, msg_wait_opp
    call print_str

    ; Получение хода от клиента
    mov rdi, [client_fd]
    mov rsi, buffer
    mov rdx, 3
    mov rax, SYS_READ
    syscall

    cmp rax, 0
    jle .client_disconnected

    cmp byte [buffer], 'q'
    je .client_quit

    ; Вывод хода клиента
    mov rsi, msg_opp_move
    call print_str
    mov rsi, buffer
    call print_str
    mov rsi, newline
    call print_str

    ; Отправка результата клиенту
    mov rsi, buffer
    mov byte [rsi], 'M'
    mov byte [rsi + 1], 0
    mov rdi, [client_fd]
    mov rdx, 2
    mov rax, SYS_WRITE
    syscall

    ; Возврат к ходу сервера
    jmp .server_move

.server_quit:
    ; Сервер завершает работу
    mov rsi, msg_quit
    call print_str
    jmp .game_end

.client_quit:
    ; Клиент хочет выйти из игры
    mov rsi, msg_client_quit
    call print_str
    jmp .game_end

.client_disconnected:
    ; Клиент неожиданно отключился
    mov rsi, msg_client_quit
    call print_str

.game_end:
    ; Закрытие клиентского соединения
    mov rdi, [client_fd]
    cmp rdi, 0
    je .done
    mov rax, SYS_CLOSE
    syscall
    mov qword [client_fd], 0

.done:
    mov rsp, rbp
    pop rbp
    ret
