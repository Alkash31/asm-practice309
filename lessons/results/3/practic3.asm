global _start

section .bss
    ; memory:
    buffer resb 6

section .text

_start:
    ; logic:
    ; Вхід: EAX = число 0..999999
    ; mov eax
     mov eax, 123456

    cmp eax, 0
    jne convert_number

    ; memory:
    mov byte [buffer], '0'

    ; I/O:
    mov eax, 4
    mov ebx, 1
    mov ecx, buffer
    mov edx, 1
    int 0x80

    jmp end

convert_number:
    ; memory:
    mov edi, buffer + 6
    xor ecx, ecx

    ; loops:
convert_loop:
    ; math:
    xor edx, edx
    mov ebx, 10
    div ebx

    add dl, '0'
    dec edi
    mov [edi], dl
    inc ecx

    ; logic:
    test eax, eax
    jnz convert_loop

    ; I/O:
    mov eax, 4
    mov ebx, 1
    mov edx, ecx
    mov ecx, edi
    int 0x80

end:
    ; I/O:
    mov eax, 1
    xor ebx, ebx
    int 0x80