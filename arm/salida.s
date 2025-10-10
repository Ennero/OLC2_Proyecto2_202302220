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
    mov w1, #9
    str w1, [x29, -8]
    sub sp, sp, #8
    mov w1, #4
    str w1, [x29, -16]
    sub sp, sp, #8
    ldr x16, =dbl_lit_1
    ldr d0, [x16]
    str d0, [x29, -24]
    sub sp, sp, #8
    ldr x16, =dbl_lit_2
    ldr d0, [x16]
    str d0, [x29, -32]
    sub sp, sp, #8
    mov w1, #1
    str w1, [x29, -40]
    sub sp, sp, #8
    mov w1, #0
    str w1, [x29, -48]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Resta
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    sub w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Multiplicacion
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    mul w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Division
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    sdiv w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Modulo
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    sdiv w21, w19, w20
    msub w1, w21, w20, w19
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Division
    ldr d0, [x29, -24]
    fmov d8, d0
    ldr d0, [x29, -32]
    fmov d9, d0
    fdiv d0, d8, d9
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Modulo
    ldr d0, [x29, -24]
    fmov d8, d0
    ldr d0, [x29, -32]
    fmov d9, d0
    fmov d0, d8
    fmov d1, d9
    bl fmod
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: NegacionUnaria
    ldr w1, [x29, -8]
    neg w1, w1
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: NegacionUnaria
    ldr d0, [x29, -24]
    fmov d8, d0
    ldr x16, =dbl_lit_10
    ldr d0, [x16]
    fmov d9, d0
    fadd d0, d8, d9
    fneg d0, d0
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: IgualIgual
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    cmp w19, w20
    cset w1, eq
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Diferente
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    cmp w19, w20
    cset w1, ne
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: MayorQue
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    cmp w19, w20
    cset w1, gt
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: MenorQue
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    cmp w19, w20
    cset w1, lt
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: MayorIgual
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    cmp w19, w20
    cset w1, ge
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: MenorIgual
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    cmp w19, w20
    cset w1, le
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_17
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: MayorIgual
    ldr d0, [x29, -24]
    fmov d8, d0
    ldr d0, [x29, -32]
    fmov d9, d0
    fcmp d8, d9
    cset w1, ge
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_18
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: And
    ldr w1, [x29, -40]
    mov w19, w1
    ldr w1, [x29, -48]
    mov w20, w1
    and w1, w19, w20
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_19
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Or
    ldr w1, [x29, -40]
    mov w19, w1
    ldr w1, [x29, -48]
    mov w20, w1
    orr w1, w19, w20
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_20
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Not
    ldr w1, [x29, -40]
    eor w1, w1, #1
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_21
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_22
    bl printf
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    sub w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_23
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_24
    bl printf
    ldr w1, [x29, -8]
    mov w19, w1
    ldr w1, [x29, -16]
    mov w20, w1
    cmp w19, w20
    cset w1, gt
    mov w19, w1
    ldr w1, [x29, -40]
    mov w20, w1
    and w1, w19, w20
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_25
    bl printf
    add sp, sp, #48
L_func_exit_2:

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
dbl_lit_1:    .double 7.5
dbl_lit_2:    .double 2.0
str_lit_3:    .asciz "\n"
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz "\n"
str_lit_6:    .asciz "\n"
str_lit_7:    .asciz "\n"
str_lit_8:    .asciz "\n"
str_lit_9:    .asciz "\n"
dbl_lit_10:    .double 0.5
str_lit_11:    .asciz "\n"
str_lit_12:    .asciz "\n"
str_lit_13:    .asciz "\n"
str_lit_14:    .asciz "\n"
str_lit_15:    .asciz "\n"
str_lit_16:    .asciz "\n"
str_lit_17:    .asciz "\n"
str_lit_18:    .asciz "\n"
str_lit_19:    .asciz "\n"
str_lit_20:    .asciz "\n"
str_lit_21:    .asciz "\n"
str_lit_22:    .asciz "res= "
str_lit_23:    .asciz "\n"
str_lit_24:    .asciz "ok? "
str_lit_25:    .asciz "\n"
