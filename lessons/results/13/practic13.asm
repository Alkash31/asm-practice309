global _start

section .data
    ; memory:
    input_size equ 4096
    max_n equ 200

    newline db 10
    space db ' '
    minus db '-'

    yes_msg db 'PALINDROME: YES'
    yes_len equ $ - yes_msg

    no_msg db 'PALINDROME: NO'
    no_len equ $ - no_msg

section .bss
    ; memory:
    input_buf resb input_size
    out_buf   resb 16

    arr       resd max_n
    copy_arr  resd max_n
    rev_arr   resd max_n

    n_value   resd 1
    is_pal    resd 1

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
    cmp dword [n_value], 5
    jl exit_program
    cmp dword [n_value], 200
    jg exit_program

    ; loops:
    xor ecx, ecx

read_array_loop:
    cmp ecx, [n_value]
    jge copy_array

    ; parse:
    call atoi

    ; memory:
    mov [arr + ecx*4], eax

    ; logic:
    inc ecx
    jmp read_array_loop

copy_array:
    ; memory:
    xor ecx, ecx

copy_loop:
    ; loops:
    cmp ecx, [n_value]
    jge build_reverse

    ; memory:
    mov eax, [arr + ecx*4]
    mov [copy_arr + ecx*4], eax

    ; logic:
    inc ecx
    jmp copy_loop

build_reverse:
    ; loops:
    xor ecx, ecx

reverse_loop:
    cmp ecx, [n_value]
    jge check_palindrome

    ; math:
    mov edx, [n_value]
    dec edx
    sub edx, ecx

    ; memory:
    mov eax, [copy_arr + edx*4]
    mov [rev_arr + ecx*4], eax

    ; logic:
    inc ecx
    jmp reverse_loop

check_palindrome:
    ; memory:
    mov dword [is_pal], 1

    ; loops:
    xor ecx, ecx

pal_loop:
    ; math:
    mov edx, [n_value]
    shr edx, 1

    ; logic:
    cmp ecx, edx
    jge print_original

    ; math:
    mov ebx, [n_value]
    dec ebx
    sub ebx, ecx

    ; memory:
    mov eax, [arr + ecx*4]
    mov edx, [arr + ebx*4]

    ; logic:
    cmp eax, edx
    je pal_next

    ; memory:
    mov dword [is_pal], 0
    jmp print_original

pal_next:
    inc ecx
    jmp pal_loop

print_original:
    ; loops:
    xor esi, esi

print_original_loop:
    cmp esi, [n_value]
    jge print_original_done

    ; I/O:
    mov eax, [arr + esi*4]
    call print_int_eax

    ; logic:
    inc esi
    cmp esi, [n_value]
    jge print_original_done

    ; I/O:
    mov ecx, space
    mov edx, 1
    call print_text
    jmp print_original_loop

print_original_done:
    call print_newline

print_reverse:
    ; loops:
    xor esi, esi

print_reverse_loop:
    cmp esi, [n_value]
    jge print_reverse_done

    ; I/O:
    mov eax, [rev_arr + esi*4]
    call print_int_eax

    ; logic:
    inc esi
    cmp esi, [n_value]
    jge print_reverse_done

    ; I/O:
    mov ecx, space
    mov edx, 1
    call print_text
    jmp print_reverse_loop

print_reverse_done:
    call print_newline

print_palindrome:
    ; logic:
    cmp dword [is_pal], 1
    jne print_no

    ; I/O:
    mov ecx, yes_msg
    mov edx, yes_len
    call print_text
    call print_newline
    jmp exit_program

print_no:
    ; I/O:
    mov ecx, no_msg
    mov edx, no_len
    call print_text
    call print_newline

exit_program:
    ; I/O:
    mov eax, 1
    xor ebx, ebx
    int 0x80

atoi:
    ; parse:
    ; ESI = поточна позиція
    ; EDI = кінець буфера
    ; EAX = signed int

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

    ; math:
    imul eax, eax, 10
    movzx edx, dl
    sub edx, '0'
    add eax, edx

    ; logic:
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
    ; I/O:
    mov ecx, newline
    mov edx, 1
    call print_text
    ret

print_int_eax:
    ; I/O:
    ; EAX = signed int

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

    ; I/O:
    mov ecx, minus
    mov edx, 1
    call print_text

    ; math:
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