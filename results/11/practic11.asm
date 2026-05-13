global _start

section .data
    ; memory:
    input_size equ 32

section .bss
    ; memory:
    input_buf resb input_size
    line_buf  resb 64
    h_value   resd 1

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
    mov [h_value], eax

    ; logic:
    cmp dword [h_value], 5
    jl exit_program
    cmp dword [h_value], 25
    jg exit_program

    ; loops:
    xor esi, esi              ; esi = i

row_loop:
    ; logic:
    cmp esi, [h_value]
    jge exit_program

    ; memory:
    mov edi, line_buf

    ; math:
    mov eax, [h_value]
    sub eax, esi
    dec eax                   ; spaces = h - i - 1
    mov ebx, eax

space_loop:
    ; loops:
    cmp ebx, 0
    jle prepare_stars

    ; memory:
    mov byte [edi], ' '
    inc edi
    dec ebx
    jmp space_loop

prepare_stars:
    ; math:
    mov eax, esi
    shl eax, 1
    inc eax                   ; stars = 2*i + 1
    mov ebx, eax

star_loop:
    ; loops:
    cmp ebx, 0
    jle finish_line

    ; memory:
    mov byte [edi], '*'
    inc edi
    dec ebx
    jmp star_loop

finish_line:
    ; memory:
    mov byte [edi], 10
    inc edi

    ; math:
    mov edx, edi
    sub edx, line_buf         ; length = edi - line_buf

    ; I/O:
    mov ecx, line_buf
    call print_line

    ; logic:
    inc esi
    jmp row_loop

exit_program:
    ; I/O:
    mov eax, 1
    xor ebx, ebx
    int 0x80

print_line:
    ; I/O:
    ; ECX = адреса рядка
    ; EDX = довжина рядка

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

atoi:
    ; parse:
    ; ESI = поточна позиція
    ; EDI = кінець буфера
    ; EAX = результат

    ; math:
    xor eax, eax

skip_spaces:
    ; loops:
    cmp esi, edi
    jae atoi_done

    mov dl, [esi]
    cmp dl, ' '
    je next_char
    cmp dl, 9
    je next_char
    cmp dl, 10
    je next_char
    cmp dl, 13
    je next_char
    jmp parse_digits

next_char:
    ; logic:
    inc esi
    jmp skip_spaces

parse_digits:
    ; loops:
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
    jmp parse_digits

atoi_done:
    ret