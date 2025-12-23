format ELF64
public _start

extrn printf
extrn scanf

section '.data' writeable
    ; Форматы вывода
    header db "Precision (10^-n) | Series1 Terms | Series2 Terms | Series1 Value | Series2 Value", 10, 0
    result_fmt db "%-17d | %-13d | %-13d | %-12.12f | %-12.12f", 10, 0
    input_prompt db "Enter maximum precision (n for 10^-n, 1-12 recommended): ", 0
    input_fmt db "%d", 0
    warning_msg db "Note: Series2 is very slow to converge!", 10, 0

    ; Константы
    three dq 3.0
    four dq 4.0
    six dq 6.0
    one dq 1.0
    neg_one dq -1.0
    ten dq 10.0
    zero dq 0.0
    true_pi dq 3.14159265358979323846
    max_terms dq 10000000  ; Максимум 10 млн итераций

    ; Текущие значения
    precision dd 0
    current_prec dd 0

section '.bss' writeable
    epsilon dq 1.0
    series1_pi dq 0.0
    series2_pi dq 0.0
    terms1 dd 0
    terms2 dd 0
    sum_series2 dq 0.0

section '.text' executable

; Функция для вычисления абсолютного значения double
fabs_double:
    push rax
    movq rax, xmm0
    btr rax, 63
    movq xmm0, rax
    pop rax
    ret

; Функция вычисления 10^(-n)
compute_power10:
    push rcx

    movsd xmm0, [one]
    mov ecx, eax
    test ecx, ecx
    jz .done_power

    .power_loop:
        divsd xmm0, [ten]
        loop .power_loop

    .done_power:
    pop rcx
    ret

; Первое представление
compute_series1:
    push rbx
    push rcx

    movsd [epsilon], xmm0

    ; Инициализация
    movsd xmm0, [three]
    movsd [series1_pi], xmm0
    mov dword [terms1], 0
    mov rbx, 2
    movsd xmm2, [one]
    movsd xmm3, xmm0

    .loop_series1:
        ; Вычисляем k*(k+1)*(k+2)
        mov rax, rbx
        mov rcx, rbx
        inc rcx
        imul rax, rcx
        mov rcx, rbx
        add rcx, 2
        imul rax, rcx

        cvtsi2sd xmm0, rax

        ; Вычисляем член
        movsd xmm1, xmm2
        divsd xmm1, xmm0

        ; Добавляем к сумме
        movsd xmm0, [four]
        mulsd xmm0, xmm1
        addsd xmm0, [series1_pi]

        ; Проверяем изменение с истинным pi
        movsd xmm1, [true_pi]
        subsd xmm1, xmm0
        movsd [series1_pi], xmm0

        movsd xmm0, xmm1
        call fabs_double

        ; Увеличиваем счетчик
        inc dword [terms1]

        ; Проверяем точность
        comisd xmm0, [epsilon]
        jb .done_series1

        ; Следующая итерация
        movsd xmm0, [neg_one]
        mulsd xmm2, xmm0
        add rbx, 2

        ; Проверка на слишком много итераций
        cmp dword [terms1], 1000000
        jge .done_series1

        jmp .loop_series1

    .done_series1:
        movsd xmm0, [series1_pi]
        mov eax, [terms1]

        pop rcx
        pop rbx
        ret

; Второе представление
compute_series2:
    push rbx
    push rcx

    movsd [epsilon], xmm0

    ; Инициализация
    movsd xmm0, [zero]
    movsd [sum_series2], xmm0
    mov dword [terms2], 0
    mov rbx, 1

    .loop_series2:
        ; Вычисляем 1/k^2
        cvtsi2sd xmm0, rbx
        mulsd xmm0, xmm0
        movsd xmm1, [one]
        divsd xmm1, xmm0

        ; Добавляем к сумме
        addsd xmm1, [sum_series2]
        movsd [sum_series2], xmm1

        ; Вычисляем pi
        movsd xmm0, xmm1
        mulsd xmm0, [six]
        sqrtsd xmm0, xmm0

        ; Проверяем ошибку с истинным pi
        movsd xmm1, [true_pi]
        subsd xmm1, xmm0
        movsd [series2_pi], xmm0

        movsd xmm0, xmm1
        call fabs_double

        ; Увеличиваем счетчик
        inc dword [terms2]

        ; Проверяем точность
        comisd xmm0, [epsilon]
        jb .done_series2

        inc rbx

        ; Ограничение итераций
        cmp dword [terms2], 10000000  ; 10 миллионов максимум
        jge .done_series2

        jmp .loop_series2

    .done_series2:
        movsd xmm0, [series2_pi]
        mov eax, [terms2]

        pop rcx
        pop rbx
        ret

_start:
    ; Запрашиваем максимальную точность
    mov rdi, input_prompt
    xor rax, rax
    call printf

    mov rdi, input_fmt
    mov rsi, precision
    xor rax, rax
    call scanf

    ; Предупреждение
    mov rdi, warning_msg
    xor rax, rax
    call printf

    ; Заголовок
    mov rdi, header
    xor rax, rax
    call printf

    ; Цикл по точности
    mov dword [current_prec], 1

    .precision_loop:
        mov eax, [current_prec]
        cmp eax, [precision]
        jg .end_program

        ; Вычисляем epsilon
        call compute_power10
        movsd [epsilon], xmm0

        ; Первый ряд
        movsd xmm0, [epsilon]
        call compute_series1
        movsd [series1_pi], xmm0
        mov ebx, eax

        ; Второй ряд
        movsd xmm0, [epsilon]
        call compute_series2
        movsd [series2_pi], xmm0
        mov ecx, eax

        ; Вывод
        mov rdi, result_fmt
        mov esi, [current_prec]
        mov edx, ebx
        movsd xmm0, [series1_pi]
        movsd xmm1, [series2_pi]
        mov rax, 2
        call printf

        ; Следующая точность
        inc dword [current_prec]
        jmp .precision_loop

    .end_program:
        mov rax, 60
        xor rdi, rdi
        syscall
