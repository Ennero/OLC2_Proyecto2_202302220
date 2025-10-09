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
    mov w1, #15
    str w1, [x29, -8]
    sub sp, sp, #8
    ldr x16, =dbl_lit_1
    ldr d0, [x16]
    str d0, [x29, -16]
    sub sp, sp, #8
    ldr x1, =str_lit_2
    str x1, [x29, -24]
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #5
    mov w20, w1
    add w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    ldr d0, [x29, -16]
    fmov d8, d0
    ldr x16, =dbl_lit_5
    ldr d0, [x16]
    fmov d9, d0
    fadd d0, d8, d9
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    ldr w1, [x29, -8]
    mov w19, w1
    ldr d0, [x29, -16]
    fmov d9, d0
    scvtf d8, w19
    fadd d0, d8, d9
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    ldr x1, [x29, -24]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    ldr w1, [x29, -8]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    ldr d0, [x29, -16]
    ldr x0, =fmt_double
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    ldr w1, [x29, -8]
    mov w19, w1
    mov w1, #10
    mov w20, w1
    add w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    add sp, sp, #24

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
dbl_lit_1:    .double 2.5
str_lit_2:    .asciz "Hola"
str_lit_3:    .asciz "\n"
str_lit_4:    .asciz "\n"
dbl_lit_5:    .double 3.5
str_lit_6:    .asciz "\n"
str_lit_7:    .asciz "\n"
str_lit_8:    .asciz " Mundo"
str_lit_9:    .asciz "\n"
str_lit_10:    .asciz "Resultado: "
str_lit_11:    .asciz " y b= "
str_lit_12:    .asciz "\n"
str_lit_13:    .asciz "Suma: "
str_lit_14:    .asciz "\n"
