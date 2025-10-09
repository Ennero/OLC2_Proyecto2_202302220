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
    mov w1, #3
    str w1, [x29, -8]
    // --- Generando switch ---
    ldr w1, [x29, -8]
    mov w19, w1
    // comparar selector int con case int
    mov w1, #1
    mov w20, w1
    cmp w19, w20
    beq L_case_0_1
    // comparar selector int con case int
    mov w1, #2
    mov w20, w1
    cmp w19, w20
    beq L_case_1_1
    // comparar selector int con case int
    mov w1, #3
    mov w20, w1
    cmp w19, w20
    beq L_case_2_1
    b L_default_1
L_case_0_1:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_break_1
L_case_1_1:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    b L_break_1
L_case_2_1:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    b L_break_1
L_default_1:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
L_break_1:
    sub sp, sp, #8
    ldr x1, =str_lit_9
    str x1, [x29, -16]
    // --- Generando switch ---
    ldr x1, [x29, -16]
    mov x19, x1
    // comparar selector string con case string
    ldr x1, =str_lit_10
    mov x0, x19
    // strcmp(x0, x1) == 0 ? goto case
    bl strcmp
    cmp w0, #0
    beq L_case_0_2
    // comparar selector string con case string
    ldr x1, =str_lit_11
    mov x0, x19
    // strcmp(x0, x1) == 0 ? goto case
    bl strcmp
    cmp w0, #0
    beq L_case_1_2
    b L_default_2
L_case_0_2:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    b L_break_2
L_case_1_2:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    b L_break_2
L_default_2:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_17
    bl printf
L_break_2:
    add sp, sp, #16

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "Lunes"
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "Martes"
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz "Miércoles"
str_lit_6:    .asciz "\n"
str_lit_7:    .asciz "Otro día"
str_lit_8:    .asciz "\n"
str_lit_9:    .asciz "b"
str_lit_10:    .asciz "a"
str_lit_11:    .asciz "b"
str_lit_12:    .asciz "uno"
str_lit_13:    .asciz "\n"
str_lit_14:    .asciz "dos"
str_lit_15:    .asciz "\n"
str_lit_16:    .asciz "tres"
str_lit_17:    .asciz "\n"
