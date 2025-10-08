// Archivo generado automáticamente por el compilador JavaLang -> AArch64
// Fase 2: Soporte inicial para System.out.println con literales String

.data

str_0:
    .asciz "--- Prueba de 'break' ---"

str_1:
    .asciz "Prueba 1: Saliendo de un 'for' en i=3"

str_2:
    .asciz "Break activado."

str_3:
    .asciz "----------------------------------------"

str_4:
    .asciz "Prueba 2: Saliendo de un 'while' en j=7"

str_5:
    .asciz "Prueba 3: Saliendo de un 'case' con break"

str_6:
    .asciz "Lunes"

str_7:
    .asciz "Martes"

str_8:
    .asciz "Mi\xC3\xA9rcoles"

str_9:
    .asciz "Otro d\xC3\xADa"

str_10:
    .asciz "Prueba 4: 'break' en bucle anidado"

str_11:
    .asciz "--- Fin de la prueba de 'break' ---"

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

    // TODO (linea 11, columna 9): System.out.println solo soporta, por ahora, literales String.

    ldr x0, =str_3
    bl puts

    ldr x0, =str_4
    bl puts

    // TODO (linea 24, columna 5): System.out.println solo soporta, por ahora, literales String.

    ldr x0, =str_3
    bl puts

    ldr x0, =str_5
    bl puts

    ldr x0, =str_6
    bl puts

    ldr x0, =str_7
    bl puts

    ldr x0, =str_8
    bl puts

    ldr x0, =str_9
    bl puts

    ldr x0, =str_3
    bl puts

    ldr x0, =str_10
    bl puts

    // TODO (linea 42, columna 9): System.out.println solo soporta, por ahora, literales String.

    // TODO (linea 47, columna 13): System.out.println solo soporta, por ahora, literales String.

    ldr x0, =str_11
    bl puts

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret
