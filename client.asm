format ELF64
public _start

SYS_READ        = 0
SYS_WRITE       = 1
SYS_CLOSE       = 3
SYS_SOCKET      = 41
SYS_CONNECT     = 42
SYS_EXIT        = 60
AF_INET         = 2
SOCK_STREAM     = 1

section '.data' writeable
    notify_connect  db 'Initiating duel...', 10, 0
    error_socket    db 'Socket creation failed!', 10, 0
    error_connect   db 'Connection failed! Make sure server is running.', 10, 0

    target_address:
        dw AF_INET
        db 0x15, 0xB3      ; Порт 5555 (0xB315 в сетевом порядке байт)
        db 127,0,0,1       ; IP-адрес localhost
        dq 0

    comm_socket     dq 0
    server_reply    rb 512
    player_action   db 0

section '.text' executable
_start:
    mov rsi, notify_connect
    call show_text

    ; Создаем сокет
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    syscall
    cmp rax, 0
    jl socket_error
    mov [comm_socket], rax

    ; Подключаемся к серверу
    mov rax, SYS_CONNECT
    mov rdi, [comm_socket]
    mov rsi, target_address
    mov rdx, 16
    syscall
    cmp rax, 0
    jl connect_error
    jmp match_loop

socket_error:
    mov rsi, error_socket
    call show_text
    jmp exit_program

connect_error:
    mov rsi, error_connect
    call show_text
    mov rax, SYS_CLOSE
    mov rdi, [comm_socket]
    syscall
    jmp exit_program

match_loop:
    ; Читаем ответ от сервера
    mov byte [server_reply], 0
    mov rax, SYS_READ
    mov rdi, [comm_socket]
    mov rsi, server_reply
    mov rdx, 511
    syscall

    cmp rax, 0
    jle disconnect

    ; Выводим ответ сервера
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall

    ; Проверяем, не закончилась ли игра
    mov rsi, server_reply
    call check_game_over
    cmp rax, 1
    je disconnect

    ; Читаем выбор игрока
    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, player_action
    mov rdx, 2
    syscall

    ; Отправляем выбор серверу
    mov rax, SYS_WRITE
    mov rdi, [comm_socket]
    mov rsi, player_action
    mov rdx, 1
    syscall

    jmp match_loop

check_game_over:
    ; Проверяем, содержит ли сообщение слова конца игры
    mov rcx, 0
.check_loop:
    mov al, [rsi + rcx]
    cmp al, 0
    je .not_over

    ; Проверяем на "OVER", "WINNER", "LOST", "DRAW"
    cmp al, 'O'
    je .check_over
    cmp al, 'W'
    je .check_winner
    cmp al, 'L'
    je .check_lost
    cmp al, 'D'
    je .check_draw
    jmp .continue

.check_over:
    cmp byte [rsi + rcx + 1], 'V'
    je .is_over
    jmp .continue
.check_winner:
    cmp byte [rsi + rcx + 1], 'I'
    je .is_over
    jmp .continue
.check_lost:
    cmp byte [rsi + rcx + 1], 'O'
    je .is_over
    jmp .continue
.check_draw:
    cmp byte [rsi + rcx + 1], 'R'
    je .is_over
    jmp .continue

.continue:
    inc rcx
    jmp .check_loop

.is_over:
    mov rax, 1
    ret
.not_over:
    mov rax, 0
    ret

disconnect:
    mov rax, SYS_CLOSE
    mov rdi, [comm_socket]
    syscall

exit_program:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

show_text:
    push rdi
    push rax
    push rdx
    push rcx
    mov rdi, rsi
    call text_length
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    pop rcx
    pop rdx
    pop rax
    pop rdi
    ret

text_length:
    xor rax, rax
.loop_check:
    cmp byte [rdi + rax], 0
    je .length_ready
    inc rax
    jmp .loop_check
.length_ready:
    ret
