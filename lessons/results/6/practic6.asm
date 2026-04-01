global _start

section .data
    input_buf_size equ 128

    signed_prefix db 'SIGNED: '
    signed_prefix_len equ $ - signed_prefix

    unsigned_prefix db 'UNSIGNED: '
    unsigned_prefix_len equ $ - unsigned_prefix

    max_signed_prefix db 'max_signed(a,b) = '
    max_signed_prefix_len equ $ - max_signed_prefix

    max_unsigned_prefix db 'max_unsigned(a,b) = '
    max_unsigned_prefix_len equ $ - max_unsigned_prefix

    rel_lt db 'a < b'
    rel_lt_len equ $ - rel_lt

    rel_eq db 'a = b'
    rel_eq_len equ $ - rel_eq

    rel_gt db 'a > b'
    rel_gt_len equ $ - rel_gt

    newline db 10
    minus_char db '-'

section .bss
    input_buf resb input_buf_size
    out_buf   resb 16
    a_value   resd 1
    b_value   resd 1

section .text

_start:
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, input_buf_size
    int 0x80

    cmp eax, 0
    jle exit_program

    mov esi, input_buf
    mov edi, input_buf
    add edi, eax

    call parse_int32
    mov [a_value], eax

    call parse_int32
    mov [b_value], eax

    mov ecx, signed_prefix
    mov edx, signed_prefix_len
    call print_text

    mov eax, [a_value]
    mov ebx, [b_value]
    call cmp_signed
    call print_text
    call print_newline

    mov ecx, unsigned_prefix
    mov edx, unsigned_prefix_len
    call print_text

    mov eax, [a_value]
    mov ebx, [b_value]
    call cmp_unsigned
    call print_text
    call print_newline

    mov ecx, max_signed_prefix
    mov edx, max_signed_prefix_len
    call print_text

    mov eax, [a_value]
    mov ebx, [b_value]
    call max_signed
    call print_signed_eax
    call print_newline

    mov ecx, max_unsigned_prefix
    mov edx, max_unsigned_prefix_len
    call print_text

    mov eax, [a_value]
    mov ebx, [b_value]
    call max_unsigned
    call print_unsigned_eax
    call print_newline

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80

parse_int32:
    ; parse:
    ; ESI = поточна позиція
    ; EDI = кінець буфера
    ; EAX = результат
    
.skip_spaces:
    cmp esi, edi
    jae .return_zero

    mov dl, [esi]
    cmp dl, ' '
    je .advance_space
    cmp dl, 10
    je .advance_space
    cmp dl, 13
    je .advance_space
    cmp dl, 9
    je .advance_space
    jmp .check_sign

.advance_space:
    inc esi
    jmp .skip_spaces

.check_sign:
    xor ebx, ebx
    cmp esi, edi
    jae .return_zero

    mov dl, [esi]
    cmp dl, '-'
    jne .check_plus
    mov bl, 1
    inc esi
    jmp .parse_digits

.check_plus:
    cmp dl, '+'
    jne .parse_digits
    inc esi

.parse_digits:
    xor eax, eax

.digit_loop:
    cmp esi, edi
    jae .apply_sign

    mov dl, [esi]
    cmp dl, '0'
    jb .apply_sign
    cmp dl, '9'
    ja .apply_sign

    imul eax, eax, 10
    movzx edx, dl
    sub edx, '0'
    add eax, edx

    inc esi
    jmp .digit_loop

.apply_sign:
    test bl, bl
    jz .done
    neg eax

.done:
    ret

.return_zero:
    xor eax, eax
    ret

cmp_signed:
    ; EAX = a, EBX = b
    ; ECX = адреса тексту, EDX = довжина

    cmp eax, ebx
    jl .signed_less
    jg .signed_greater
    je .signed_equal

.signed_less:
    mov ecx, rel_lt
    mov edx, rel_lt_len
    ret

.signed_equal:
    mov ecx, rel_eq
    mov edx, rel_eq_len
    ret

.signed_greater:
    mov ecx, rel_gt
    mov edx, rel_gt_len
    ret

cmp_unsigned:
    ; EAX = a, EBX = b
    ; ECX = адреса тексту, EDX = довжина

    cmp eax, ebx
    jb .unsigned_less
    ja .unsigned_greater
    je .unsigned_equal

.unsigned_less:
    mov ecx, rel_lt
    mov edx, rel_lt_len
    ret

.unsigned_equal:
    mov ecx, rel_eq
    mov edx, rel_eq_len
    ret

.unsigned_greater:
    mov ecx, rel_gt
    mov edx, rel_gt_len
    ret

max_signed:
    ; EAX = a, EBX = b
    ; EAX = max_signed(a,b)

    cmp eax, ebx
    jl .take_b_signed
    ret

.take_b_signed:
    mov eax, ebx
    ret

max_unsigned:
    ; EAX = a, EBX = b
    ; EAX = max_unsigned(a,b)

    cmp eax, ebx
    jb .take_b_unsigned
    ret

.take_b_unsigned:
    mov eax, ebx
    ret

print_text:
    ; ECX = адреса
    ; EDX = довжина

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

print_newline:
    mov ecx, newline
    mov edx, 1
    call print_text
    ret

print_signed_eax:

    push ebx
    push ecx
    push edx
    push esi
    push edi

    cmp eax, 0
    jne .check_negative

    mov byte [out_buf], '0'
    mov ecx, out_buf
    mov edx, 1
    call print_text
    jmp .done

.check_negative:
    cmp eax, 0
    jge .positive_value

    mov ecx, minus_char
    mov edx, 1
    call print_text

    neg eax

.positive_value:
    call print_unsigned_eax

.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

print_unsigned_eax:

    push eax
    push ebx
    push ecx
    push edx
    push edi

    mov edi, out_buf + 16
    xor ecx, ecx

    cmp eax, 0
    jne .convert

    dec edi
    mov byte [edi], '0'
    mov ecx, 1
    jmp .print_result

.convert:
.convert_loop:
    
    xor edx, edx
    mov ebx, 10
    div ebx

    add dl, '0'

    dec edi
    mov [edi], dl
    inc ecx

    test eax, eax
    jnz .convert_loop

.print_result:
    mov edx, ecx
    mov ecx, edi
    call print_text

    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret