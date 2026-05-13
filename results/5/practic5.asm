global _start

section .data
    ; memory:
    input_size equ 64
    newline db 10

section .bss
    ; memory:
    input_buf  resb input_size
    output_buf resb 16
    sum_value  resd 1
    len_value  resd 1

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
    jle end

    ; parse:
    mov esi, input_buf
    mov edi, input_buf
    add edi, eax
    call atoi                 ; EAX = x

    ; memory:
    mov dword [sum_value], 0
    mov dword [len_value], 0
    mov ebx, eax              ; EBX = поточне x

    ; loops:
while_x_gt_0:
    ; logic:
    cmp ebx, 0
    jle print_sum

    ; math:
    mov eax, ebx
    xor edx, edx              ; EDX:EAX / 10
    mov ecx, 10
    div ecx                   ; EAX = x / 10, EDX = x % 10

    add [sum_value], edx      ; sumDigits += digit
    inc dword [len_value]     ; len++

    ; logic:
    mov ebx, eax
    jmp while_x_gt_0

print_sum:
    ; I/O:
    mov eax, [sum_value]
    call itoa
    call print_text
    call print_newline

print_len:
    ; I/O:
    mov eax, [len_value]
    call itoa
    call print_text
    call print_newline

end:
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
    ;   EAX = unsigned число

    ; math:
    xor eax, eax

    ; loops:
atoi_skip_spaces:
    cmp esi, edi
    jae atoi_done

    mov dl, [esi]
    cmp dl, ' '
    je atoi_skip_next
    cmp dl, 9
    je atoi_skip_next
    cmp dl, 10
    je atoi_skip_next
    cmp dl, 13
    je atoi_skip_next
    jmp atoi_digits

atoi_skip_next:
    inc esi
    jmp atoi_skip_spaces

atoi_digits:
    cmp esi, edi
    jae atoi_done

    mov dl, [esi]
    cmp dl, '0'
    jb atoi_done
    cmp dl, '9'
    ja atoi_done

    ; math:
    imul eax, eax, 10
    movzx edx, dl
    sub edx, '0'
    add eax, edx

    ; logic:
    inc esi
    jmp atoi_digits

atoi_done:
    ret

itoa:
    ; parse:
    ; Вхід:
    ;   EAX = unsigned число
    ; Вихід:
    ;   ECX = адреса рядка
    ;   EDX = довжина рядка

    ; memory:
    mov edi, output_buf + 16
    xor ebx, ebx

    ; logic:
    cmp eax, 0
    jne itoa_convert

    dec edi
    mov byte [edi], '0'
    mov ecx, edi
    mov edx, 1
    ret

    ; loops:
itoa_convert:
itoa_loop:
    ; math:
    xor edx, edx
    mov esi, 10
    div esi

    add dl, '0'

    ; memory:
    dec edi
    mov [edi], dl
    inc ebx

    ; logic:
    test eax, eax
    jnz itoa_loop

    mov ecx, edi
    mov edx, ebx
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