global _start

section .data
    ; memory:
    input_size equ 64

    p_pos equ 1
    q_pos equ 3
    r_pos equ 2

    newline db 10
    space db ' '
    zero db '0'
    one  db '1'
    minus db '-'

section .bss
    ; memory:
    input_buf resb input_size
    out_buf   resb 16

    x_value   resd 1

section .text

_start:
    ; I/O:
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, input_size
    int 0x80

    ; parse:
    mov esi, input_buf
    mov edi, input_buf
    add edi, eax
    call atoi
    mov [x_value], eax

    ; 1. binary
    mov eax, [x_value]
    call print_binary
    call newline_print

    ; 2. popcount
    mov eax, [x_value]
    call popcount
    call print_int
    call newline_print

    ; 3. bit operations
    mov eax, [x_value]

    ; set p
    mov ebx, 1
    shl ebx, p_pos
    or eax, ebx

    ; set q
    mov ebx, 1
    shl ebx, q_pos
    or eax, ebx

    ; clear r
    mov ebx, 1
    shl ebx, r_pos
    not ebx
    and eax, ebx

    call print_int
    call newline_print

exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

print_binary:
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov ebx, eax
    mov esi, 31

.loop:
    mov eax, ebx
    mov ecx, esi
    shr eax, cl
    and eax, 1

    cmp eax, 0
    je .zero

    mov ecx, one
    mov edx, 1
    call print_text
    jmp .next

.zero:
    mov ecx, zero
    mov edx, 1
    call print_text

.next:
    ; пробіл кожні 4 біти
    cmp esi, 0
    je .skip

    mov eax, esi
    and eax, 3
    cmp eax, 0
    jne .skip

    mov ecx, space
    mov edx, 1
    call print_text

.skip:
    dec esi
    cmp esi, -1
    jne .loop

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

popcount:
    push ebx
    push ecx
    push edx

    mov ebx, eax
    xor eax, eax
    mov ecx, 32

.loop:
    mov edx, ebx
    and edx, 1
    add eax, edx
    shr ebx, 1
    loop .loop

    pop edx
    pop ecx
    pop ebx
    ret

print_int:
    push ebx
    push ecx
    push edx
    push esi
    push edi

    cmp eax, 0
    jne .check

    mov byte [out_buf], '0'
    mov ecx, out_buf
    mov edx, 1
    call print_text
    jmp .done

.check:
    cmp eax, 0
    jge .convert

    mov ecx, minus
    mov edx, 1
    call print_text
    neg eax

.convert:
    mov edi, out_buf + 16
    xor ebx, ebx

.loop:
    xor edx, edx
    mov ecx, 10
    div ecx

    add dl, '0'
    dec edi
    mov [edi], dl
    inc ebx

    test eax, eax
    jnz .loop

    mov ecx, edi
    mov edx, ebx
    call print_text

.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

print_text:
    push eax
    push ebx
    push ecx
    push edx

    mov eax, 4
    mov ebx, 1
    int 0x80

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

newline_print:
    mov ecx, newline
    mov edx, 1
    call print_text
    ret

atoi:
    xor eax, eax

.skip:
    cmp esi, edi
    jae .done

    mov dl, [esi]
    cmp dl, ' '
    je .next
    cmp dl, 10
    je .next
    jmp .parse

.next:
    inc esi
    jmp .skip

.parse:
    mov dl, [esi]
    cmp dl, '0'
    jb .done
    cmp dl, '9'
    ja .done

    imul eax, eax, 10
    sub dl, '0'
    add eax, edx

    inc esi
    jmp .parse

.done:
    ret