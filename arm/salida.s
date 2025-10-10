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
    mov w1, #1
    str w1, [x29, -8]
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #1
    mov w20, w1
    cmp w19, w20
    cset w1, eq
    cmp w1, #0
    beq L_end_2
L_then_2:
    add sp, sp, #8
    b L_func_exit_1
L_end_2:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    add sp, sp, #8
L_func_exit_1:

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "NO"
str_lit_2:    .asciz "\n"
