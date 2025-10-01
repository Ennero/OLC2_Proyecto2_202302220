// === Comentarios del programa fuente ===
// [L1,C1] // Comentario inicial de archivo
// [L3,C5] // Comentario dentro de main
// [L4,C5] /* Comentario en bloque
// [L4,C5]        que cubre varias lineas */
// [L6,C45] // Comentario al final de la linea

.data

literal_cadena_0:
    .ascii "Hola comentarios"
longitud_literal_cadena_0 = . - literal_cadena_0

literal_cadena_1:
    .ascii "\n"
longitud_literal_cadena_1 = . - literal_cadena_1


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

    mov x0, #0
    mov x8, #93
    svc #0
