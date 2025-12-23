format ELF64

section '.data' writable
array_ptr     dq 0         ; Указатель на массив
array_size    dq 0         ; Текущий размер
array_cap     dq 0         ; Емкость массива

section '.text' executable
public array_init
public array_add
public array_remove_first
public array_fill_random
public array_remove_even
public array_count_primes
public array_get_odds
public array_get_size
public array_is_empty

SYS_BRK  = 12
SYS_TIME = 201
SYS_EXIT = 60

array_init:
    push rdi

    mov qword [array_size], 0
    mov qword [array_cap], 16

    mov rax, SYS_BRK
    xor rdi, rdi
    syscall

    mov [array_ptr], rax

    mov rdi, [array_cap]
    shl rdi, 3
    add rdi, rax
    mov rax, SYS_BRK
    syscall

    cmp rax, 0
    je .error

    pop rdi
    ret

.error:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

array_resize:
    push rdi
    push rsi
    push rbx
    push r12
    push r13

    mov rbx, [array_ptr]
    mov r12, [array_cap]
    mov r13, [array_size]

    mov rax, [array_cap]
    shl rax, 1
    mov [array_cap], rax

    mov rax, SYS_BRK
    xor rdi, rdi
    syscall

    mov rdi, [array_cap]
    shl rdi, 3
    add rdi, rax
    mov rax, SYS_BRK
    syscall

    mov rcx, [array_size]
    test rcx, rcx
    jz .copy_done

    mov rsi, rbx
    mov rdi, [array_ptr]

.copy_loop:
    mov rax, [rsi]
    mov [rdi], rax
    add rsi, 8
    add rdi, 8
    loop .copy_loop

.copy_done:
    mov rax, SYS_BRK
    mov rdi, rbx
    syscall

    pop r13
    pop r12
    pop rbx
    pop rsi
    pop rdi
    ret

array_add:
    push rbx

    mov rbx, [array_size]
    cmp rbx, [array_cap]
    jl .no_resize

    push rdi
    call array_resize
    pop rdi

.no_resize:
    mov rax, [array_ptr]
    mov rbx, [array_size]
    mov [rax + rbx * 8], rdi

    inc qword [array_size]

    mov rax, 1
    pop rbx
    ret

array_remove_first:
    cmp qword [array_size], 0
    je .empty

    mov rax, [array_ptr]
    mov rax, [rax]

    mov rcx, [array_size]
    dec rcx
    test rcx, rcx
    jz .no_shift

    mov rdi, [array_ptr]
    mov rsi, rdi
    add rsi, 8

    push rax  ; Сохраняем возвращаемое значение

.shift_loop:
    mov rdx, [rsi]
    mov [rdi], rdx
    add rdi, 8
    add rsi, 8
    loop .shift_loop

    pop rax   ; Восстанавливаем возвращаемое значение

.no_shift:
    dec qword [array_size]
    ret

.empty:
    xor rax, rax
    ret

array_fill_random:
    push rbx
    push r12

    call array_init

    mov r12, rdi

    mov rax, SYS_TIME
    syscall
    mov rbx, rax

.fill_loop:
    test r12, r12
    jz .done

    mov rax, rbx
    mov rdx, 0x5DEECE66D
    mul rdx
    add rax, 0xB
    mov rbx, rax
    shr rax, 16
    and rax, 0x7FFF

    xor rdx, rdx
    mov rcx, 1000
    div rcx
    mov rax, rdx
    inc rax

    mov rdi, rax
    call array_add

    dec r12
    jmp .fill_loop

.done:
    pop r12
    pop rbx
    ret

array_remove_even:
    push rbx
    push r12
    push r13

    mov r12, [array_size]
    test r12, r12
    jz .done

    mov r13, [array_ptr]
    xor rbx, rbx        ; Индекс для записи
    xor rcx, rcx        ; Индекс для чтения

.filter_loop:
    cmp rcx, r12
    jge .update_size

    mov rax, [r13 + rcx * 8]

    test rax, 1
    jz .skip

    mov [r13 + rbx * 8], rax
    inc rbx

.skip:
    inc rcx
    jmp .filter_loop

.update_size:
    mov [array_size], rbx

.done:
    pop r13
    pop r12
    pop rbx
    ret

is_prime:
    cmp rdi, 2
    je .prime

    cmp rdi, 1
    jle .not_prime

    test rdi, 1
    jz .not_prime

    mov r8, 3

.check_loop:
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

array_count_primes:
    push rbx
    push r12
    push r13
    push r14  ; Используем r14 как счетчик простых чисел

    mov r12, [array_size]
    test r12, r12
    jz .zero

    mov r13, [array_ptr]
    xor rbx, rbx        ; Индекс в массиве
    xor r14, r14        ; Счетчик простых чисел

.count_loop:
    cmp rbx, r12
    jge .done

    mov rdi, [r13 + rbx * 8]

    push rbx
    push r12
    push r13
    push r14
    call is_prime
    pop r14
    pop r13
    pop r12
    pop rbx

    add r14, rax

    inc rbx
    jmp .count_loop

.done:
    mov rax, r14
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.zero:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_get_odds:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r13, rdi        ; Буфер
    mov r14, rsi        ; Максимальный размер
    mov r12, [array_size]
    test r12, r12
    jz .zero

    mov rbx, [array_ptr]
    xor r15, r15        ; Счетчик нечетных чисел
    xor rcx, rcx        ; Индекс в массиве

.odds_loop:
    cmp rcx, r12
    jge .done
    cmp r15, r14
    jge .done

    mov rax, [rbx + rcx * 8]

    test rax, 1
    jz .next

    mov [r13 + r15 * 8], rax
    inc r15

.next:
    inc rcx
    jmp .odds_loop

.done:
    mov rax, r15
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.zero:
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_get_size:
    mov rax, [array_size]
    ret

array_is_empty:
    cmp qword [array_size], 0
    sete al
    movzx eax, al
    ret
