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
    mov w1, #0
    str w1, [x29, -8]
L_while_cond_2:
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #5
    mov w20, w1
    cmp w19, w20
    cset w1, lt
    cmp w1, #0
    beq L_break_2
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #3
    mov w20, w1
    cmp w19, w20
    cset w1, eq
    cmp w1, #0
    beq L_end_3
L_then_3:
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #1
    mov w20, w1
    add w1, w19, w20
    str w1, [x29, -8]
    b L_continue_2
L_end_3:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #4
    mov w20, w1
    cmp w19, w20
    cset w1, eq
    cmp w1, #0
    beq L_end_4
L_then_4:
    b L_break_2
L_end_4:
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #1
    mov w20, w1
    add w1, w19, w20
    str w1, [x29, -8]
L_continue_2:
    b L_while_cond_2
L_break_2:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    sub sp, sp, #8
    mov w1, #0
    str w1, [x29, -16]
L_for_cond_5:
    ldr w1, [x29, -16]
    mov w19, w1
    mov w1, #3
    mov w20, w1
    cmp w19, w20
    cset w1, lt
    cmp w1, #0
    beq L_break_5
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
L_continue_5:
    ldr w1, [x29, -16]
    mov w19, w1
    mov w1, #1
    mov w20, w1
    add w1, w19, w20
    str w1, [x29, -16]
    b L_for_cond_5
L_break_5:
    add sp, sp, #8
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    sub sp, sp, #8
    mov w1, #0
    str w1, [x29, -16]
L_for_cond_6:
    ldr w1, [x29, -16]
    mov w19, w1
    mov w1, #3
    mov w20, w1
    cmp w19, w20
    cset w1, lt
    cmp w1, #0
    beq L_break_6
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
L_continue_6:
    ldr w1, [x29, -16]
    add w20, w1, #1
    str w20, [x29, -16]
    b L_for_cond_6
L_break_6:
    add sp, sp, #8
    add sp, sp, #8
L_func_exit_1:

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "\n"
str_lit_2:    .asciz "--"
str_lit_3:    .asciz "\n"
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz "--"
str_lit_6:    .asciz "\n"
str_lit_7:    .asciz "\n"
