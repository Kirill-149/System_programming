format ELF64

section '.data' writable
queue_size      dq 0         ; Текущий размер очереди
queue_capacity  dq 1000      ; Емкость очереди
queue_start     dq 0         ; Указатель на начало очереди
queue_end       dq 0         ; Указатель на конец очереди
queue_memory_start dq 0      ; Начало выделенной памяти
queue_memory_end   dq 0      ; Конец выделенной памяти

section '.bss' writable
queue_memory    rq 1000      ; Память для данных очереди

section '.text' executable
public queue_init
public queue_enqueue
public queue_dequeue
public queue_fill_random
public queue_remove_even
public queue_count_primes
public queue_get_odds
public queue_size_func
public queue_is_empty

; Инициализация очереди
queue_init:
    mov rax, queue_memory
    mov [queue_start], rax
    mov [queue_end], rax
    mov [queue_memory_start], rax
    mov rax, queue_memory
    add rax, 1000 * 8
    mov [queue_memory_end], rax
    mov qword [queue_size], 0
    ret

; Добавление элемента в конец
; rdi - значение для добавления
; возвращает rax=1 успех, rax=0 ошибка
queue_enqueue:
    mov r8, [queue_size]
    cmp r8, [queue_capacity]
    jge .enqueue_full

    mov rcx, [queue_end]
    mov [rcx], rdi          ; Сохраняем значение

    add rcx, 8              ; Увеличиваем указатель
    cmp rcx, [queue_memory_end]
    jl .no_wrap_end
    mov rcx, [queue_memory_start]
.no_wrap_end:
    mov [queue_end], rcx

    inc r8                  ; Увеличиваем размер
    mov [queue_size], r8

    mov rax, 1
    ret

.enqueue_full:
    mov rax, 0
    ret

; Удаление элемента из начала
; возвращает значение в rax, 0 если очередь пуста
queue_dequeue:
    mov r8, [queue_size]
    test r8, r8
    jle .dequeue_empty

    mov rcx, [queue_start]
    mov rax, [rcx]          ; Загружаем значение

    add rcx, 8              ; Увеличиваем указатель
    cmp rcx, [queue_memory_end]
    jl .no_wrap_start
    mov rcx, [queue_memory_start]
.no_wrap_start:
    mov [queue_start], rcx

    dec r8                  ; Уменьшаем размер
    mov [queue_size], r8
    ret

.dequeue_empty:
    mov rax, 0
    ret

; Заполнение случайными числами
; rdi - количество элементов
queue_fill_random:
    push rbx
    push r12

    ; Проверяем размер
    mov rax, rdi
    cmp rax, [queue_capacity]
    jle .size_ok
    mov rax, [queue_capacity]
.size_ok:
    mov r12, rax

    ; Очищаем очередь
    call queue_init

    xor rbx, rbx            ; Счетчик = 0
.fill_loop:
    cmp rbx, r12
    jge .fill_done

    ; Генерация случайного числа
    rdtsc
    shl rdx, 32
    or rax, rdx
    and rax, 0x3FF
    inc rax

    mov rdi, rax
    call queue_enqueue

    inc rbx
    jmp .fill_loop

.fill_done:
    pop r12
    pop rbx
    ret

; Удаление всех четных чисел
; Нечетные числа добавляются обратно в конец
queue_remove_even:
    push rbx
    push r12

    mov r12, [queue_size]   ; Сохраняем исходный размер
    xor rbx, rbx            ; Счетчик = 0

.process_loop:
    cmp rbx, r12
    jge .process_done

    call queue_dequeue
    test rax, rax
    jz .process_done

    ; Проверяем на нечетность
    test rax, 1
    jz .next_element

    ; Нечетное - добавляем обратно
    mov rdi, rax
    call queue_enqueue

.next_element:
    inc rbx
    jmp .process_loop

.process_done:
    pop r12
    pop rbx
    ret

; Проверка числа на простоту
; rdi - число для проверки
; возвращает rax=1 если простое, rax=0 если нет
is_prime:
    cmp rdi, 2
    je .is_prime_num
    jl .not_prime

    test rdi, 1             ; Проверка на четность
    jz .not_prime

    mov r8, rdi             ; Сохраняем число
    mov r9, 3               ; Начинаем с 3

.check_divisor:
    mov rax, r8
    xor rdx, rdx
    div r9

    test rdx, rdx
    jz .not_prime

    ; r9 * r9 <= r8?
    mov rax, r9
    mul rax
    cmp rax, r8
    jg .is_prime_num        ; Если квадрат делителя > числа - простое

    add r9, 2               ; Следующий нечетный делитель
    jmp .check_divisor

.is_prime_num:
    mov rax, 1
    ret

.not_prime:
    mov rax, 0
    ret

; Подсчет количества простых чисел в очереди
queue_count_primes:
    push rbx
    push r12
    push r13
    push r14

    mov r12, [queue_size]
    xor r13, r13            ; Счетчик простых = 0
    xor rbx, rbx            ; Обработанные = 0

    mov r14, [queue_start]  ; Текущий указатель

.count_loop:
    cmp rbx, r12
    jge .count_done

    mov rdi, [r14]          ; Берем элемент
    call is_prime
    add r13, rax

    ; Следующий элемент
    add r14, 8
    cmp r14, [queue_memory_end]
    jl .no_wrap_count
    mov r14, [queue_memory_start]
.no_wrap_count:

    inc rbx
    jmp .count_loop

.count_done:
    mov rax, r13

    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Получение списка нечетных чисел
; rdi - указатель на массив для результата
; rsi - максимальный размер буфера
; возвращает количество нечетных чисел
queue_get_odds:
    push rbx
    push r12
    push r13
    push r14

    mov r13, rdi            ; Указатель на результат
    mov r14, rsi            ; Максимальный размер
    mov r12, [queue_size]
    xor rbx, rbx            ; Счетчик нечетных = 0
    xor rdi, rdi            ; Обработанные = 0

    mov rsi, [queue_start]  ; Текущий указатель

.get_odds_loop:
    cmp rdi, r12
    jge .get_odds_done
    cmp rbx, r14
    jge .get_odds_done

    mov rax, [rsi]          ; Берем элемент

    test rax, 1             ; Проверяем на нечетность
    jz .next_odd

    mov [r13 + rbx * 8], rax ; Сохраняем
    inc rbx

.next_odd:
    ; Следующий элемент
    add rsi, 8
    cmp rsi, [queue_memory_end]
    jl .no_wrap_odds
    mov rsi, [queue_memory_start]
.no_wrap_odds:

    inc rdi
    jmp .get_odds_loop

.get_odds_done:
    mov rax, rbx

    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Получение размера очереди
queue_size_func:
    mov rax, [queue_size]
    ret

; Проверка пустоты очереди
queue_is_empty:
    mov rax, [queue_size]
    test rax, rax
    sete al
    movzx eax, al
    ret
