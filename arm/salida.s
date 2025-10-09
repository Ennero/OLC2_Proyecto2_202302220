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
    mov w1, #5
    str w1, [x29, -8]
    sub sp, sp, #8
    ldr x16, =dbl_lit_1
    ldr d0, [x16]
    str d0, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Postfix
    ldr w1, [x29, -8]
    add w20, w1, #1
    str w20, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Postfix
    ldr d0, [x29, -16]
    ldr x16, =dbl_lit_4
    ldr d1, [x16]
    fsub d1, d0, d1
    str d1, [x29, -16]
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr d0, [x29, -16]
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    sub sp, sp, #8
    ldr x1, =str_lit_7
    str x1, [x29, -24]
    sub sp, sp, #8
    ldr x1, =str_lit_8
    str x1, [x29, -32]
    sub sp, sp, #8
    ldr x1, =str_lit_9
    str x1, [x29, -40]
    sub sp, sp, #8
    ldr x1, [x29, -24]
    mov x0, x1
    mov x1, #0
    mov w2, #10
    bl strtol
    mov w1, w0
    str w1, [x29, -48]
    sub sp, sp, #8
    ldr x1, [x29, -32]
    mov x0, x1
    mov x1, #0
    bl strtod
    str d0, [x29, -56]
    sub sp, sp, #8
    ldr x1, [x29, -40]
    mov x0, x1
    mov x1, #0
    bl strtof
    fcvt d0, s0
    str d0, [x29, -64]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -48]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr d0, [x29, -56]
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr d0, [x29, -64]
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: StringValueof
    mov w1, #42
    mov w21, w1
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_int
    mov w2, w21
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: StringValueof
    ldr x16, =dbl_lit_14
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: StringValueof
    ldr x1, =true_str
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: StringValueof
    mov w1, #65
    mov w21, w1
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_char
    mov w2, w21
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_17
    bl printf
    add sp, sp, #64

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
dbl_lit_1:    .double 2.5
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "\n"
dbl_lit_4:    .double 1.0
str_lit_5:    .asciz "\n"
str_lit_6:    .asciz "\n"
str_lit_7:    .asciz "123"
str_lit_8:    .asciz "3.14"
str_lit_9:    .asciz "2.5"
str_lit_10:    .asciz "\n"
str_lit_11:    .asciz "\n"
str_lit_12:    .asciz "\n"
str_lit_13:    .asciz "\n"
dbl_lit_14:    .double 3.5
str_lit_15:    .asciz "\n"
str_lit_16:    .asciz "\n"
str_lit_17:    .asciz "\n"
