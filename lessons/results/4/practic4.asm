global _start

section .data
    ; memory:
    input_size equ 64
    newline db 10

section .bss
    ; memory:
    input_buf  resb input_size
    output_buf resb 12       

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
    mov edi, eax
    add edi, input_buf
    call parse_int32        

    ; parse:
    call print_eax_number

    ; I/O:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

end:
    ; I/O:
    mov eax, 1
    xor ebx, ebx
    int 0x80

parse_int32:
    ; parse:

    ; loops:
.skip_spaces:
    cmp esi, edi
    jae .zero

    mov dl, [esi]
    cmp dl, ' '
    je .next
    cmp dl, 10
    je .next
    cmp dl, 13
    je .next
    cmp dl, 9
    je .next
    jmp .sign

.next:
    inc esi
    jmp .skip_spaces

.sign:
    ; logic:
    xor ebx, ebx

    mov dl, [esi]
    cmp dl, '-'
    jne .plus
    mov bl, 1
    inc esi
    jmp .digits

.plus:
    cmp dl, '+'
    jne .digits
    inc esi

.digits:
    ; math:
    xor eax, eax

    ; loops:
.loop:
    cmp esi, edi
    jae .apply

    mov dl, [esi]
    cmp dl, '0'
    jb .apply
    cmp dl, '9'
    ja .apply

    imul eax, eax, 10
    movzx edx, dl
    sub edx, '0'
    add eax, edx

    inc esi
    jmp .loop

.apply:
    ; logic:
    test bl, bl
    jz .done
    neg eax

.done:
    ret

.zero:
    xor eax, eax
    ret

print_eax_number:
    ; parse:

    ; logic:
    cmp eax, 0
    jne .neg_check

    mov byte [output_buf], '0'

    ; I/O:
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    mov edx, 1
    int 0x80
    ret

.neg_check:
    cmp eax, 0
    jge .convert

    ; I/O:
    mov byte [output_buf], '-'
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    mov edx, 1
    int 0x80

    ; math:
    neg eax

.convert:
    ; memory:
    mov edi, output_buf + 12
    xor ecx, ecx

    ; loops:
.loop:
    xor edx, edx
    mov ebx, 10
    div ebx

    add dl, '0'

    dec edi
    mov [edi], dl
    inc ecx

    test eax, eax
    jnz .loop

    ; I/O:
    mov eax, 4
    mov ebx, 1
    mov edx, ecx
    mov ecx, edi
    int 0x80
    ret