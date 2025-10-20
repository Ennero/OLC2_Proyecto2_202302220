.data

// Cadenas de formato para printf (sin salto de línea) 
fmt_int:        .asciz "%d"
fmt_double:     .asciz "%f"
fmt_string:     .asciz "%s"
fmt_char:       .asciz "%c"

true_str:       .asciz "true"
false_str:      .asciz "false"

tmpbuf:         .skip 1024
charbuf:        .skip 8

.text
.global main

// --- Runtime helpers para arreglos ---
// x0 = dims (w0), x1 = ptr a sizes[int32] -> retorna x0 puntero a arreglo
new_array_flat:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #80
    stp x19, x20, [sp, #0]
    stp x21, x22, [sp, #16]
    stp x23, x24, [sp, #32]
    stp x25, x26, [sp, #48]
    stp x27, x28, [sp, #64]
    // Guardar args en callee-saved (preservados a través de llamadas)
    mov w19, w0
    mov x20, x1
    mov x21, #1
L_arr_prod_loop:
    cmp w12, w19
    add x14, x20, x12, uxtw #2
    uxtw x13, w13
    mul x21, x21, x13
    add w12, w12, #1
    b L_arr_prod_loop
L_arr_prod_done:
    // bytes de header = 8 + dims*4; alinear a 8
    mov x15, #8
    uxtw x16, w19
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    mov x27, x17
    // total_bytes = data_off + total_elems*4
    lsl x18, x21, #2
    add x22, x17, x18
    mov x0, x22
    bl malloc
    mov x23, x0
    // escribir dims
    str w19, [x23]
    // copiar sizes
    add x24, x23, #8
    mov w12, #0
L_arr_store_sizes:
    cmp w12, w19
    b.ge L_arr_sizes_done
    add x14, x20, x12, uxtw #2
    ldr w13, [x14]
    add x25, x24, x12, uxtw #2
    str w13, [x25]
    add w12, w12, #1
    b L_arr_store_sizes
L_arr_sizes_done:
    // limpiar data a cero
    add x26, x23, x27
    mov x25, #0
L_arr_zero_loop:
    cmp x25, x21
    b.ge L_arr_zero_done
    add x28, x26, x25, lsl #2
    mov w14, #0
    str w14, [x28]
    add x25, x25, #1
    b L_arr_zero_loop
L_arr_zero_done:
    mov x0, x23
    ldp x19, x20, [sp, #0]
    ldp x21, x22, [sp, #16]
    ldp x23, x24, [sp, #32]
    ldp x25, x26, [sp, #48]
    ldp x27, x28, [sp, #64]
    add sp, sp, #80
    ldp x29, x30, [sp], 16
    ret

// x0 = arr_ptr, x1 = indices ptr, w2 = num_indices -> x0 = puntero a elemento int
array_element_addr:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #80
    stp x19, x20, [sp, #0]
    stp x21, x22, [sp, #16]
    stp x23, x24, [sp, #32]
    stp x25, x26, [sp, #48]
    stp x27, x28, [sp, #64]
    mov x9, x0
    mov x10, x1
    mov w11, w2
    ldr w12, [x9]
    // calcular data_offset
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    // puntero a sizes
    add x18, x9, #8
    mov x19, #0
    mov w20, #0
L_lin_outer:
    cmp w20, w11
    b.ge L_lin_done
    // cargar idx[i]
    add x21, x10, x20, uxtw #2
    ldr w22, [x21]
    uxtw x22, w22
    // stride = prod sizes[j] para j=i+1..dims-1
    mov x23, #1
    add w24, w20, #1
L_lin_stride:
    cmp w24, w12
    b.ge L_lin_stride_done
    add x25, x18, x24, uxtw #2
    ldr w26, [x25]
    uxtw x26, w26
    mul x23, x23, x26
    add w24, w24, #1
    b L_lin_stride
L_lin_stride_done:
    madd x19, x22, x23, x19
    add w20, w20, #1
    b L_lin_outer
L_lin_done:
    // &data[lin]
    add x0, x9, x17
    add x0, x0, x19, lsl #2
    ldp x19, x20, [sp, #0]
    ldp x21, x22, [sp, #16]
    ldp x23, x24, [sp, #32]
    ldp x25, x26, [sp, #48]
    ldp x27, x28, [sp, #64]
    add sp, sp, #80
    ldp x29, x30, [sp], 16
    ret

// --- Helper: char_to_utf8(w0->x0) ---
char_to_utf8:
    // preservar code point en w9 y preparar puntero de salida en x0
    mov w9, w0
    ldr x1, =charbuf
    mov x0, x1
    // if cp <= 0x7F -> 1 byte
    mov w2, #0x7F
    cmp w9, w2
    b.hi 1f
    // 1-byte ASCII
    strb w9, [x1]
    mov w3, #0
    strb w3, [x1, #1]
    ret
1:
    // if cp <= 0x7FF -> 2 bytes
    mov w2, #0x7FF
    cmp w9, w2
    b.hi 2f
    // 2 bytes: 110xxxxx 10xxxxxx
    ubfx w4, w9, #6, #5
    orr w4, w4, #0xC0
    strb w4, [x1]
    and w5, w9, #0x3F
    orr w5, w5, #0x80
    strb w5, [x1, #1]
    mov w3, #0
    strb w3, [x1, #2]
    ret
2:
    // if cp <= 0xFFFF -> 3 bytes
    mov w2, #0xFFFF
    cmp w9, w2
    b.hi 3f
    // 3 bytes: 1110xxxx 10xxxxxx 10xxxxxx
    ubfx w4, w9, #12, #4
    orr w4, w4, #0xE0
    strb w4, [x1]
    ubfx w5, w9, #6, #6
    orr w5, w5, #0x80
    strb w5, [x1, #1]
    and w6, w9, #0x3F
    orr w6, w6, #0x80
    strb w6, [x1, #2]
    mov w3, #0
    strb w3, [x1, #3]
    ret
3:
    // 4 bytes: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
    ubfx w4, w9, #18, #3
    orr w4, w4, #0xF0
    strb w4, [x1]
    ubfx w5, w9, #12, #6
    orr w5, w5, #0x80
    strb w5, [x1, #1]
    ubfx w6, w9, #6, #6
    orr w6, w6, #0x80
    strb w6, [x1, #2]
    and w7, w9, #0x3F
    orr w7, w7, #0x80
    strb w7, [x1, #3]
    mov w3, #0
    strb w3, [x1, #4]
    ret

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    mov w1, #65
    sub x16, x29, #16
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr w1, [x16]
    sub x16, x29, #32
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    sub x16, x29, #32
    ldr w1, [x16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    mov w1, #42
    sub x16, x29, #48
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #48
    ldr w1, [x16]
    scvtf d0, w1
    sub x16, x29, #64
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    sub x16, x29, #64
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_7
    ldr d0, [x16]
    sub x16, x29, #80
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #80
    ldr d0, [x16]
    sub x16, x29, #96
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    sub x16, x29, #96
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
    sub sp, sp, #16
    mov w1, #90
    sub x16, x29, #112
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    sub x16, x29, #128
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #128
    ldr w1, [x16]
    scvtf d0, w1
    sub x16, x29, #144
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #144
    ldr d0, [x16]
    sub x16, x29, #160
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    sub x16, x29, #112
    ldr w1, [x16]
    mov w0, w1
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    sub x16, x29, #128
    ldr w1, [x16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    sub x16, x29, #144
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_17
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_18
    bl printf
    sub x16, x29, #160
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_19
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_20
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_21
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_22
    ldr d0, [x16]
    sub x16, x29, #176
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #176
    ldr d0, [x16]
    sub x16, x29, #192
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_23
    bl printf
    sub x16, x29, #192
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_24
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_25
    ldr d0, [x16]
    sub x16, x29, #208
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #208
    ldr d0, [x16]
    fcvtzs w1, d0
    sub x16, x29, #224
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_26
    bl printf
    sub x16, x29, #224
    ldr w1, [x16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_27
    bl printf
    sub sp, sp, #16
    mov w1, #65
    sub x16, x29, #240
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #240
    ldr w1, [x16]
    sub x16, x29, #256
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_28
    bl printf
    sub x16, x29, #256
    ldr w1, [x16]
    mov w0, w1
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_29
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_30
    ldr d0, [x16]
    sub x16, x29, #272
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #272
    ldr d0, [x16]
    fcvtzs w1, d0
    sub x16, x29, #288
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_31
    bl printf
    sub x16, x29, #288
    ldr w1, [x16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_32
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_33
    ldr d0, [x16]
    fneg d0, d0
    sub x16, x29, #304
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #304
    ldr d0, [x16]
    fcvtzs w1, d0
    sub x16, x29, #320
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_34
    bl printf
    sub x16, x29, #320
    ldr w1, [x16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_35
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_36
    ldr d0, [x16]
    sub x16, x29, #336
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #336
    ldr d0, [x16]
    sub x16, x29, #352
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #352
    ldr d0, [x16]
    fcvtzs w1, d0
    sub x16, x29, #368
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #368
    ldr w1, [x16]
    sub x16, x29, #384
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_37
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_38
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_39
    bl printf
    sub x16, x29, #336
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_40
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_41
    bl printf
    sub x16, x29, #352
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_42
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_43
    bl printf
    sub x16, x29, #368
    ldr w1, [x16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_44
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_45
    bl printf
    sub x16, x29, #384
    ldr w1, [x16]
    mov w0, w1
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_46
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_47
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_48
    bl printf
    sub sp, sp, #16
    mov w1, #100
    sub x16, x29, #400
    str w1, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_49
    ldr d0, [x16]
    sub x16, x29, #416
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_50
    bl printf
    sub x16, x29, #400
    ldr w1, [x16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_51
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_52
    bl printf
    sub x16, x29, #416
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_53
    bl printf
    sub sp, sp, #16
    mov w1, #1
    sub x16, x29, #432
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_54
    bl printf
    sub x16, x29, #432
    ldr w1, [x16]
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_55
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_56
    sub x16, x29, #448
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #448
    ldr x1, [x16]
    mov x0, x1
    mov x1, #0
    mov w2, #10
    bl strtol
    mov w1, w0
    sub x16, x29, #464
    str w1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_57
    mov x0, x1
    mov x1, #0
    bl strtof
    fcvt d0, s0
    sub x16, x29, #480
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_58
    bl printf
    sub x16, x29, #464
    ldr w1, [x16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_59
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_60
    bl printf
    sub x16, x29, #480
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_61
    bl printf
L_func_exit_4:
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "=== Pruebas de Widening Casting (Automático) ==="
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "char 'A' -> int: "
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz "int 42 -> float: "
str_lit_6:    .asciz "\n"
dbl_lit_7:    .double 3.14
str_lit_8:    .asciz "float 3.14 -> double: "
str_lit_9:    .asciz "\n"
str_lit_10:    .asciz "Cadena de conversiones:"
str_lit_11:    .asciz "\n"
str_lit_12:    .asciz "char 'Z': "
str_lit_13:    .asciz "\n"
str_lit_14:    .asciz "-> int: "
str_lit_15:    .asciz "\n"
str_lit_16:    .asciz "-> float: "
str_lit_17:    .asciz "\n"
str_lit_18:    .asciz "-> double: "
str_lit_19:    .asciz "\n"
str_lit_20:    .asciz "=== Pruebas de Narrowing Casting (Manual) ==="
str_lit_21:    .asciz "\n"
dbl_lit_22:    .double 3.14159265359
str_lit_23:    .asciz "double 3.14159265359 -> float: "
str_lit_24:    .asciz "\n"
dbl_lit_25:    .double 5.9
str_lit_26:    .asciz "float 5.9 -> int: "
str_lit_27:    .asciz "\n"
str_lit_28:    .asciz "int 65 -> char: "
str_lit_29:    .asciz "\n"
dbl_lit_30:    .double 7.8
str_lit_31:    .asciz "float 7.8 -> int: "
str_lit_32:    .asciz "\n"
dbl_lit_33:    .double 2.3
str_lit_34:    .asciz "float -2.3 -> int: "
str_lit_35:    .asciz "\n"
dbl_lit_36:    .double 72.99
str_lit_37:    .asciz "Cadena de conversiones hacia abajo:"
str_lit_38:    .asciz "\n"
str_lit_39:    .asciz "double 72.99: "
str_lit_40:    .asciz "\n"
str_lit_41:    .asciz "-> float: "
str_lit_42:    .asciz "\n"
str_lit_43:    .asciz "-> int: "
str_lit_44:    .asciz "\n"
str_lit_45:    .asciz "-> char: "
str_lit_46:    .asciz "\n"
str_lit_47:    .asciz "=== Casos adicionales ==="
str_lit_48:    .asciz "\n"
dbl_lit_49:    .double 25.0
str_lit_50:    .asciz "Casting redundante int->int: "
str_lit_51:    .asciz "\n"
str_lit_52:    .asciz "Casting redundante double->double: "
str_lit_53:    .asciz "\n"
str_lit_54:    .asciz "Boolean: "
str_lit_55:    .asciz "\n"
str_lit_56:    .asciz "123"
str_lit_57:    .asciz "45.6"
str_lit_58:    .asciz "String \"123\" -> int: "
str_lit_59:    .asciz "\n"
str_lit_60:    .asciz "String \"45.6\" -> float: "
str_lit_61:    .asciz "\n"

// --- Variables globales ---
g_letra:    .quad 65
g_codigo:    .quad 0
g_entero:    .quad 42
g_flotante:    .quad 0
g_decimal:    .quad 0
g_doble:    .quad 0
g_caracter:    .quad 90
g_codigoChar:    .quad 0
g_flotanteChar:    .quad 0
g_dobleChar:    .quad 0
g_dobleNum:    .quad 0
g_flotanteNum:    .quad 0
g_decimal2:    .quad 0
g_entero2:    .quad 0
g_codigoAscii:    .quad 65
g_letra2:    .quad 0
g_positivo:    .quad 0
g_enteroPositivo:    .quad 0
g_negativo:    .quad 0
g_enteroNegativo:    .quad 0
g_granNumero:    .quad 0
g_medioNumero:    .quad 0
g_pequenoNumero:    .quad 0
g_caracterFinal:    .quad 0
g_redundante:    .quad 0
g_redundante2:    .quad 0
g_bandera:    .quad 1
g_numeroStr:    .quad 0
g_numParse:    .quad 0
g_numParseF:    .quad 0
