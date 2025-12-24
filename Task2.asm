format ELF64 executable 3
entry start

; Константы
SYS_BRK        = 12
SYS_CLONE      = 56
SYS_WAITID     = 247
SYS_EXIT       = 60
SYS_WRITE      = 1
SYS_SCHED_YIELD = 24
SYS_NANOSLEEP  = 35

CLONE_VM       = 0x00000100
CLONE_FS       = 0x00000200
CLONE_FILES    = 0x00000400
CLONE_SIGHAND  = 0x00000800
CLONE_THREAD   = 0x00010000

STDOUT         = 1
ARRAY_SIZE     = 943
STACK_SIZE     = 4096 * 4

; Структура thread_data (определяем смещения)
THREAD_DATA.array   = 0
THREAD_DATA.size    = 8
THREAD_DATA.task_id = 12
THREAD_DATA.result  = 16
THREAD_DATA_SIZE    = 24

segment readable writable
; Сообщения для вывода
msg_prime       db "Prime numbers: ",0
msg_fifth       db "Fifth after min: ",0
msg_median      db "Median: ",0
msg_digit       db "Most frequent digit: ",0
newline         db 10,0
digit_counts    dd 10 dup(0) ; Счетчики цифр

; Массив указателей на сообщения
msg_array       dq msg_prime, msg_fifth, msg_median, msg_digit

; Случайные числа генерируем линейным конгруэнтным методом
seed            dd 123456789

segment readable writable
array           dq ?     ; Указатель на массив
threads         dq 4 dup(?) ; ID потоков
stacks          dq 4 dup(?) ; Указатели на стеки потоков
tdatas          rb 4 * THREAD_DATA_SIZE ; Данные для потоков
output_buffer   rb 64    ; Буфер для вывода
counter_lock    dd 0     ; Примитив синхронизации

segment readable executable
; ======================= СИНХРОНИЗАЦИЯ =======================
lock:
    mov eax, 1
.spin:
    xchg eax, [counter_lock]
    test eax, eax
    jnz .spin
    ret

unlock:
    mov dword [counter_lock], 0
    ret

; ======================= МАТЕМАТИЧЕСКИЕ ФУНКЦИИ =======================
; Генератор псевдослучайных чисел (LCG)
rand:
    mov eax, [seed]
    imul eax, 1103515245
    add eax, 12345
    and eax, 0x7fffffff
    mov [seed], eax
    ret

; Проверка на простое число
; Вход: rdi = число
; Выход: rax = 1 если простое, 0 если нет
is_prime:
    cmp rdi, 2
    je .prime
    jl .not_prime

    test rdi, 1
    jz .not_prime

    mov r8, 3

.check_loop:
    ; Проверяем делитель r8
    mov rax, r8
    imul rax, r8
    cmp rax, rdi
    jg .prime

    mov rax, rdi
    xor rdx, rdx
    div r8
    test rdx, rdx
    jz .not_prime

    add r8, 2
    jmp .check_loop

.prime:
    mov rax, 1
    ret

.not_prime:
    xor rax, rax
    ret

; Быстрая сортировка (рекурсивная)
; Вход: rdi = массив, rsi = индекс начала, rdx = индекс конца
qsort:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    mov [rsp], rdi    ; сохраняем массив
    mov [rsp+8], rsi  ; low
    mov [rsp+16], rdx ; high

    cmp rsi, rdx
    jge .end

    ; Выбираем опорный элемент (середина)
    mov rax, rsi
    add rax, rdx
    shr rax, 1

    ; Получаем опорный элемент
    mov ecx, [rdi + rax*4]
    mov [rsp+24], ecx ; pivot

    mov rbx, rsi ; i = low
    mov r12, rdx ; j = high

.partition:
.while_i:
    cmp rbx, r12
    jg .partition_done

    mov eax, [rdi + rbx*4]
    cmp eax, [rsp+24]
    jge .while_j
    inc rbx
    jmp .while_i

.while_j:
    cmp r12, rbx
    jl .swap_check

    mov eax, [rdi + r12*4]
    cmp eax, [rsp+24]
    jle .swap_check
    dec r12
    jmp .while_j

.swap_check:
    cmp rbx, r12
    jg .partition_done

    ; Обмен элементов
    mov eax, [rdi + rbx*4]
    mov ecx, [rdi + r12*4]
    mov [rdi + rbx*4], ecx
    mov [rdi + r12*4], eax

    inc rbx
    dec r12
    jmp .partition

.partition_done:
    ; Рекурсивные вызовы
    mov rdi, [rsp]
    mov rsi, [rsp+8] ; low
    mov rdx, r12     ; j
    call qsort

    mov rdi, [rsp]
    mov rsi, rbx     ; i
    mov rdx, [rsp+16] ; high
    call qsort

.end:
    leave
    ret

; ======================= ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =======================
; Преобразование числа в строку
; Вход: rax = число, rdi = буфер
; Выход: rdi = указатель на начало строки
int_to_str:
    push rbx
    push rdx
    push rcx

    mov rbx, rdi
    add rbx, 20
    mov byte [rbx], 0
    dec rbx

    mov rcx, 10
    xor rsi, rsi

.convert_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rbx], dl
    dec rbx
    inc rsi
    test rax, rax
    jnz .convert_loop

    inc rbx
    mov rdi, rbx

    pop rcx
    pop rdx
    pop rbx
    ret

; Вывод строки
; Вход: rsi = строка
print_str:
    push rax
    push rdi
    push rdx
    push rcx

    mov rdi, rsi
    xor rcx, rcx
.strlen:
    cmp byte [rdi + rcx], 0
    je .print
    inc rcx
    jmp .strlen

.print:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rdx, rcx
    syscall

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

; ======================= ЗАДАЧИ ПОТОКОВ =======================
; Задача A: подсчет простых чисел
task_prime:
    mov rsi, [rdi + THREAD_DATA.array]
    mov ecx, [rdi + THREAD_DATA.size]
    xor r8d, r8d      ; счетчик

.loop:
    mov rdx, [rsi]
    push rcx
    push rsi
    push rdi
    mov rdi, rdx
    call is_prime
    pop rdi
    pop rsi
    pop rcx
    add r8d, eax
    add rsi, 8
    loop .loop

    mov [rdi + THREAD_DATA.result], r8
    ret

; Задача B: пятое после минимального
task_fifth:
    push rbp
    mov rbp, rsp

    mov rsi, [rdi + THREAD_DATA.array]
    mov ecx, [rdi + THREAD_DATA.size]

    ; Копируем массив для сортировки
    push rdi
    mov rax, rcx
    shl rax, 3  ; 8 байт на элемент
    sub rsp, rax
    mov r9, rsp   ; Сохраняем указатель на копию

    mov rdi, r9
    rep movsq

    ; Сортируем копию
    mov rdi, r9
    mov rsi, 0
    mov edx, ecx
    dec edx
    call qsort

    ; Пятый элемент (индекс 4, так как 0-based)
    cmp ecx, 5
    jl .error

    mov rax, [r9 + 4*8] ; Пятый элемент

.done:
    mov rsp, rbp
    pop rbp
    mov [rdi + THREAD_DATA.result], rax
    ret

.error:
    xor rax, rax
    jmp .done

; Задача C: медиана
task_median:
    push rbp
    mov rbp, rsp

    mov rsi, [rdi + THREAD_DATA.array]
    mov ecx, [rdi + THREAD_DATA.size]

    ; Копируем массив для сортировки
    push rdi
    mov rax, rcx
    shl rax, 3  ; 8 байт на элемент
    sub rsp, rax
    mov r9, rsp   ; Сохраняем указатель на копию

    mov rdi, r9
    rep movsq

    ; Сортируем копию
    mov rdi, r9
    mov rsi, 0
    mov edx, ecx
    dec edx
    call qsort

    ; Находим медиану
    mov rax, rcx
    shr rax, 1 ; Средний индекс

    test rcx, 1
    jnz .odd

    ; Для четного количества: среднее двух центральных
    mov rdx, [r9 + rax*8 - 8]
    add rdx, [r9 + rax*8]
    shr rdx, 1
    mov rax, rdx
    jmp .done

.odd:
    mov rax, [r9 + rax*8]

.done:
    mov rsp, rbp
    pop rbp
    mov [rdi + THREAD_DATA.result], rax
    ret

; Задача D: наиболее частая цифра
task_digit:
    mov rsi, [rdi + THREAD_DATA.array]
    mov ecx, [rdi + THREAD_DATA.size]

    ; Обнуляем счетчики цифр
    push rdi
    mov rdi, digit_counts
    push rcx
    mov rcx, 10
    xor eax, eax
    rep stosd
    pop rcx
    pop rdi

    mov rsi, [rdi + THREAD_DATA.array]

.digit_loop:
    mov rax, [rsi]
    test rax, rax
    jz .count_zero

.count_digits:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    inc dword [digit_counts + rdx*4]
    test rax, rax
    jnz .count_digits
    jmp .next

.count_zero:
    inc dword [digit_counts]

.next:
    add rsi, 8
    loop .digit_loop

    ; Находим максимальную цифру
    mov ecx, 9
    mov eax, [digit_counts]
    xor edx, edx ; Цифра с максимальным счетчиком

.max_loop:
    mov ebx, [digit_counts + rcx*4]
    cmp ebx, eax
    jle .not_max
    mov eax, ebx
    mov edx, ecx
.not_max:
    dec ecx
    jns .max_loop

    mov [rdi + THREAD_DATA.result], rdx
    ret

; ======================= ФУНКЦИЯ ПОТОКА =======================
thread_func:
    mov rdi, [rsp]   ; получаем thread_data из стека

    mov eax, [rdi + THREAD_DATA.task_id]
    cmp eax, 0
    je .prime
    cmp eax, 1
    je .fifth
    cmp eax, 2
    je .median

    ; Иначе task_digit
    call task_digit
    jmp .output

.prime:
    call task_prime
    jmp .output

.fifth:
    call task_fifth
    jmp .output

.median:
    call task_median

.output:
    ; Блокировка для корректного вывода
    call lock

    ; Вывод сообщения в зависимости от task_id
    mov eax, [rdi + THREAD_DATA.task_id]
    mov rsi, [msg_array + rax*8]
    call print_str

    ; Вывод результата
    mov rax, [rdi + THREAD_DATA.result]
    mov rdi, output_buffer
    call int_to_str
    mov rsi, rdi
    call print_str

    ; Новая строка
    mov rsi, newline
    call print_str

    call unlock

    ; Завершение потока
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; ======================= ОСНОВНАЯ ПРОГРАММА =======================
start:
    ; Инициализация кучи
    mov rax, SYS_BRK
    xor rdi, rdi
    syscall
    mov [array], rax

    ; Выделяем память под массив
    mov rax, [array]
    add rax, ARRAY_SIZE * 8
    mov rdi, rax
    mov rax, SYS_BRK
    syscall

    ; Заполняем массив случайными числами
    mov rdi, [array]
    mov ecx, ARRAY_SIZE
.fill_array:
    call rand
    stosd
    loop .fill_array

    ; Создаем стеки для потоков
    mov ecx, 4
    mov rbx, stacks
.alloc_stacks:
    mov rax, SYS_BRK
    xor rdi, rdi
    syscall
    mov [rbx], rax
    add rax, STACK_SIZE
    mov rdi, rax
    mov rax, SYS_BRK
    syscall
    add rbx, 8
    loop .alloc_stacks

    ; Инициализируем данные для потоков
    mov ecx, 4
    xor ebx, ebx
    mov r15, tdatas
.init_tdata:
    ; Вычисляем адрес текущей структуры
    mov rax, THREAD_DATA_SIZE
    imul rax, rbx
    lea rdi, [r15 + rax]

    ; Заполняем структуру
    mov rax, [array]
    mov [rdi + THREAD_DATA.array], rax
    mov dword [rdi + THREAD_DATA.size], ARRAY_SIZE
    mov dword [rdi + THREAD_DATA.task_id], ebx

    inc rbx
    cmp rbx, 4
    jl .init_tdata

    ; Создаем потоки
    mov ecx, 4
    xor ebx, ebx
.create_threads:
    mov rdi, CLONE_VM or CLONE_FS or CLONE_FILES or CLONE_SIGHAND or CLONE_THREAD
    mov rsi, [stacks + rbx*8]
    add rsi, STACK_SIZE - 8

    ; Помещаем адрес thread_data в стек потока
    mov rax, THREAD_DATA_SIZE
    imul rax, rbx
    lea rax, [tdatas + rax]
    mov [rsi], rax

    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    mov rax, SYS_CLONE
    syscall

    test rax, rax
    js .clone_error

    mov [threads + rbx*8], rax
    inc rbx
    loop .create_threads

    ; Ожидаем завершения всех потоков
.wait_loop:
    mov rax, SYS_SCHED_YIELD
    syscall

    mov ecx, 4
    xor ebx, ebx
    xor r8, r8  ; Счетчик завершенных потоков
.check_threads:
    cmp qword [threads + rbx*8], 0
    je .next_check

    ; Проверяем, завершился ли поток
    mov rax, SYS_WAITID
    mov rdi, -1
    lea rsi, [threads + rbx*8]
    xor rdx, rdx
    mov r10, 1  ; WNOHANG
    syscall

    test rax, rax
    jz .thread_done
    jmp .next_check

.thread_done:
    mov qword [threads + rbx*8], 0
    inc r8

.next_check:
    inc rbx
    loop .check_threads

    cmp r8, 4
    jl .wait_loop

    ; Завершение программы
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.clone_error:
    ; Если не удалось создать поток
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
