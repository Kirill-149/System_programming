format ELF64
public _start

; --- Константы ---
SYS_READ    = 0
SYS_WRITE   = 1
SYS_MMAP    = 9
SYS_MUNMAP  = 11
SYS_FORK    = 57
SYS_EXIT    = 60
SYS_WAIT4   = 61
SYS_NANOSLEEP = 35

STDOUT      = 1
PROT_READ   = 0x1
PROT_WRITE  = 0x2
MAP_SHARED  = 0x01
MAP_ANONY   = 0x20

COUNT       = 637
ARRAY_SIZE  = 4 + (COUNT * 4)

section '.data' writeable
    msg_start       db "Массив заполнен случайными числами.", 10, 0
    msg_start_len   = $ - msg_start

    msg_task0:
        db "[Процесс 1] Самая редкая цифра: ", 0
    msg_task0_end:
    len_0 equ msg_task0_end - msg_task0

    msg_task1:
        db "[Процесс 2] Среднее арифметическое: ", 0
    msg_task1_end:
    len_1 equ msg_task1_end - msg_task1

    msg_task2:
    db "[Процесс 3] Самая частая цифра: ", 0
    msg_task2_end:
    len_2 equ msg_task2_end - msg_task2

    msg_task3:
    db "[Процесс 4] Третье число после максимального: ", 0
    msg_task3_end:
    len_3 equ msg_task3_end - msg_task3

    newline         db 10, 0

    array_ptr       dq 0
    data_ptr        dq 0
    seed            dd 743

    num_buffer      rb 20

    timespec:
        dq 0
        dq 1000000  ; 1 ms

section '.text' executable
_start:
    ; 1. Память
    mov rax, SYS_MMAP
    mov rdi, 0
    mov rsi, ARRAY_SIZE
    mov rdx, PROT_READ or PROT_WRITE
    mov r10, MAP_SHARED or MAP_ANONY
    mov r8, -1
    mov r9, 0
    syscall

    cmp rax, 0
    jl exit_error
    mov [array_ptr], rax

    mov dword [rax], 0      ; Обнуляем очередь
    lea rbx, [rax + 4]
    mov [data_ptr], rbx     ; Указатель на данные

    ; 2. Заполнение
    mov rdi, [data_ptr]
    mov rcx, COUNT
    fill_loop:
        call rand
        mov [rdi], eax
        add rdi, 4
        loop fill_loop

        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_start]
        mov rdx, msg_start_len
        syscall

        ; 3. Форки
        mov r15, 0
    fork_loop:
        cmp r15, 4
        je wait_children

        mov rax, SYS_FORK
        syscall

        test rax, rax
        js exit_error
        jz child_process

        inc r15
        jmp fork_loop

    ; ---------------------------------------------------------
    child_process:
        cmp r15, 0
        je task_rare_digit
        cmp r15, 1
        je task_mean
        cmp r15, 2
        je task_freq_digit
        cmp r15, 3
        je task_third_max
        jmp child_exit

    ; --- ЗАДАЧА 0 ---
    task_rare_digit:
        sub rsp, 80             ; ВЫДЕЛЯЕМ ПАМЯТЬ ЗДЕСЬ
        mov rdi, rsp            ; Передаем адрес буфера в функцию
        call count_digits

        mov rcx, 0
        mov rbx, -1
        shr rbx, 1              ; Max Int
        mov rdx, -1
    .find_min:
        cmp rcx, 10
        je .print
        mov rax, [rsp + rcx*8]
        cmp rax, rbx
        jae .next
        mov rbx, rax
        mov rdx, rcx
    .next:
        inc rcx
        jmp .find_min
    .print:
        mov r14, rdx
        add rsp, 80             ; ОСВ ПАМ

        call wait_my_turn

        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_task0]
        mov rdx, len_0
        syscall
        mov rax, r14
        call print_num
        call print_newline

        call pass_turn
        jmp child_exit

    ; --- ЗАДАЧА 2 ---
    task_freq_digit:
        sub rsp, 80             ; ВЫД ПАМ
        mov rdi, rsp
        call count_digits

        mov rcx, 0
        mov rbx, 0
        mov rdx, -1
    .find_max:
        cmp rcx, 10
        je .print
        mov rax, [rsp + rcx*8]
        cmp rax, rbx
        jle .next
        mov rbx, rax
        mov rdx, rcx
    .next:
        inc rcx
        jmp .find_max
    .print:
        mov r14, rdx
        add rsp, 80             ; ОСВОБОЖДАЕМ

        call wait_my_turn

        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_task2]
        mov rdx, len_2
        syscall
        mov rax, r14
        call print_num
        call print_newline

        call pass_turn
        jmp child_exit

    ; --- ЗАДАЧА 1 ---
    task_mean:
        mov rsi, [data_ptr]
        mov rcx, COUNT
        xor rbx, rbx
    .sum:
        xor rax, rax
        mov eax, [rsi]
        add rbx, rax
        add rsi, 4
        loop .sum

        mov rax, rbx
        xor rdx, rdx
        mov rbx, COUNT
        div rbx

        mov rcx, rbx
        shr rcx, 1
        cmp rdx, rcx
        jl .done
        inc rax
    .done:
        mov r14, rax

        call wait_my_turn
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_task1]
        mov rdx, len_1
        syscall
        mov rax, r14
        call print_num
        call print_newline
        call pass_turn
        jmp child_exit

    ; --- ЗАДАЧА 3 ---
    task_third_max:
        xor r8, r8
        xor r9, r9
        xor r10, r10
        mov rsi, [data_ptr]
        mov rcx, COUNT
    .scan:
        xor rax, rax
        mov eax, [rsi]
        cmp rax, r8
        jle .c2
        mov r10, r9
        mov r9, r8
        mov r8, rax
        jmp .nx
    .c2:
        cmp rax, r8
        je .nx
        cmp rax, r9
        jle .c3
        mov r10, r9
        mov r9, rax
        jmp .nx
    .c3:
        cmp rax, r9
        je .nx
        cmp rax, r10
        jle .nx
        mov r10, rax
    .nx:
        add rsi, 4
        loop .scan

        mov r14, r10

        call wait_my_turn
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        lea rsi, [msg_task3]
        mov rdx, len_3
        syscall
        mov rax, r14
        call print_num
        call print_newline
        call pass_turn
        jmp child_exit


    child_exit:
        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall

    wait_children:
        ; Мы не используем счетчик loop, а ждем, пока wait4 не скажет "хватит"
    .wl:
        mov rax, SYS_WAIT4
        mov rdi, -1         ; Ждать любого ребенка
        mov rsi, 0
        mov rdx, 0
        mov r10, 0
        syscall

        ; Проверяем результат wait4
        cmp rax, 0
        jg .wl              ; Если RAX > 0 (вернул PID убитого ребенка), ждем следующего

        ; Если RAX <= 0 (ошибка, например -ECHILD "No child processes"), значит все дети мертвы

        ; Освобождаем память
        mov rax, SYS_MUNMAP
        mov rdi, [array_ptr]
        mov rsi, ARRAY_SIZE
        syscall

        ; Выход
        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall

    exit_error:
        mov rax, SYS_EXIT
        mov rdi, 1
        syscall

; =========================================================
; Подпрограммы
; =========================================================

wait_my_turn:
    push rbx
    push rax
    push rcx
    push rdx
    push rdi
    push rsi
.check:
    mov rbx, [array_ptr]
    mov eax, [rbx]
    cmp eax, r15d
    je .ok
    mov rax, SYS_NANOSLEEP
    lea rdi, [timespec]
    xor rsi, rsi
    syscall
    jmp .check
.ok:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rax
    pop rbx
    ret

pass_turn:
    push rbx
    mov rbx, [array_ptr]
    lock inc dword [rbx]
    pop rbx
    ret

rand:
    mov eax, [seed]
    mov edx, 11035152
    mul edx
    add eax, 12345
    mov [seed], eax
    xor edx, edx
    mov ebx, 10000
    div ebx
    mov eax, edx
    ret

; Принимает в RDI адрес буфера (80 байт)
count_digits:
    push rdi                ; Сохраняем начало буфера
    mov rcx, 10
    xor rax, rax
    rep stosq               ; Обнуляем буфер
    pop rbx                 ; RBX = Начало буфера

    mov rsi, [data_ptr]
    mov rcx, COUNT
.ol:
    xor rax, rax
    mov eax, [rsi]
    mov r8, 10              ; Делитель
    test eax, eax
    jnz .il
    inc qword [rbx + 0]     ; Используем RBX как базу
    jmp .ct
.il:
    test eax, eax
    jz .ct
    xor edx, edx
    div r8d                 ; 32-битное деление! EAX / R8D
    inc qword [rbx + rdx*8]
    jmp .il
.ct:
    add rsi, 4
    dec rcx
    jnz .ol
    ret

print_num:
    lea rsi, [num_buffer + 19]
    mov byte [rsi], 0
    mov rbx, 10
.cv:
    dec rsi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    test rax, rax
    jnz .cv
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rdx, [num_buffer + 19]
    sub rdx, rsi
    syscall
    ret
print_newline:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [newline]
    mov rdx, 1
    syscall
    ret
