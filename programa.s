.data

literal_cadena_0:
    .ascii "uno && true -> true"
longitud_literal_cadena_0 = . - literal_cadena_0

literal_cadena_1:
    .ascii "\n"
longitud_literal_cadena_1 = . - literal_cadena_1

literal_cadena_2:
    .ascii "cero || true -> true"
longitud_literal_cadena_2 = . - literal_cadena_2

literal_cadena_3:
    .ascii "uno || cero -> true"
longitud_literal_cadena_3 = . - literal_cadena_3

literal_cadena_4:
    .ascii "cero && uno -> false"
longitud_literal_cadena_4 = . - literal_cadena_4

literal_cadena_5:
    .ascii "!cero -> true"
longitud_literal_cadena_5 = . - literal_cadena_5

literal_cadena_6:
    .ascii "!uno -> false"
longitud_literal_cadena_6 = . - literal_cadena_6

literal_cadena_7:
    .ascii "!ceroDouble -> true"
longitud_literal_cadena_7 = . - literal_cadena_7

literal_cadena_8:
    .ascii "!medio -> false"
longitud_literal_cadena_8 = . - literal_cadena_8

literal_cadena_9:
    .ascii "!floatCero -> true"
longitud_literal_cadena_9 = . - literal_cadena_9

literal_cadena_10:
    .ascii "!floatUno -> false"
longitud_literal_cadena_10 = . - literal_cadena_10

literal_cadena_11:
    .ascii "texto && true -> true"
longitud_literal_cadena_11 = . - literal_cadena_11

literal_cadena_12:
    .ascii "vacio || uno -> true"
longitud_literal_cadena_12 = . - literal_cadena_12

literal_cadena_13:
    .ascii "nulo || texto -> true"
longitud_literal_cadena_13 = . - literal_cadena_13

literal_cadena_14:
    .ascii "!nulo -> true"
longitud_literal_cadena_14 = . - literal_cadena_14

literal_cadena_15:
    .ascii "short && -> false"
longitud_literal_cadena_15 = . - literal_cadena_15

literal_cadena_16:
    .ascii "short || -> true"
longitud_literal_cadena_16 = . - literal_cadena_16


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
    ldr x1, =literal_cadena_9
    mov x2, #longitud_literal_cadena_9
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_10
    mov x2, #longitud_literal_cadena_10
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_11
    mov x2, #longitud_literal_cadena_11
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_12
    mov x2, #longitud_literal_cadena_12
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_13
    mov x2, #longitud_literal_cadena_13
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_14
    mov x2, #longitud_literal_cadena_14
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_15
    mov x2, #longitud_literal_cadena_15
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_16
    mov x2, #longitud_literal_cadena_16
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
