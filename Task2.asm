format ELF64
public _start

extrn printf
extrn atoi
extrn exit
extrn fflush

SYS_MMAP    equ 9
SYS_CLONE   equ 56
SYS_WAIT4   equ 61
SYS_EXIT    equ 60

PROT_READ   equ 1
PROT_WRITE  equ 2
MAP_SHARED  equ 1
MAP_ANON    equ 32
SIGCHLD     equ 17

section '.data' writable
    msg_usage   db "Usage: ./clone <N>", 10, 0
    msg_init    db "Initial: ", 0
    msg_ch1     db "Child 1: ", 0
    msg_ch2     db "Child 2: ", 0
    msg_final   db "Final:   ", 0
    fmt_num     db "%d ", 0
    fmt_nl      db 10, 0
    N           dq 0
    arr         dq 0

section '.text' executable

_start:
    and     rsp, -16
    pop     rcx
    cmp     rcx, 2
    jl      .usage

    mov     rdi, [rsp + 8]
    call    atoi
    mov     [N], rax
    test    rax, rax
    jle     .exit0

    ; mmap
    mov     rax, SYS_MMAP
    xor     rdi, rdi
    mov     rsi, [N]
    shl     rsi, 2
    mov     rdx, PROT_READ or PROT_WRITE
    mov     r10, MAP_SHARED or MAP_ANON
    mov     r8, -1
    xor     r9, r9
    syscall
    cmp     rax, -1
    je      .exit0
    mov     [arr], rax

    ; init array
    mov     rcx, [N]
    mov     rbx, rax
    xor     rdx, rdx
.init:
    cmp     rdx, rcx
    jge     .init_done
    lea     eax, [rdx + 1]
    mov     [rbx + rdx*4], eax
    inc     rdx
    jmp     .init
.init_done:

    mov     rdi, msg_init
    mov     rsi, [arr]
    mov     rdx, [N]
    call    print_arr

    ; clone 1
    mov     rax, SYS_CLONE
    mov     rdi, SIGCHLD
    xor     rsi, rsi
    xor     rdx, rdx
    syscall
    cmp     rax, 0
    je      .child1

    ; clone 2
    mov     rax, SYS_CLONE
    mov     rdi, SIGCHLD
    xor     rsi, rsi
    xor     rdx, rdx
    syscall
    cmp     rax, 0
    je      .child2

    ; wait
    mov     rax, SYS_WAIT4
    mov     rdi, -1
    xor     rsi, rsi
    xor     rdx, rdx
    xor     r10, r10
    syscall
    mov     rax, SYS_WAIT4
    mov     rdi, -1
    xor     rsi, rsi
    xor     rdx, rdx
    xor     r10, r10
    syscall

    mov     rdi, msg_final
    mov     rsi, [arr]
    mov     rdx, [N]
    call    print_arr

.exit0:
    xor     rdi, rdi
    call    exit

.usage:
    mov     rdi, msg_usage
    xor     rax, rax
    call    printf
    mov     rdi, 1
    call    exit

.child1:
    and     rsp, -16
    mov     rcx, [N]
    mov     rbx, [arr]
    xor     rdx, rdx
.even_loop:
    cmp     rdx, rcx
    jge     .even_done
    mov     eax, [rbx + rdx*4]
    test    eax, 1
    jnz     .even_next
    inc     eax
    mov     [rbx + rdx*4], eax
.even_next:
    inc     rdx
    jmp     .even_loop
.even_done:
    mov     rdi, msg_ch1
    mov     rsi, [arr]
    mov     rdx, [N]
    call    print_arr
    mov     rax, SYS_EXIT
    xor     rdi, rdi
    syscall

.child2:
    and     rsp, -16
    mov     rcx, [N]
    mov     rbx, [arr]
    xor     rdx, rdx
.odd_loop:
    cmp     rdx, rcx
    jge     .odd_done
    mov     eax, [rbx + rdx*4]
    test    eax, 1
    jz      .odd_next
    dec     eax
    mov     [rbx + rdx*4], eax
.odd_next:
    inc     rdx
    jmp     .odd_loop
.odd_done:
    mov     rdi, msg_ch2
    mov     rsi, [arr]
    mov     rdx, [N]
    call    print_arr
    mov     rax, SYS_EXIT
    xor     rdi, rdi
    syscall

print_arr:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r13, rdi
    mov     rbx, rsi
    mov     r12, rdx

    mov     rdi, r13
    xor     rax, rax
    call    printf

    xor     r14, r14
.loop:
    cmp     r14, r12
    jge     .done
    mov     rdi, fmt_num
    movsxd  rsi, dword [rbx + r14*4]
    xor     rax, rax
    call    printf
    inc     r14
    jmp     .loop
.done:
    mov     rdi, fmt_nl
    xor     rax, rax
    call    printf
    xor     rdi, rdi
    call    fflush

    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    leave
    ret
