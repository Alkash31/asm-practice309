global _start

section .data
    ; memory:
    input_size equ 64
    newline db 10
    minus db '-'

    calls_msg db 'calls = '
    calls_msg_len equ $ - calls_msg

section .bss
    ; memory:
    input_buf resb input_size
    out_buf   resb 16

    n_value   resd 1
    calls     resd 1

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
    cmp dword [n_value], 0
    jl exit_program
    cmp dword [n_value], 12
    jg exit_program

    ; memory:
    mov dword [calls], 0

    ; math:
    mov eax, [n_value]
    call fact

    ; I/O:
    call print_int_eax
    call print_newline

    mov ecx, calls_msg
    mov edx, calls_msg_len
    call print_text

    mov eax, [calls]
    call print_int_eax
    call print_newline

exit_program:
    ; I/O:
    mov eax, 1
    xor ebx, ebx
    int 0x80

fact:
    ; math:
    ; Вхід: EAX = n
    ; Вихід: EAX = fact(n)

    ; memory:
    push ebp
    mov ebp, esp
    push ebx

    ; logic:
    inc dword [calls]

    cmp eax, 1
    jle fact_base

    ; memory:
    mov ebx, eax
    dec eax
    call fact

    ; math:
    imul eax, ebx
    jmp fact_done

fact_base:
    ; math:
    mov eax, 1

fact_done:
    ; memory:
    pop ebx
    mov esp, ebp
    pop ebp
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