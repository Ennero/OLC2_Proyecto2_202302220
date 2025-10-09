.data

// Cadenas de formato para printf (sin salto de línea) 
fmt_int:        .asciz "%d"
fmt_double:     .asciz "%f"
fmt_string:     .asciz "%s"
fmt_char:       .asciz "%c"

true_str:       .asciz "true"
false_str:      .asciz "false"

tmpbuf:         .skip 1024

.text
.global main

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    sub sp, sp, #8
    mov w1, #10
    str w1, [x29, -8]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    add sp, sp, #8

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "Mayor que cinco"
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "Par"
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz "Impar"
str_lit_6:    .asciz "\n"
str_lit_7:    .asciz "Negativo"
str_lit_8:    .asciz "\n"
str_lit_9:    .asciz "Cero o positivo"
str_lit_10:    .asciz "\n"
str_lit_11:    .asciz "Negativo"
str_lit_12:    .asciz "\n"
str_lit_13:    .asciz "Positivo"
str_lit_14:    .asciz "\n"
str_lit_15:    .asciz "Cero"
str_lit_16:    .asciz "\n"
