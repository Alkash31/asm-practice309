global _start

section .data
    ; memory:
    input_size equ 4096
    max_n equ 100

    newline db 10
    space db ' '
    minus db '-'

section .bss
    ; memory:
    input_buf resb input_size
    out_buf   resb 16

    arr       resd max_n
    n_value   resd 1

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
    cmp dword [n_value], 10
    jl exit_program
    cmp dword [n_value], 100
    jg exit_program

    ; loops:
    xor ecx, ecx

read_array_loop:
    cmp ecx, [n_value]
    jge print_before_sort

    ; parse:
    call atoi

    ; memory:
    mov [arr + ecx*4], eax

    ; logic:
    inc ecx
    jmp read_array_loop

print_before_sort:
    ; I/O:
    call print_array

selection_sort:
    ; loops:
    xor esi, esi              ; i = 0

outer_loop:
    ; math:
    mov eax, [n_value]
    dec eax

    ; logic:
    cmp esi, eax
    jge print_after_sort

    ; memory:
    mov ebx, esi              ; min_index = i

    ; loops:
    mov edi, esi
    inc edi                   ; j = i + 1

inner_loop:
    ; logic:
    cmp edi, [n_value]
    jge swap_elements

    ; memory:
    mov eax, [arr + edi*4]
    mov edx, [arr + ebx*4]

    ; logic:
    cmp eax, edx
    jge next_j

    ; memory:
    mov ebx, edi              ; min_index = j

next_j:
    ; logic:
    inc edi
    jmp inner_loop

swap_elements:
    ; logic:
    cmp ebx, esi
    je next_i

    ; memory:
    mov eax, [arr + esi*4]
    mov edx, [arr + ebx*4]
    mov [arr + esi*4], edx
    mov [arr + ebx*4], eax

next_i:
    ; logic:
    inc esi
    jmp outer_loop

print_after_sort:
    ; I/O:
    call print_array

print_median:
    ; math:
    mov eax, [n_value]
    dec eax
    shr eax, 1                ; index = (n - 1) / 2

    ; memory:
    mov eax, [arr + eax*4]

    ; I/O:
    call print_int_eax
    call print_newline

exit_program:
    ; I/O:
    mov eax, 1
    xor ebx, ebx
    int 0x80

print_array:
    ; I/O:
    ; друкує arr[0..n-1] в один рядок

    push eax
    push ebx
    push ecx
    push edx
    push esi

    ; loops:
    xor esi, esi

print_array_loop:
    cmp esi, [n_value]
    jge print_array_done

    ; I/O:
    mov eax, [arr + esi*4]
    call print_int_eax

    ; logic:
    inc esi
    cmp esi, [n_value]
    jge print_array_done

    ; I/O:
    mov ecx, space
    mov edx, 1
    call print_text
    jmp print_array_loop

print_array_done:
    call print_newline

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

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