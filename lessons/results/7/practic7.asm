global _start

section .data
    ; memory:
    input_size equ 64
    newline db 10
    space db ' '
    minus db '-'

section .bss
    ; memory:
    input_buf  resb input_size
    output_buf resb 16
    arr        resd 50
    n_value    resd 1
    min_value  resd 1
    max_value  resd 1
    min_index  resd 1
    max_index  resd 1

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
    call atoi
    mov [n_value], eax

    ; logic:
    cmp dword [n_value], 5
    jl end
    cmp dword [n_value], 50
    jg end

    ; loops:
    xor ecx, ecx

fill_loop:
    cmp ecx, [n_value]
    jge init_min_max

    ; math:
    ; a[i] = i*i - 3*i + 7
    mov eax, ecx
    imul eax, ecx
    mov ebx, ecx
    imul ebx, 3
    sub eax, ebx
    add eax, 7

    ; memory:
    mov [arr + ecx*4], eax

    ; logic:
    inc ecx
    jmp fill_loop

init_min_max:
    ; memory:
    mov eax, [arr]
    mov [min_value], eax
    mov [max_value], eax
    mov dword [min_index], 0
    mov dword [max_index], 0

    ; loops:
    xor esi, esi

print_array_loop:
    cmp esi, [n_value]
    jge print_array_end

    ; I/O:
    mov eax, [arr + esi*4]
    call print_int_eax

    ; logic:
    inc esi
    cmp esi, [n_value]
    jge print_array_end

    ; I/O:
    mov ecx, space
    mov edx, 1
    call print_text

    ; logic:
    jmp print_array_loop

print_array_end:
    call print_newline

    ; loops:
    xor ecx, ecx

scan_loop:
    cmp ecx, [n_value]
    jge print_min

    ; memory:
    mov eax, [arr + ecx*4]

    ; logic:
    cmp eax, [min_value]
    jge check_max
    mov [min_value], eax
    mov [min_index], ecx

check_max:
    cmp eax, [max_value]
    jle next_scan
    mov [max_value], eax
    mov [max_index], ecx

next_scan:
    inc ecx
    jmp scan_loop

print_min:
    ; I/O:
    mov eax, [min_value]
    call print_int_eax
    mov ecx, space
    mov edx, 1
    call print_text
    mov eax, [min_index]
    call print_int_eax
    call print_newline

print_max:
    ; I/O:
    mov eax, [max_value]
    call print_int_eax
    mov ecx, space
    mov edx, 1
    call print_text
    mov eax, [max_index]
    call print_int_eax
    call print_newline

end:
    ; I/O:
    mov eax, 1
    xor ebx, ebx
    int 0x80

atoi:
    ; parse:
    ; Вхід:
    ; ESI = поточна позиція
    ; EDI = кінець буфера
    ; Вихід:
    ; EAX = число

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

print_text:
    ; I/O:
    ; Вхід:
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
    ; Вхід:
    ; EAX = signed int

    push ebx
    push ecx
    push edx
    push edi

    ; logic:
    cmp eax, 0
    jne print_int_check_negative

    mov byte [output_buf], '0'
    mov ecx, output_buf
    mov edx, 1
    call print_text
    jmp print_int_done

print_int_check_negative:
    cmp eax, 0
    jge print_int_convert

    mov ecx, minus
    mov edx, 1
    call print_text
    neg eax

print_int_convert:
    ; memory:
    mov edi, output_buf + 16
    xor ebx, ebx

    ; loops:
print_int_loop:
    ; math:
    xor edx, edx
    mov ecx, 10
    div ecx

    add dl, '0'
    dec edi
    mov [edi], dl
    inc ebx

    ; logic:
    test eax, eax
    jnz print_int_loop

    ; I/O:
    mov ecx, edi
    mov edx, ebx
    call print_text

print_int_done:
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret