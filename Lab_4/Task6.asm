format elf64
public _start

section '.data' writable
    prompt db "Enter n: ", 0
    prompt_len = $ - prompt
    result_msg db "Count: ", 0
    result_msg_len = $ - result_msg
    newline db 10

section '.bss' writable
    input_buffer rb 255
    number_buffer rb 20
    n dq 0
    count dq 0

section '.text' executable

_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 255
    syscall

    mov rsi, input_buffer
    call string_to_number
    mov [n], rax

    call calculate_count

    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall

    mov rax, [count]
    mov rsi, number_buffer
    call number_to_string
    call print_string

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

string_to_number:
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

number_to_string:
    mov rdi, rsi
    add rdi, 19
    mov byte [rdi], 0
    dec rdi
    mov byte [rdi], 10
    dec rdi
    mov rbx, 10
.push_digits:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    test rax, rax
    jnz .push_digits
    inc rdi
    mov rsi, rdi
    ret

print_string:
    push rsi
    call string_length
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    pop rsi
    syscall
    ret

string_length:
    xor rax, rax
.count_loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .count_loop
.done:
    ret

calculate_count:
    push rbx
    push rcx
    mov qword [count], 0
    mov rcx, 1
.check_loop:
    cmp rcx, [n]
    jg .done
    mov rax, rcx
    xor rdx, rdx
    mov rbx, 5
    div rbx
    test rdx, rdx
    jnz .next_number
    mov rax, rcx
    xor rdx, rdx
    mov rbx, 3
    div rbx
    test rdx, rdx
    jz .next_number
    mov rax, rcx
    xor rdx, rdx
    mov rbx, 7
    div rbx
    test rdx, rdx
    jz .next_number
    inc qword [count]
.next_number:
    inc rcx
    jmp .check_loop
.done:
    pop rcx
    pop rbx
    ret
