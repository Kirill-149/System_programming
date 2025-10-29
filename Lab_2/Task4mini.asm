format ELF64
_start:
mov rax,5277616985
mov rbx,10
xor rcx,rcx
l1:xor rdx,rdx
div rbx
add rcx,rdx
test rax,rax
jnz l1
mov rax,rcx
mov rbx,10
mov rdi,buf+15
mov byte[rdi],10
l2:dec rdi
xor rdx,rdx
div rbx
add dl,48
mov [rdi],dl
test rax,rax
jnz l2
mov rsi,rdi
mov rdx,buf+16
sub rdx,rdi
mov eax,1
mov edi,1
syscall
mov eax,60
xor edi,edi
syscall
buf:rb 16
