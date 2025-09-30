.data

literal_cadena_0:
    .ascii "0"
longitud_literal_cadena_0 = . - literal_cadena_0

literal_cadena_1:
    .ascii "\n"
longitud_literal_cadena_1 = . - literal_cadena_1

literal_cadena_2:
    .ascii "42"
longitud_literal_cadena_2 = . - literal_cadena_2

literal_cadena_3:
    .ascii "-15"
longitud_literal_cadena_3 = . - literal_cadena_3

literal_cadena_4:
    .ascii "3.14"
longitud_literal_cadena_4 = . - literal_cadena_4

literal_cadena_5:
    .ascii "0.125"
longitud_literal_cadena_5 = . - literal_cadena_5

literal_cadena_6:
    .ascii "2.718281828"
longitud_literal_cadena_6 = . - literal_cadena_6

literal_cadena_7:
    .ascii "123456.000001"
longitud_literal_cadena_7 = . - literal_cadena_7

literal_cadena_8:
    .ascii "true"
longitud_literal_cadena_8 = . - literal_cadena_8

literal_cadena_9:
    .ascii "false"
longitud_literal_cadena_9 = . - literal_cadena_9

literal_cadena_10:
    .ascii "Z"
longitud_literal_cadena_10 = . - literal_cadena_10

literal_cadena_11:
    .ascii "\t"
longitud_literal_cadena_11 = . - literal_cadena_11

literal_cadena_12:
    .ascii "-2"
longitud_literal_cadena_12 = . - literal_cadena_12

literal_cadena_13:
    .ascii "30"
longitud_literal_cadena_13 = . - literal_cadena_13

literal_cadena_14:
    .ascii "6"
longitud_literal_cadena_14 = . - literal_cadena_14

literal_cadena_15:
    .ascii "5"
longitud_literal_cadena_15 = . - literal_cadena_15

literal_cadena_16:
    .ascii "1"
longitud_literal_cadena_16 = . - literal_cadena_16

literal_cadena_17:
    .ascii "20"
longitud_literal_cadena_17 = . - literal_cadena_17

literal_cadena_18:
    .ascii "-10.5"
longitud_literal_cadena_18 = . - literal_cadena_18

literal_cadena_19:
    .ascii "null"
longitud_literal_cadena_19 = . - literal_cadena_19


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
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
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

    mov x0, #1
    ldr x1, =literal_cadena_17
    mov x2, #longitud_literal_cadena_17
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_18
    mov x2, #longitud_literal_cadena_18
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_19
    mov x2, #longitud_literal_cadena_19
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
