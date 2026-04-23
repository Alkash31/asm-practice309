global _start

section .data
    ; memory:
    input_size equ 64

    newline    db 10
    colon_sp   db ': '
    colon_sp_len equ $ - colon_sp
    space      db ' '
    lparen     db '('
    rparen     db ')'
    minus      db '-'
    hash_char  db '#'

section .bss
    ; memory:
    input_buf  resb input_size
    out_buf    resb 16
    freq       resd 10
    n_value    resd 1
    seed_value resd 1

section .text

_start:
    ; I/O:
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, input_size
    int 0x80

    ; logic:
    cmp eax, 0
    jle exit_program

    ; parse:
    mov esi, input_buf
    mov edi, input_buf
    add edi, eax
    call atoi
    mov [n_value], eax

    ; logic:
    cmp dword [n_value], 100
    jl exit_program
    cmp dword [n_value], 1000
    jg exit_program

    ; memory:
    xor ecx, ecx

init_freq_loop:
    ; loops:
    cmp ecx, 10
    jge init_seed

    mov dword [freq + ecx*4], 0
    inc ecx
    jmp init_freq_loop

init_seed:
    ; memory:
    mov dword [seed_value], 1

    ; loops:
    xor ecx, ecx

generate_loop:
    cmp ecx, [n_value]
    jge print_histogram

    ; math:
    ; x = (1103515245*x + 12345) mod 2^31
    mov eax, [seed_value]
    imul eax, eax, 1103515245
    add eax, 12345
    and eax, 0x7fffffff
    mov [seed_value], eax

    ; math:
    ; digit = x % 10
    xor edx, edx
    mov ebx, 10
    div ebx

    ; memory:
    inc dword [freq + edx*4]

    ; logic:
    inc ecx
    jmp generate_loop

print_histogram:
    ; loops:
    xor esi, esi

print_line_loop:
    cmp esi, 10
    jge exit_program

    ; I/O:
    mov eax, esi
    call print_int_eax

    mov ecx, colon_sp
    mov edx, colon_sp_len
    call print_text

    ; memory:
    mov ebx, [freq + esi*4]

    ; loops:
    xor edi, edi

print_hashes_loop:
    cmp edi, ebx
    jge print_count_part

    ; I/O:
    mov ecx, hash_char
    mov edx, 1
    call print_text

    ; logic:
    inc edi
    jmp print_hashes_loop

print_count_part:
    ; I/O:
    mov ecx, space
    mov edx, 1
    call print_text

    mov ecx, lparen
    mov edx, 1
    call print_text

    mov eax, [freq + esi*4]
    call print_int_eax

    mov ecx, rparen
    mov edx, 1
    call print_text

    call print_newline

    ; logic:
    inc esi
    jmp print_line_loop

exit_program:
    ; I/O:
    mov eax, 1
    xor ebx, ebx
    int 0x80

atoi:
    ; parse:
    ; Вхід:
    ;   ESI = поточна позиція
    ;   EDI = кінець буфера
    ; Вихід:
    ;   EAX = signed int

    ; loops:
atoi_skip_spaces:
    cmp esi, edi
    jae atoi_zero

    mov dl, [esi]
    cmp dl, ' '
    je atoi_skip_next
    cmp dl, 9
    je atoi_skip_next
    cmp dl, 10
    je atoi_skip_next
    cmp dl, 13
    je atoi_skip_next
    jmp atoi_check_sign

atoi_skip_next:
    inc esi
    jmp atoi_skip_spaces

atoi_check_sign:
    ; logic:
    xor ebx, ebx

    cmp byte [esi], '-'
    jne atoi_check_plus
    mov bl, 1
    inc esi
    jmp atoi_digits

atoi_check_plus:
    cmp byte [esi], '+'
    jne atoi_digits
    inc esi

atoi_digits:
    ; math:
    xor eax, eax

atoi_digit_loop:
    ; loops:
    cmp esi, edi
    jae atoi_apply_sign

    mov dl, [esi]
    cmp dl, '0'
    jb atoi_apply_sign
    cmp dl, '9'
    ja atoi_apply_sign

    imul eax, eax, 10
    movzx edx, dl
    sub edx, '0'
    add eax, edx

    inc esi
    jmp atoi_digit_loop

atoi_apply_sign:
    ; logic:
    test bl, bl
    jz atoi_done
    neg eax

atoi_done:
    ret

atoi_zero:
    xor eax, eax
    ret

print_text:
    ; I/O:
    ; Вхід:
    ;   ECX = адреса
    ;   EDX = довжина

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
    ; I/O:
    mov ecx, newline
    mov edx, 1
    call print_text
    ret

print_int_eax:
    ; I/O:
    ; Вхід:
    ;   EAX = signed int

    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; logic:
    cmp eax, 0
    jne print_check_negative

    mov byte [out_buf], '0'
    mov ecx, out_buf
    mov edx, 1
    call print_text
    jmp print_done

print_check_negative:
    cmp eax, 0
    jge print_convert

    mov ecx, minus
    mov edx, 1
    call print_text
    neg eax

print_convert:
    ; memory:
    mov edi, out_buf + 16
    xor ebx, ebx

print_loop:
    ; loops:
    ; math:
    xor edx, edx
    mov ecx, 10
    div ecx

    add dl, '0'

    ; memory:
    dec edi
    mov [edi], dl
    inc ebx

    ; logic:
    test eax, eax
    jnz print_loop

    ; I/O:
    mov ecx, edi
    mov edx, ebx
    call print_text

print_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret