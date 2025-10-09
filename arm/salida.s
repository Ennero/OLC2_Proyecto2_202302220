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
    mov w1, #65
    str w1, [x29, -8]
    sub sp, sp, #8
    mov w1, #65
    str w1, [x29, -16]
    sub sp, sp, #8
    mov w1, #10
    str w1, [x29, -24]
    sub sp, sp, #8
    mov w1, #10
    str w1, [x29, -32]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Casteo
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Casteo
    ldr w1, [x29, -16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Casteo
    ldr w1, [x29, -24]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Casteo
    ldr w1, [x29, -32]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    add sp, sp, #32

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "\n"
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "\n"
str_lit_4:    .asciz "\n"
