.data

literal_cadena_0:
    .ascii "false"
longitud_literal_cadena_0 = . - literal_cadena_0

literal_cadena_1:
    .ascii "\n"
longitud_literal_cadena_1 = . - literal_cadena_1

literal_cadena_2:
    .ascii "true"
longitud_literal_cadena_2 = . - literal_cadena_2

literal_cadena_3:
    .ascii "6"
longitud_literal_cadena_3 = . - literal_cadena_3

literal_cadena_4:
    .ascii "1"
longitud_literal_cadena_4 = . - literal_cadena_4

literal_cadena_5:
    .ascii "2147483646"
longitud_literal_cadena_5 = . - literal_cadena_5

literal_cadena_6:
    .ascii "4"
longitud_literal_cadena_6 = . - literal_cadena_6

literal_cadena_7:
    .ascii "0"
longitud_literal_cadena_7 = . - literal_cadena_7

literal_cadena_8:
    .ascii "2"
longitud_literal_cadena_8 = . - literal_cadena_8

literal_cadena_9:
    .ascii "2147483647"
longitud_literal_cadena_9 = . - literal_cadena_9


.text

.global _start

_start:

    mov x0, #1
    ldr x1, =literal_cadena_0
    mov x2, #longitud_literal_cadena_0
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_2
    mov x2, #longitud_literal_cadena_2
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_2
    mov x2, #longitud_literal_cadena_2
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_0
    mov x2, #longitud_literal_cadena_0
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_2
    mov x2, #longitud_literal_cadena_2
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_0
    mov x2, #longitud_literal_cadena_0
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_3
    mov x2, #longitud_literal_cadena_3
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_4
    mov x2, #longitud_literal_cadena_4
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_4
    mov x2, #longitud_literal_cadena_4
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_5
    mov x2, #longitud_literal_cadena_5
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_6
    mov x2, #longitud_literal_cadena_6
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_7
    mov x2, #longitud_literal_cadena_7
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_8
    mov x2, #longitud_literal_cadena_8
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_6
    mov x2, #longitud_literal_cadena_6
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_9
    mov x2, #longitud_literal_cadena_9
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #0
    mov x8, #93
    svc #0
