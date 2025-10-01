.data

literal_cadena_0:
    .ascii "uno == verdadero -> true"
longitud_literal_cadena_0 = . - literal_cadena_0

literal_cadena_1:
    .ascii "\n"
longitud_literal_cadena_1 = . - literal_cadena_1

literal_cadena_2:
    .ascii "cero == falso -> true"
longitud_literal_cadena_2 = . - literal_cadena_2

literal_cadena_3:
    .ascii "uno != falso -> true"
longitud_literal_cadena_3 = . - literal_cadena_3

literal_cadena_4:
    .ascii "verdadero == uno -> true"
longitud_literal_cadena_4 = . - literal_cadena_4

literal_cadena_5:
    .ascii "ceroDouble == falso -> true"
longitud_literal_cadena_5 = . - literal_cadena_5

literal_cadena_6:
    .ascii "medio < verdadero -> true"
longitud_literal_cadena_6 = . - literal_cadena_6

literal_cadena_7:
    .ascii "verdadero < medio -> false"
longitud_literal_cadena_7 = . - literal_cadena_7

literal_cadena_8:
    .ascii "falso <= floatUno -> true"
longitud_literal_cadena_8 = . - literal_cadena_8

literal_cadena_9:
    .ascii "verdadero >= floatUno -> true"
longitud_literal_cadena_9 = . - literal_cadena_9

literal_cadena_10:
    .ascii "hola == holaCopia -> true"
longitud_literal_cadena_10 = . - literal_cadena_10

literal_cadena_11:
    .ascii "hola != \"hola\" -> false"
longitud_literal_cadena_11 = . - literal_cadena_11

literal_cadena_12:
    .ascii "hola == nuloString -> false"
longitud_literal_cadena_12 = . - literal_cadena_12

literal_cadena_13:
    .ascii "vacio == null -> false"
longitud_literal_cadena_13 = . - literal_cadena_13

literal_cadena_14:
    .ascii "nuloString == null -> true"
longitud_literal_cadena_14 = . - literal_cadena_14

literal_cadena_15:
    .ascii "null == null -> true"
longitud_literal_cadena_15 = . - literal_cadena_15

literal_cadena_16:
    .ascii "null != null -> false"
longitud_literal_cadena_16 = . - literal_cadena_16

literal_cadena_17:
    .ascii "arr1 == arr1 -> true"
longitud_literal_cadena_17 = . - literal_cadena_17

literal_cadena_18:
    .ascii "arr1 == arr2 -> false"
longitud_literal_cadena_18 = . - literal_cadena_18

literal_cadena_19:
    .ascii "arr1 == arr3 -> false"
longitud_literal_cadena_19 = . - literal_cadena_19

literal_cadena_20:
    .ascii "arrNull == null -> true"
longitud_literal_cadena_20 = . - literal_cadena_20

literal_cadena_21:
    .ascii "arr1 == null -> false"
longitud_literal_cadena_21 = . - literal_cadena_21


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

    mov x0, #1
    ldr x1, =literal_cadena_20
    mov x2, #longitud_literal_cadena_20
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_1
    mov x2, #longitud_literal_cadena_1
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =literal_cadena_21
    mov x2, #longitud_literal_cadena_21
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
