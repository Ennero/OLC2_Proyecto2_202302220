// Archivo generado automáticamente por el compilador JavaLang -> AArch64
// Fase 2: Soporte inicial para System.out.println con literales primitivos directos (String, numéricos, booleanos, char, null)

.data

str_0:
    .asciz "A"

str_0_len:
    .quad 1

str_1:
    .asciz "\n"

str_1_len:
    .quad 1

str_2:
    .asciz "null"

str_2_len:
    .quad 4

newline_char:
    .byte 0x0A

.text
.global _start
.global main

print_line:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov x8, #64
    mov x2, x1
    mov x1, x0
    mov x0, #1
    svc #0

    ldr x1, =newline_char
    mov x2, #1
    mov x0, #1
    mov x8, #64
    svc #0

    ldp x29, x30, [sp], 16
    ret

_start:
    bl main
    mov x8, #93
    mov x0, #0
    svc #0

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    ldr x0, =str_0
    ldr x1, =str_0_len
    ldr x1, [x1]
    bl print_line

    ldr x0, =str_1
    ldr x1, =str_1_len
    ldr x1, [x1]
    bl print_line

    ldr x0, =str_2
    ldr x1, =str_2_len
    ldr x1, [x1]
    bl print_line

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret
