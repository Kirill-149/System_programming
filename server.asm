format ELF64
public _start

SYS_WRITE       = 1
SYS_CLOSE       = 3
SYS_SOCKET      = 41
SYS_ACCEPT      = 43
SYS_BIND        = 49
SYS_LISTEN      = 50
SYS_EXIT        = 60

AF_INET         = 2
SOCK_STREAM     = 1
INADDR_ANY      = 0

section '.data' writeable
    notify_ready    db '[Server started on port 5555]', 10, 0
    notify_player   db '[New connection]', 10, 0

    buffer_in       rb 256
    buffer_out      rb 1024

    host_address:
        dw AF_INET
        db 0x15, 0xB3    ; Порт 5555 (0xB315 в сетевом порядке байт)
        dd INADDR_ANY
        dq 0

    main_socket     dq 0
    game_socket     dq 0

    challenger_pts  dq 0
    host_pts        dq 0

    challenger_cards rb 20
    challenger_count dq 0

    host_cards      rb 20
    host_count      dq 0

    deck_pointer    dq 0
    rand_seed       dq 987654321

    face_symbols    db '2','3','4','5','6','7','8','9','X','V','Q','K','A'

    card_strength   db 2,2,2,2, 3,3,3,3, 4,4,4,4, 5,5,5,5, 6,6,6,6, 7,7,7,7, 8,8,8,8, 9,9,9,9
                    db 10,10,10,10
                    db 10,10,10,10
                    db 10,10,10,10
                    db 10,10,10,10
                    db 10,10,10,10

    shuffled_deck   db 52 dup(0)

section '.text' executable
_start:
    mov rcx, 52
    xor rax, rax
.init_deck:
    mov [shuffled_deck + rax], al
    inc rax
    loop .init_deck

    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    syscall
    mov [main_socket], rax

    mov rax, SYS_BIND
    mov rdi, [main_socket]
    mov rsi, host_address
    mov rdx, 16
    syscall

    mov rax, SYS_LISTEN
    mov rdi, [main_socket]
    mov rsi, 1
    syscall

    mov rsi, notify_ready
    call output_message

accept_cycle:
    mov rax, SYS_ACCEPT
    mov rdi, [main_socket]
    mov rsi, 0
    mov rdx, 0
    syscall
    mov [game_socket], rax

    mov rsi, notify_player
    call output_message

session_start:
    mov qword [challenger_pts], 0
    mov qword [host_pts], 0
    mov qword [deck_pointer], 0

    mov qword [challenger_count], 0
    mov qword [host_count], 0

    call shuffle_cards

    mov rdi, 0
    call draw_card
    mov rdi, 0
    call draw_card

    mov rdi, 1
    call draw_card
    mov rdi, 1
    call draw_card

    cmp qword [challenger_pts], 20
    je verify_host_blackjack

    call display_hidden_state
    jmp game_cycle

game_cycle:
    mov rax, 0
    mov rdi, [game_socket]
    mov rsi, buffer_in
    mov rdx, 255
    syscall

    cmp rax, 0
    jle terminate_session

    mov al, byte [buffer_in]

    cmp al, '1'
    je request_card

    cmp al, '2'
    je freeze_turn

    jmp terminate_session

request_card:
    mov rdi, 0
    call draw_card
    cmp qword [challenger_pts], 21
    jg challenger_busted
    call display_hidden_state
    jmp game_cycle

freeze_turn:
host_move:
    cmp qword [host_pts], 17
    jge host_finished
    mov rdi, 1
    call draw_card
    jmp host_move

host_finished:
    mov rax, [host_pts]
    cmp rax, 21
    jg challenger_victory
    mov rbx, [challenger_pts]
    cmp rbx, rax
    jg challenger_victory
    jl challenger_defeat
    je match_draw

challenger_busted:
    mov rdi, buffer_out
    call message_busted
    jmp finalize_round

challenger_victory:
    mov rdi, buffer_out
    call message_victory
    jmp finalize_round

challenger_defeat:
    mov rdi, buffer_out
    call message_defeat
    jmp finalize_round

match_draw:
    mov rdi, buffer_out
    call message_draw
    jmp finalize_round

finalize_round:
    mov rsi, buffer_out
    call transmit_output
    jmp terminate_session

terminate_session:
    mov rax, SYS_CLOSE
    mov rdi, [game_socket]
    syscall
    jmp accept_cycle

verify_host_blackjack:
    cmp qword [host_pts], 20
    je match_draw
    jmp challenger_victory

draw_card:
    push rbx
    push rcx
    push rdx

    mov rbx, [deck_pointer]
    movzx rax, byte [shuffled_deck + rbx]
    inc [deck_pointer]

    push rax
    push rdx
    xor rdx, rdx
    mov rbx, 4
    div rbx
    mov bl, [face_symbols + rax]
    pop rdx

    cmp rdi, 0
    je .store_challenger
    jmp .store_host

.store_challenger:
    mov rdx, [challenger_count]
    mov [challenger_cards + rdx], bl
    inc [challenger_count]
    jmp .store_complete
.store_host:
    mov rdx, [host_count]
    mov [host_cards + rdx], bl
    inc [host_count]
.store_complete:
    pop rax

    movzx rcx, byte [card_strength + rax]

    cmp rdi, 0
    je .update_challenger
    jmp .update_host
.update_challenger:
    add [challenger_pts], rcx
    jmp .complete
.update_host:
    add [host_pts], rcx
.complete:
    pop rdx
    pop rcx
    pop rbx
    ret

shuffle_cards:
    mov rcx, 51
.shuffle_loop:
    push rcx
    call generate_random
    xor rdx, rdx
    mov rbx, 52
    div rbx
    pop rcx
    mov al, [shuffled_deck + rcx]
    mov ah, [shuffled_deck + rdx]
    mov [shuffled_deck + rcx], ah
    mov [shuffled_deck + rdx], al
    loop .shuffle_loop
    ret

generate_random:
    push rbx
    push rcx
    push rdx
    mov rax, [rand_seed]
    mov rbx, 6364136223846793005
    mul rbx
    mov rcx, 1442695040888963407
    add rax, rcx
    mov [rand_seed], rax
    pop rdx
    pop rcx
    pop rbx
    ret

show_card_sequence:
    push rbx
    push rcx
    push rsi

    xor rbx, rbx
.sequence_loop:
    cmp rbx, rcx
    jge .sequence_end

    mov al, [rsi + rbx]
    mov [rdi], al
    inc rdi
    mov byte [rdi], ' '
    inc rdi

    inc rbx
    jmp .sequence_loop
.sequence_end:
    pop rsi
    pop rcx
    pop rbx
    ret

display_hidden_state:
    mov rdi, buffer_out

    mov dword [rdi], 'Host'
    mov dword [rdi+4], ':   '
    add rdi, 8

    mov al, [host_cards]
    mov [rdi], al
    inc rdi
    mov dword [rdi], ' [H]'
    add rdi, 4

    mov byte [rdi], 10
    inc rdi

    mov dword [rdi], 'Play'
    mov dword [rdi+4], 'er: '
    add rdi, 8
    mov rax, [challenger_pts]
    call convert_number
    mov byte [rdi], ' '
    inc rdi

    mov rsi, challenger_cards
    mov rcx, [challenger_count]
    call show_card_sequence

    mov byte [rdi], 10
    inc rdi

    mov dword [rdi], '1-TA'
    mov dword [rdi+4], 'KE 2'
    mov dword [rdi+8], '-HOL'
    mov byte [rdi+12], 'D'
    add rdi, 13

    mov byte [rdi], 10
    inc rdi

    mov byte [rdi], 0

    mov rsi, buffer_out
    call transmit_output
    ret

append_final_details:
    mov byte [rdi], 10
    inc rdi

    mov dword [rdi], 'Play'
    mov dword [rdi+4], 'er: '
    add rdi, 8
    mov rax, [challenger_pts]
    call convert_number
    mov byte [rdi], ' '
    inc rdi
    mov rsi, challenger_cards
    mov rcx, [challenger_count]
    call show_card_sequence

    mov byte [rdi], 10
    inc rdi

    mov dword [rdi], 'Host'
    mov dword [rdi+4], ':   '
    add rdi, 8
    mov rax, [host_pts]
    call convert_number
    mov byte [rdi], ' '
    inc rdi
    mov rsi, host_cards
    mov rcx, [host_count]
    call show_card_sequence

    mov byte [rdi], 10
    inc rdi

    mov byte [rdi], 0
    ret

message_busted:
    mov dword [rdi], 'OVER'
    mov byte [rdi+4], '!'
    add rdi, 5
    jmp append_final_details
message_victory:
    mov dword [rdi], 'WINN'
    mov dword [rdi+4], 'ER!'
    add rdi, 8
    jmp append_final_details
message_defeat:
    mov dword [rdi], 'LOST'
    mov byte [rdi+4], '!'
    add rdi, 5
    jmp append_final_details
message_draw:
    mov dword [rdi], 'DRAW'
    add rdi, 4
    jmp append_final_details

convert_number:
    push rbx
    push rdx
    mov rbx, 10
    xor rdx, rdx
    div rbx
    add al, '0'
    add dl, '0'
    mov [rdi], al
    inc rdi
    mov [rdi], dl
    inc rdi
    pop rdx
    pop rbx
    ret

transmit_output:
    push rdi
    push rax
    push rdx
    push rcx
    mov rdi, rsi
    call measure_text
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, [game_socket]
    syscall
    pop rcx
    pop rdx
    pop rax
    pop rdi
    ret

output_message:
    push rdi
    push rax
    push rdx
    push rcx
    mov rdi, rsi
    call measure_text
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    pop rcx
    pop rdx
    pop rax
    pop rdi
    ret

measure_text:
    xor rax, rax
.scan_loop:
    cmp byte [rdi + rax], 0
    je .scan_done
    inc rax
    jmp .scan_loop
.scan_done:
    ret
