.data

literal_cadena_0:
    .ascii "true"
longitud_literal_cadena_0 = . - literal_cadena_0

literal_cadena_1:
    .ascii "\n"
longitud_literal_cadena_1 = . - literal_cadena_1

literal_cadena_2:
    .ascii "false"
longitud_literal_cadena_2 = . - literal_cadena_2


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

    mov x0, #0
    mov x8, #93
    svc #0
