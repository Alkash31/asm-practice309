global _start

section .data
    ; memory:
    input_size equ 256
    text_size equ 201
    pattern_size equ 51

    newline db 10
    minus db '-'

section .bss
    ; memory:
    input_buf   resb input_size
    text_buf    resb text_size
    pattern_buf resb pattern_size
    out_buf     resb 16

    text_len    resd 1
    pattern_len resd 1
    first_pos   resd 1
    count_value resd 1

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
    mov ebx, text_buf
    mov ecx, text_size
    call read_line_to_buffer

    ; parse:
    mov ebx, pattern_buf
    mov ecx, pattern_size
    call read_line_to_buffer

    ; parse:
    mov esi, text_buf
    call strlen
    mov [text_len], eax

    ; parse:
    mov esi, pattern_buf
    call strlen
    mov [pattern_len], eax

    ; logic:
    mov dword [first_pos], -1
    mov dword [count_value], 0

    cmp dword [pattern_len], 0
    jne check_lengths

    ; I/O:
    mov eax, 0
    call print_int_eax
    call print_newline

    mov eax, 0
    call print_int_eax
    call print_newline
    jmp exit_program

check_lengths:
    ; logic:
    mov eax, [pattern_len]
    cmp eax, [text_len]
    jg print_result

    ; loops:
    xor esi, esi              ; i = 0

search_loop:
    ; logic:
    mov eax, [text_len]
    sub eax, [pattern_len]
    cmp esi, eax
    jg print_result

    ; memory:
    mov ebx, esi              ; запам'ятати i
    xor edi, edi              ; j = 0

compare_loop:
    ; loops:
    cmp edi, [pattern_len]
    jge match_found

    ; memory:
    mov al, [text_buf + ebx + edi]
    mov dl, [pattern_buf + edi]

    ; logic:
    cmp al, dl
    jne no_match

    ; logic:
    inc edi
    jmp compare_loop

match_found:
    ; logic:
    cmp dword [first_pos], -1
    jne count_match
    mov [first_pos], esi

count_match:
    ; math:
    inc dword [count_value]

    ; logic:
    add esi, [pattern_len]    ; без перекриття
    jmp search_loop

no_match:
    ; logic:
    inc esi
    jmp search_loop

print_result:
    ; I/O:
    mov eax, [first_pos]
    call print_int_eax
    call print_newline

    mov eax, [count_value]
    call print_int_eax
    call print_newline

exit_program:
    ; I/O:
    mov eax, 1
    xor ebx, ebx
    int 0x80

read_line_to_buffer:
    ; parse:
    ; ESI = позиція у input_buf
    ; EDI = кінець input_buf
    ; EBX = буфер призначення
    ; ECX = максимальний розмір буфера

    push eax
    push edx
    push ebx
    push ecx

    ; memory:
    xor edx, edx              ; index = 0

copy_line_loop:
    ; loops:
    cmp esi, edi
    jae finish_copy_line

    ; logic:
    cmp edx, ecx
    jae skip_to_line_end

    mov al, [esi]
    cmp al, 10
    je finish_copy_line
    cmp al, 13
    je finish_copy_line

    ; memory:
    mov [ebx + edx], al
    inc edx
    inc esi
    jmp copy_line_loop

skip_to_line_end:
    ; loops:
    cmp esi, edi
    jae finish_copy_line
    mov al, [esi]
    cmp al, 10
    je finish_copy_line
    inc esi
    jmp skip_to_line_end

finish_copy_line:
    ; logic:
    cmp edx, ecx
    jb write_zero
    dec edx

write_zero:
    ; memory:
    mov byte [ebx + edx], 0

    ; logic:
    cmp esi, edi
    jae read_line_done

    mov al, [esi]
    cmp al, 13
    jne check_lf_after
    inc esi

check_lf_after:
    cmp esi, edi
    jae read_line_done

    mov al, [esi]
    cmp al, 10
    jne read_line_done
    inc esi

read_line_done:
    pop ecx
    pop ebx
    pop edx
    pop eax
    ret

strlen:
    ; parse:
    ; ESI = адреса рядка
    ; EAX = довжина

    ; math:
    xor eax, eax

strlen_loop:
    ; loops:
    cmp byte [esi + eax], 0
    je strlen_done
    inc eax
    jmp strlen_loop

strlen_done:
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