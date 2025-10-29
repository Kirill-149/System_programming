format elf64
public _start

section '.data' writable
    prompt db "Enter n: ", 0
    non_dec_msg db "non-decreasing order", 10, 0
    dec_msg db "decreasing order", 10, 0

section '.bss' writable
    input_buffer rb 255
    digit_buffer rb 20
    n dq 0

section '.text' executable

_start:
    mov rsi, prompt
    call print_str

    mov rsi, input_buffer
    call input_keyboard

    mov rsi, input_buffer
    call str_number
    mov [n], rax

    mov rax, [n]
    call check_order

    test rax, rax
    jz .decreasing
    mov rsi, non_dec_msg
    jmp .print_result
.decreasing:
    mov rsi, dec_msg
.print_result:
    call print_str
    call exit

input_keyboard:
    push rax
    push rdi
    push rdx
    mov rax, 0
    mov rdi, 0
    mov rdx, 255
    syscall
    pop rdx
    pop rdi
    pop rax
    ret

str_number:
    xor rax, rax
    xor rcx, rcx
.next_digit:
    mov cl, [rsi]
    cmp cl, 10
    je .done
    cmp cl, 13
    je .done
    cmp cl, 0
    je .done
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .next_digit
.done:
    ret

print_str:
    push rsi
    call str_length
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    pop rsi
    syscall
    ret

str_length:
    xor rax, rax
.count:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .count
.done:
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

check_order:
    push rbx
    push rcx
    push rdx
    push rsi

    mov rsi, digit_buffer
    call number_to_digits
    mov rcx, rax

    cmp rcx, 1
    jle .non_decreasing

    mov rsi, digit_buffer
    mov rbx, rsi
    add rbx, rcx
    dec rbx

.check_loop:
    cmp rsi, rbx
    jae .non_decreasing

    mov dl, [rsi]
    mov dh, [rsi + 1]
    cmp dl, dh
    jg .decreasing

    inc rsi
    jmp .check_loop

.non_decreasing:
    mov rax, 1
    jmp .done
.decreasing:
    xor rax, rax
.done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

number_to_digits:
    push rbx
    push rdx
    push rdi

    mov rdi, rsi
    mov rbx, 10
    xor rcx, rcx

.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    inc rdi
    inc rcx
    test rax, rax
    jnz .convert_loop

    mov rdi, rsi
    mov rbx, rsi
    add rbx, rcx
    dec rbx

.reverse_loop:
    cmp rdi, rbx
    jae .reverse_done
    mov al, [rdi]
    mov dl, [rbx]
    mov [rdi], dl
    mov [rbx], al
    inc rdi
    dec rbx
    jmp .reverse_loop

.reverse_done:
    mov rax, rcx
    pop rdi
    pop rdx
    pop rbx
    ret
