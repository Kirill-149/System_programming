format ELF64

public _start

section '.data' writable
    S db 'AMVtdiYVETHnNhuYwnWDVBqL',0
    len equ 24

section '.bss' writable
    place rb 1

section '.text' executable
_start:
    mov ecx, len
    dec ecx
.iter_reverse:
    mov al, [S + ecx]
    push rcx
    call print_symb
    pop rcx
    dec ecx
    jns .iter_reverse
    mov al, 0Ah
    call print_symb
    call exit

print_symb:
    mov [place], al
    mov eax, 4
    mov ebx, 1
    mov ecx, place
    mov edx, 1
    int 0x80
    ret

exit:
    mov eax, 1
    mov ebx, 0
    int 0x80
