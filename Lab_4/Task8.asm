format elf64
public _start

section '.data' writable
    prompt db "Enter n: ", 0
    newline db 10, 0

section '.bss' writable
    input_buffer rb 255
    output_buffer rb 255
    number_buffer rb 20
    n dq 0
    result dq 0

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
    call alternate_with_zero
    mov [result], rax

    mov rax, [result]
    mov rsi, output_buffer
    call number_str
    call print_str

    call new_line
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

number_str:
    mov rdi, rsi
    add rdi, 19
    mov byte [rdi], 0
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

new_line:
    push rsi
    mov rsi, newline
    call print_str
    pop rsi
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

alternate_with_zero:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    mov rbx, rax
    mov rsi, number_buffer
    call number_str_temp
    mov rdi, rsi
    call str_length_temp
    mov rcx, rax
    xor rax, rax
    mov rsi, rdi
.process_digits:
    test rcx, rcx
    jz .done
    mov dl, [rsi]
    sub dl, '0'
    imul rax, 100
    movzx rdx, dl
    imul rdx, 10
    add rax, rdx
    inc rsi
    dec rcx
    jmp .process_digits
.done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

number_str_temp:
    push rbx
    push rdx
    mov rdi, rsi
    add rdi, 19
    mov byte [rdi], 0
    dec rdi
    mov rbx, 10
.push_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    test rax, rax
    jnz .push_loop
    inc rdi
    mov rsi, rdi
    pop rdx
    pop rbx
    ret

str_length_temp:
    xor rax, rax
.count_loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .count_loop
.done:
    ret
