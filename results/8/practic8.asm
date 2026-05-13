global _start

section .data
    ; memory:
    input_size equ 4096
    max_n equ 100

    newline db 10
    space   db ' '
    minus   db '-'

section .bss
    ; memory:
    input_buf    resb input_size
    arr          resd max_n
    indices      resd max_n
    out_buf      resb 16

    n_value      resd 1
    target_value resd 1
    first_index  resd 1
    count_value  resd 1

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

    ; memory:
    mov esi, input_buf
    mov edi, input_buf
    add edi, eax

    ; parse:
    call atoi
    mov [n_value], eax

    ; logic:
    cmp dword [n_value], 10
    jl exit_program
    cmp dword [n_value], 100
    jg exit_program

    ; memory:
    mov dword [first_index], -1
    mov dword [count_value], 0

    ; loops:
    xor ecx, ecx

read_array_loop:
    cmp ecx, [n_value]
    jge read_target

    ; parse:
    call atoi
    mov [arr + ecx*4], eax

    ; logic:
    inc ecx
    jmp read_array_loop

read_target:
    ; parse:
    call atoi
    mov [target_value], eax

    ; loops:
    xor esi, esi

search_loop:
    cmp esi, [n_value]
    jge print_first_index

    ; memory:
    mov eax, [arr + esi*4]

    ; logic:
    cmp eax, [target_value]
    jne next_item

    cmp dword [first_index], -1
    jne store_index
    mov [first_index], esi

store_index:
    ; memory:
    mov edx, [count_value]
    mov [indices + edx*4], esi

    ; logic:
    inc dword [count_value]

next_item:
    inc esi
    jmp search_loop

print_first_index:
    ; I/O:
    mov eax, [first_index]
    call print_int_eax
    call print_newline

print_count:
    ; I/O:
    mov eax, [count_value]
    call print_int_eax
    call print_newline

print_indices:
    ; logic:
    cmp dword [count_value], 0
    je print_empty_line

    ; loops:
    xor esi, esi

print_indices_loop:
    cmp esi, [count_value]
    jge print_indices_done

    ; I/O:
    mov eax, [indices + esi*4]
    call print_int_eax

    ; logic:
    inc esi
    cmp esi, [count_value]
    jge print_indices_done

    ; I/O:
    mov ecx, space
    mov edx, 1
    call print_text
    jmp print_indices_loop

print_indices_done:
    call print_newline
    jmp exit_program

print_empty_line:
    call print_newline

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

    ; loops:
atoi_digit_loop:
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

    ; loops:
print_loop:
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