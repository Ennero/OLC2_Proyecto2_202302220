.data

// Cadenas de formato para printf (sin salto de línea) 
fmt_int:        .asciz "%d"
fmt_double:     .asciz "%f"
fmt_string:     .asciz "%s"
fmt_char:       .asciz "%c"

true_str:       .asciz "true"
false_str:      .asciz "false"

.text
.global main

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    sub sp, sp, #8
    mov w1, #5
    str w1, [x29, -8]
    sub sp, sp, #8
    mov w1, #3
    str w1, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: BitwiseAnd
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    and w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: BitwiseOr
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    orr w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: BitwiseXor
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    eor w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: BitwiseNot
    ldr w1, [x29, -8]
    mvn w1, w1
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: LeftShift
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #2
    mov w20, w1
    lsl w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: RightShift
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #1
    mov w20, w1
    asr w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: UnsignedRightShift
    mov w1, #8
    neg w1, w1
    mov w19, w1
    mov w1, #1
    mov w20, w1
    lsr w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    ldr w19, [x29, -8]
    mov w1, #8
    mov w20, w1
    orr w1, w19, w20
    str w1, [x29, -8]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    ldr w19, [x29, -8]
    mov w1, #3
    mov w20, w1
    and w1, w19, w20
    str w1, [x29, -8]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
    ldr w19, [x29, -8]
    mov w1, #6
    mov w20, w1
    eor w1, w19, w20
    str w1, [x29, -8]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    ldr w19, [x29, -8]
    mov w1, #1
    mov w20, w1
    lsl w1, w19, w20
    str w1, [x29, -8]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    ldr w19, [x29, -8]
    mov w1, #2
    mov w20, w1
    asr w1, w19, w20
    str w1, [x29, -8]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    ldr w19, [x29, -8]
    mov w1, #1
    mov w20, w1
    lsr w1, w19, w20
    str w1, [x29, -8]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    add sp, sp, #16

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "\n"
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "\n"
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz "\n"
str_lit_6:    .asciz "\n"
str_lit_7:    .asciz "\n"
str_lit_8:    .asciz "\n"
str_lit_9:    .asciz "\n"
str_lit_10:    .asciz "\n"
str_lit_11:    .asciz "\n"
str_lit_12:    .asciz "\n"
str_lit_13:    .asciz "\n"
