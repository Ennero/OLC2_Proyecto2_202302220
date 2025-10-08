// Archivo generado automáticamente por el compilador JavaLang -> AArch64
// Fase 2: Soporte inicial para System.out.println con literales primitivos directos (String, numéricos, booleanos, char, null)

.data

str_0:
    .asciz "--- Literales Primitivos ---"

str_1:
    .asciz "42"

str_2:
    .asciz "3.14159"

str_3:
    .asciz "true"

str_4:
    .asciz "false"

str_5:
    .asciz "--- Fin ---"

.text
.global main

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    ldr x0, =str_0
    bl puts

    ldr x0, =str_1
    bl puts

    ldr x0, =str_2
    bl puts

    ldr x0, =str_3
    bl puts

    ldr x0, =str_4
    bl puts

    ldr x0, =str_5
    bl puts

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret
