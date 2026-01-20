format ELF64

public _start

extrn initscr
extrn start_color
extrn init_pair
extrn raw
extrn noecho
extrn keypad
extrn stdscr
extrn move
extrn addch
extrn refresh
extrn endwin
extrn getch
extrn timeout
extrn usleep
extrn attron
extrn attroff
extrn getmaxx
extrn getmaxy
extrn clear

section '.data' writable
    delay dq 20000

section '.bss' writable
    yMax dq 1
    xMax dq 1
    currentPalette dq 1

    x dq 1
    y dq 1

    dir dq 0            ; 0=Down, 1=Right, 2=Up, 3=Left

    cur_vert_len dq 1
    cur_hor_len  dq 1

    steps_done dq 0

section '.text' executable
_start:
    call initscr
    call raw
    call noecho
    mov rdi, [stdscr]
    mov rsi, 1
    call keypad
    call start_color

    mov rdi, 1
    mov rsi, 0  ; Text Black
    mov rdx, 3  ; Background Yellow
    call init_pair

    ; init_pair(2, COLOR_BLACK, COLOR_CYAN)
    mov rdi, 2
    mov rsi, 0
    mov rdx, 6  ; Background Cyan
    call init_pair

    mov rdi, [stdscr]
    call getmaxy
    mov [yMax], rax


    mov rdi, [stdscr]
    call getmaxx
    mov [xMax], rax


    call reset_spiral_logic

main_loop:
    mov edi, dword [y]
    mov esi, dword [x]
    call move

    mov rdi, [currentPalette]
    shl rdi, 8
    call attron

    mov edi, ' '
    call addch

    mov rdi, [currentPalette]
    shl rdi, 8
    call attroff

    call refresh

    mov rdi, [delay]
    call usleep

    mov rdi, 0
    call timeout
    call getch

    cmp rax, 'p'
    je exit_program
    cmp rax, 'k'
    je toggle_speed

    mov rax, [dir]
    cmp rax, 0
    je .go_down
    cmp rax, 1
    je .go_right
    cmp rax, 2
    je .go_up
    cmp rax, 3
    je .go_left

.go_down:
    inc qword [y]
    jmp .check_turn_vert
.go_right:
    inc qword [x]
    jmp .check_turn_hor
.go_up:
    dec qword [y]
    jmp .check_turn_vert
.go_left:
    dec qword [x]
    jmp .check_turn_hor

.check_turn_vert:
    inc qword [steps_done]
    mov rax, [steps_done]
    cmp rax, [cur_vert_len]
    jl .check_bounds

    mov qword [steps_done], 0
    inc qword [dir]

    add qword [cur_vert_len], 2

    jmp .check_bounds

.check_turn_hor:
    inc qword [steps_done]
    mov rax, [steps_done]
    cmp rax, [cur_hor_len]
    jl .check_bounds

    mov qword [steps_done], 0
    inc qword [dir]

    add qword [cur_hor_len], 2

    jmp .check_bounds

.check_bounds:
    and qword [dir], 3

    cmp qword [x], 0
    jl .reset_collision
    mov rax, [xMax]
    cmp qword [x], rax
    jge .reset_collision

    cmp qword [y], 0
    jl .reset_collision
    mov rax, [yMax]
    cmp qword [y], rax
    jge .reset_collision

    jmp main_loop

.reset_collision:
    mov rax, [currentPalette]
    xor rax, 3
    mov [currentPalette], rax

    call reset_spiral_logic
    call clear
    jmp main_loop

toggle_speed:
    cmp qword [delay], 20000
    je .set_fast
    mov qword [delay], 20000
    jmp main_loop
.set_fast:
    mov qword [delay], 5000
    jmp main_loop

exit_program:
    call endwin
    mov rax, 60
    xor rdi, rdi
    syscall

reset_spiral_logic:
    ;  y = yMax / 2
    xor rdx, rdx
    mov rax, [yMax]
    mov rcx, 2
    div rcx
    mov [y], rax

    ; x = (yMax - 1) / 2
    mov rax, [yMax]
    dec rax
    xor rdx, rdx
    mov rcx, 2
    div rcx
    mov [x], rax


    mov qword [cur_vert_len], 1

    mov rax, [xMax]
    mov rbx, [yMax]
    dec rbx
    sub rax, rbx

    cmp rax, 1
    cmovl rax, [cur_vert_len]

    mov [cur_hor_len], rax

    mov qword [dir], 0
    mov qword [steps_done], 0

    ret
