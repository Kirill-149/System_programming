format elf64
public _start

section '.data' writable
    usage_msg db "Usage: ./common_chars file1 file2 output", 10
    usage_len = $ - usage_msg
    error_open db "Error opening file", 10
    error_open_len = $ - error_open
    error_read db "Error reading file", 10
    error_read_len = $ - error_read
    error_write db "Error writing file", 10
    error_write_len = $ - error_write

section '.bss' writable
    file1_fd dq 0
    file2_fd dq 0
    output_fd dq 0
    buffer rb 1
    charset1 rb 256
    charset2 rb 256
    result rb 256

section '.text' executable

_start:
    ; Проверяем количество аргументов
    mov rcx, [rsp]      ; argc
    cmp rcx, 4
    jne .usage

    ; Получаем аргументы
    mov rsi, [rsp + 16] ; argv[1]
    call .open_file1

    mov rsi, [rsp + 24] ; argv[2]
    call .open_file2

    mov rsi, [rsp + 32] ; argv[3]
    call .open_output

    ; Обрабатываем файлы
    call .process

    ; Закрываем файлы и выходим
    jmp .exit_ok

.usage:
    mov rsi, usage_msg
    mov rdx, usage_len
    call .print_error
    mov rdi, 1
    jmp .exit

.open_file1:
    mov rax, 2          ; sys_open
    mov rdi, rsi        ; filename
    mov rsi, 0          ; O_RDONLY
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .error_open
    mov [file1_fd], rax
    ret

.open_file2:
    mov rax, 2          ; sys_open
    mov rdi, rsi        ; filename
    mov rsi, 0          ; O_RDONLY
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .error_open
    mov [file2_fd], rax
    ret

.open_output:
    mov rax, 2          ; sys_open
    mov rdi, rsi        ; filename
    mov rsi, 0x42       ; O_CREAT | O_WRONLY
    mov rdx, 0644o      ; permissions
    syscall
    cmp rax, 0
    jl .error_open
    mov [output_fd], rax
    ret

.error_open:
    mov rsi, error_open
    mov rdx, error_open_len
    call .print_error
    mov rdi, 1
    jmp .exit

.process:
    ; Инициализируем массивы нулями
    mov rdi, charset1
    mov rcx, 256
    xor al, al
    rep stosb

    mov rdi, charset2
    mov rcx, 256
    xor al, al
    rep stosb

    mov rdi, result
    mov rcx, 256
    xor al, al
    rep stosb

    ; Читаем первый файл
    call .read_file1
    ; Читаем второй файл
    call .read_file2
    ; Находим общие символы
    call .find_common
    ; Записываем результат
    call .write_result
    ret

.read_file1:
    mov rdi, [file1_fd]
.read_loop1:
    mov rax, 0          ; sys_read
    mov rsi, buffer
    mov rdx, 1
    syscall
    cmp rax, 0
    jl .error_read
    jz .done1
    mov al, [buffer]
    movzx rbx, al
    mov byte [charset1 + rbx], 1
    jmp .read_loop1
.done1:
    ret

.read_file2:
    mov rdi, [file2_fd]
.read_loop2:
    mov rax, 0          ; sys_read
    mov rsi, buffer
    mov rdx, 1
    syscall
    cmp rax, 0
    jl .error_read
    jz .done2
    mov al, [buffer]
    movzx rbx, al
    mov byte [charset2 + rbx], 1
    jmp .read_loop2
.done2:
    ret

.error_read:
    mov rsi, error_read
    mov rdx, error_read_len
    call .print_error
    mov rdi, 1
    jmp .exit

.find_common:
    mov rcx, 0
.loop_find:
    cmp rcx, 256
    je .done_find
    mov al, [charset1 + rcx]
    test al, al
    jz .next_find
    mov al, [charset2 + rcx]
    test al, al
    jz .next_find
    mov byte [result + rcx], 1
.next_find:
    inc rcx
    jmp .loop_find
.done_find:
    ret

.write_result:
    mov rcx, 0
.loop_write:
    cmp rcx, 256
    je .done_write
    cmp byte [result + rcx], 0
    je .next_write
    mov [buffer], cl
    mov rax, 1          ; sys_write
    mov rdi, [output_fd]
    mov rsi, buffer
    mov rdx, 1
    syscall
    cmp rax, 0
    jl .error_write
.next_write:
    inc rcx
    jmp .loop_write
.done_write:
    ret

.error_write:
    mov rsi, error_write
    mov rdx, error_write_len
    call .print_error
    mov rdi, 1
    jmp .exit

.print_error:
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    syscall
    ret

.exit_ok:
    ; Закрываем файлы
    mov rax, 3
    mov rdi, [file1_fd]
    syscall
    mov rax, 3
    mov rdi, [file2_fd]
    syscall
    mov rax, 3
    mov rdi, [output_fd]
    syscall
    xor rdi, rdi

.exit:
    mov rax, 60         ; sys_exit
    syscall
