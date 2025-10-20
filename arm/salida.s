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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    mov w1, #25
    sub x16, x29, #16
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #17
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr w1, [x16]
    mov w19, w1
    sub x16, x29, #32
    ldr w1, [x16]
    mov w20, w1
    add w1, w19, w20
    sub x16, x29, #48
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    sub x16, x29, #16
    ldr w1, [x16]
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
    ldr x1, =str_lit_6
    bl printf
    sub x16, x29, #32
    ldr w1, [x16]
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
    ldr x1, =str_lit_7
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    sub x16, x29, #48
    ldr w1, [x16]
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
    ldr x1, =str_lit_9
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    sub sp, sp, #16
    mov w1, #100
    sub x16, x29, #64
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #35
    sub x16, x29, #80
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #64
    ldr w1, [x16]
    mov w19, w1
    sub x16, x29, #80
    ldr w1, [x16]
    mov w20, w1
    sub w1, w19, w20
    sub x16, x29, #96
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    sub x16, x29, #64
    ldr w1, [x16]
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
    ldr x1, =str_lit_12
    bl printf
    sub x16, x29, #80
    ldr w1, [x16]
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
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    sub x16, x29, #96
    ldr w1, [x16]
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
    ldr x1, =str_lit_15
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    sub sp, sp, #16
    mov w1, #12
    sub x16, x29, #112
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #8
    sub x16, x29, #128
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    mov w19, w1
    sub x16, x29, #128
    ldr w1, [x16]
    mov w20, w1
    mul w1, w19, w20
    sub x16, x29, #144
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_17
    bl printf
    sub x16, x29, #112
    ldr w1, [x16]
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
    ldr x1, =str_lit_18
    bl printf
    sub x16, x29, #128
    ldr w1, [x16]
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
    ldr x1, =str_lit_19
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_20
    bl printf
    sub x16, x29, #144
    ldr w1, [x16]
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
    ldr x1, =str_lit_21
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_22
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_23
    ldr d0, [x16]
    sub x16, x29, #160
    str d0, [x16]
    sub sp, sp, #16
    mov w1, #12
    sub x16, x29, #176
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #160
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #176
    ldr w1, [x16]
    mov w20, w1
    scvtf d9, w20
    fdiv d0, d8, d9
    sub x16, x29, #192
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_24
    bl printf
    sub x16, x29, #160
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_25
    bl printf
    sub x16, x29, #176
    ldr w1, [x16]
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
    ldr x1, =str_lit_26
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_27
    bl printf
    sub x16, x29, #192
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_28
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_29
    bl printf
    sub sp, sp, #16
    mov w1, #29
    sub x16, x29, #208
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #7
    sub x16, x29, #224
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #208
    ldr w1, [x16]
    mov w19, w1
    sub x16, x29, #224
    ldr w1, [x16]
    mov w20, w1
    sdiv w21, w19, w20
    msub w1, w21, w20, w19
    sub x16, x29, #240
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_30
    bl printf
    sub x16, x29, #208
    ldr w1, [x16]
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
    ldr x1, =str_lit_31
    bl printf
    sub x16, x29, #224
    ldr w1, [x16]
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
    ldr x1, =str_lit_32
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_33
    bl printf
    sub x16, x29, #240
    ldr w1, [x16]
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
    ldr x1, =str_lit_34
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_35
    bl printf
    sub sp, sp, #16
    mov w1, #82
    sub x16, x29, #256
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #164
    sub x16, x29, #272
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #272
    ldr w1, [x16]
    mov w19, w1
    sub x16, x29, #256
    ldr w1, [x16]
    mov w20, w1
    sub w1, w19, w20
    sub x16, x29, #288
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_36
    bl printf
    sub x16, x29, #272
    ldr w1, [x16]
    mov w21, w1
    ldr x19, =tmpbuf
    mov x0, x19
    mov w0, w21
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_37
    bl printf
    sub x16, x29, #256
    ldr w1, [x16]
    mov w21, w1
    ldr x19, =tmpbuf
    mov x0, x19
    mov w0, w21
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_38
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_39
    bl printf
    sub x16, x29, #288
    ldr w1, [x16]
    mov w21, w1
    ldr x19, =tmpbuf
    mov x0, x19
    mov w0, w21
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_40
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_41
    bl printf
    sub sp, sp, #16
    mov w1, #3
    neg w1, w1
    sub x16, x29, #304
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #1
    sub x16, x29, #320
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #304
    ldr w1, [x16]
    mov w19, w1
    sub x16, x29, #320
    ldr w1, [x16]
    mov w20, w1
    asr w1, w19, w20
    sub x16, x29, #336
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_42
    bl printf
    sub x16, x29, #304
    ldr w1, [x16]
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
    ldr x1, =str_lit_43
    bl printf
    sub x16, x29, #320
    ldr w1, [x16]
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
    ldr x1, =str_lit_44
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_45
    bl printf
    sub x16, x29, #336
    ldr w1, [x16]
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
    ldr x1, =str_lit_46
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_47
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_48
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_49
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_50
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_51
    ldr d0, [x16]
    sub x16, x29, #352
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #352
    ldr d0, [x16]
    fmov d8, d0
    ldr x16, =dbl_lit_52
    ldr d0, [x16]
    fmov d9, d0
    fsub d0, d8, d9
    fmov d8, d0
    ldr x16, =dbl_lit_53
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    fmov d8, d0
    ldr x16, =dbl_lit_54
    ldr d0, [x16]
    fmov d9, d0
    fdiv d0, d8, d9
    sub x16, x29, #368
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    sub x16, x29, #352
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_55
    bl printf
    sub x16, x29, #368
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_56
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_57
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_58
    ldr d0, [x16]
    sub x16, x29, #384
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #384
    ldr d0, [x16]
    fmov d8, d0
    ldr x16, =dbl_lit_59
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    fmov d8, d0
    ldr x16, =dbl_lit_60
    ldr d0, [x16]
    fmov d9, d0
    fdiv d0, d8, d9
    fmov d8, d0
    ldr x16, =dbl_lit_61
    ldr d0, [x16]
    fmov d9, d0
    fadd d0, d8, d9
    sub x16, x29, #400
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    sub x16, x29, #384
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_62
    bl printf
    sub x16, x29, #400
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_63
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_64
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_65
    ldr d0, [x16]
    sub x16, x29, #416
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #416
    ldr d0, [x16]
    fmov d8, d0
    ldr x16, =dbl_lit_66
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    fmov d8, d0
    ldr x16, =dbl_lit_67
    ldr d0, [x16]
    fmov d9, d0
    fdiv d0, d8, d9
    fmov d8, d0
    ldr x16, =dbl_lit_68
    ldr d0, [x16]
    fmov d9, d0
    fadd d0, d8, d9
    sub x16, x29, #432
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    sub x16, x29, #416
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_69
    bl printf
    sub x16, x29, #432
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_70
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_71
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_72
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_73
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_74
    ldr d0, [x16]
    sub x16, x29, #448
    str d0, [x16]
    sub sp, sp, #16
    fmov d0, xzr
    sub x16, x29, #464
    str d0, [x16]
    sub x16, x29, #464
    ldr d8, [x16]
    ldr x16, =dbl_lit_75
    ldr d0, [x16]
    fmov d9, d0
    fadd d0, d8, d9
    sub x16, x29, #464
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #448
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #464
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    sub x16, x29, #480
    str d0, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_76
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #448
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #464
    ldr d0, [x16]
    fmov d9, d0
    fadd d0, d8, d9
    fmov d9, d0
    fmul d0, d8, d9
    sub x16, x29, #496
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_77
    bl printf
    sub x16, x29, #448
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_78
    bl printf
    sub x16, x29, #464
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_79
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_80
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_81
    bl printf
    sub x16, x29, #480
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_82
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_83
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_84
    bl printf
    sub x16, x29, #496
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_85
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_86
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_87
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_88
    ldr d0, [x16]
    sub x16, x29, #512
    str d0, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_89
    ldr d0, [x16]
    sub x16, x29, #528
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #528
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #512
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    fmov d8, d0
    sub x16, x29, #512
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    sub x16, x29, #544
    str d0, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_90
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #528
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    fmov d8, d0
    sub x16, x29, #512
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    sub x16, x29, #560
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_91
    bl printf
    sub x16, x29, #512
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_92
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_93
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_94
    bl printf
    sub x16, x29, #544
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_95
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_96
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_97
    bl printf
    sub x16, x29, #560
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_98
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_99
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_100
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_101
    bl printf
    sub sp, sp, #16
    mov w1, #15
    sub x16, x29, #576
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #592
    str w1, [x16]
    sub x16, x29, #592
    ldr w1, [x16]
    cmp w1, #0
    beq L_else_2
L_then_2:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_102
    bl printf
    sub x16, x29, #576
    ldr w1, [x16]
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
    ldr x1, =str_lit_103
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_104
    bl printf
    b L_end_2
L_else_2:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_105
    bl printf
    sub x16, x29, #576
    ldr w1, [x16]
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
    ldr x1, =str_lit_106
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_107
    bl printf
L_end_2:
    sub sp, sp, #16
    mov w1, #5
    neg w1, w1
    sub x16, x29, #608
    str w1, [x16]
    sub x16, x29, #608
    ldr w1, [x16]
    mov w19, w1
    mov w1, #0
    mov w20, w1
    cmp w19, w20
    cset w1, gt
    cmp w1, #0
    beq L_else_3
L_then_3:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_108
    bl printf
    sub x16, x29, #608
    ldr w1, [x16]
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
    ldr x1, =str_lit_109
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_110
    bl printf
    b L_end_3
L_else_3:
    sub x16, x29, #608
    ldr w1, [x16]
    mov w19, w1
    mov w1, #0
    mov w20, w1
    cmp w19, w20
    cset w1, lt
    cmp w1, #0
    beq L_else_4
L_then_4:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_111
    bl printf
    sub x16, x29, #608
    ldr w1, [x16]
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
    ldr x1, =str_lit_112
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_113
    bl printf
    b L_end_4
L_else_4:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_114
    bl printf
    sub x16, x29, #608
    ldr w1, [x16]
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
    ldr x1, =str_lit_115
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_116
    bl printf
L_end_4:
L_end_3:
    sub sp, sp, #16
    mov w1, #2024
    sub x16, x29, #624
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #640
    str w1, [x16]
    sub x16, x29, #640
    ldr w1, [x16]
    cmp w1, #0
    beq L_else_5
L_then_5:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_117
    bl printf
    sub x16, x29, #624
    ldr w1, [x16]
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
    ldr x1, =str_lit_118
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_119
    bl printf
    b L_end_5
L_else_5:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_120
    bl printf
    sub x16, x29, #624
    ldr w1, [x16]
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
    ldr x1, =str_lit_121
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_122
    bl printf
L_end_5:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_123
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_124
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_125
    sub x16, x29, #656
    str x1, [x16]
    sub sp, sp, #16
    mov w1, #85
    sub x16, x29, #672
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #688
    str w1, [x16]
    sub sp, sp, #16
    mov x1, #0
    sub x16, x29, #704
    str x1, [x16]
    sub x16, x29, #672
    ldr w1, [x16]
    mov w19, w1
    mov w1, #90
    mov w20, w1
    cmp w19, w20
    cset w1, ge
    cmp w1, #0
    beq L_else_6
L_then_6:
    mov w1, #65
    sub x16, x29, #688
    str w1, [x16]
    b L_end_6
L_else_6:
    sub x16, x29, #672
    ldr w1, [x16]
    mov w19, w1
    mov w1, #80
    mov w20, w1
    cmp w19, w20
    cset w1, ge
    cmp w1, #0
    beq L_else_7
L_then_7:
    mov w1, #66
    sub x16, x29, #688
    str w1, [x16]
    b L_end_7
L_else_7:
    sub x16, x29, #672
    ldr w1, [x16]
    mov w19, w1
    mov w1, #70
    mov w20, w1
    cmp w19, w20
    cset w1, ge
    cmp w1, #0
    beq L_else_8
L_then_8:
    mov w1, #67
    sub x16, x29, #688
    str w1, [x16]
    b L_end_8
L_else_8:
    sub x16, x29, #672
    ldr w1, [x16]
    mov w19, w1
    mov w1, #60
    mov w20, w1
    cmp w19, w20
    cset w1, ge
    cmp w1, #0
    beq L_else_9
L_then_9:
    mov w1, #68
    sub x16, x29, #688
    str w1, [x16]
    b L_end_9
L_else_9:
    mov w1, #70
    sub x16, x29, #688
    str w1, [x16]
L_end_9:
L_end_8:
L_end_7:
L_end_6:
    sub x16, x29, #672
    ldr w1, [x16]
    mov w19, w1
    mov w1, #60
    mov w20, w1
    cmp w19, w20
    cset w1, ge
    cmp w1, #0
    beq L_else_10
L_then_10:
    ldr x1, =str_lit_126
    sub x16, x29, #704
    str x1, [x16]
    b L_end_10
L_else_10:
    ldr x1, =str_lit_127
    sub x16, x29, #704
    str x1, [x16]
L_end_10:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_128
    bl printf
    sub x16, x29, #656
    ldr x1, [x16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_129
    bl printf
    sub x16, x29, #672
    ldr w1, [x16]
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
    ldr x1, =str_lit_130
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_131
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_132
    bl printf
    sub x16, x29, #688
    ldr w1, [x16]
    mov w21, w1
    ldr x19, =tmpbuf
    mov x0, x19
    mov w0, w21
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_133
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_134
    bl printf
    sub x16, x29, #704
    ldr x1, [x16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_135
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_136
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_137
    sub x16, x29, #720
    str x1, [x16]
    sub sp, sp, #16
    mov w1, #72
    sub x16, x29, #736
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #67
    sub x16, x29, #752
    str w1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_138
    sub x16, x29, #768
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_139
    bl printf
    sub x16, x29, #720
    ldr x1, [x16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_140
    bl printf
    sub x16, x29, #736
    ldr w1, [x16]
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
    ldr x1, =str_lit_141
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_142
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_143
    bl printf
    sub x16, x29, #752
    ldr w1, [x16]
    mov w21, w1
    ldr x19, =tmpbuf
    mov x0, x19
    mov w0, w21
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_144
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_145
    bl printf
    sub x16, x29, #768
    ldr x1, [x16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_146
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_147
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_148
    sub x16, x29, #784
    str x1, [x16]
    sub sp, sp, #16
    mov w1, #55
    sub x16, x29, #800
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #70
    sub x16, x29, #816
    str w1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_149
    sub x16, x29, #832
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_150
    bl printf
    sub x16, x29, #784
    ldr x1, [x16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_151
    bl printf
    sub x16, x29, #800
    ldr w1, [x16]
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
    ldr x1, =str_lit_152
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_153
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_154
    bl printf
    sub x16, x29, #816
    ldr w1, [x16]
    mov w21, w1
    ldr x19, =tmpbuf
    mov x0, x19
    mov w0, w21
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_155
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_156
    bl printf
    sub x16, x29, #832
    ldr x1, [x16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_157
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_158
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_159
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_160
    sub x16, x29, #848
    str x1, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_161
    ldr d0, [x16]
    sub x16, x29, #864
    str d0, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_162
    ldr d0, [x16]
    sub x16, x29, #880
    str d0, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_163
    ldr d0, [x16]
    sub x16, x29, #896
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #864
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #880
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    fmov d8, d0
    ldr x16, =dbl_lit_164
    ldr d0, [x16]
    fmov d9, d0
    fdiv d0, d8, d9
    sub x16, x29, #912
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #864
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #912
    ldr d0, [x16]
    fmov d9, d0
    fsub d0, d8, d9
    sub x16, x29, #928
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #928
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #896
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    fmov d8, d0
    ldr x16, =dbl_lit_165
    ldr d0, [x16]
    fmov d9, d0
    fdiv d0, d8, d9
    sub x16, x29, #944
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #928
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #944
    ldr d0, [x16]
    fmov d9, d0
    fadd d0, d8, d9
    sub x16, x29, #960
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_166
    bl printf
    sub x16, x29, #848
    ldr x1, [x16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_167
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_168
    bl printf
    sub x16, x29, #864
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_169
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_170
    bl printf
    sub x16, x29, #880
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_171
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_172
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_173
    bl printf
    sub x16, x29, #928
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_174
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_175
    bl printf
    sub x16, x29, #896
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_176
    bl printf
    sub x16, x29, #944
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_177
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_178
    bl printf
    sub x16, x29, #960
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_179
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_180
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_181
    ldr d0, [x16]
    sub x16, x29, #976
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #976
    ldr d0, [x16]
    fmov d8, d0
    sub x16, x29, #960
    ldr d0, [x16]
    fmov d9, d0
    fsub d0, d8, d9
    sub x16, x29, #992
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_182
    bl printf
    sub x16, x29, #976
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_183
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_184
    bl printf
    sub x16, x29, #992
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_185
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_186
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_187
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_188
    sub x16, x29, #1008
    str x1, [x16]
    sub sp, sp, #16
    mov w1, #17
    sub x16, x29, #1024
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #1040
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #1056
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #1072
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_189
    bl printf
    sub x16, x29, #1008
    ldr x1, [x16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_190
    bl printf
    sub x16, x29, #1024
    ldr w1, [x16]
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
    ldr x1, =str_lit_191
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_192
    bl printf
    sub x16, x29, #1040
    ldr w1, [x16]
    cmp w1, #0
    beq L_else_11
L_then_11:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_193
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_194
    bl printf
    b L_end_11
L_else_11:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_195
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_196
    bl printf
L_end_11:
    sub x16, x29, #1072
    ldr w1, [x16]
    cmp w1, #0
    beq L_end_12
L_then_12:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_197
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_198
    bl printf
L_end_12:
    sub x16, x29, #1056
    ldr w1, [x16]
    cmp w1, #0
    beq L_else_13
L_then_13:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_199
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_200
    bl printf
    b L_end_13
L_else_13:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_201
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_202
    bl printf
L_end_13:
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_203
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_204
    sub x16, x29, #1088
    str x1, [x16]
    sub sp, sp, #16
    mov w1, #25
    sub x16, x29, #1104
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #1120
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #1136
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #1152
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_205
    bl printf
    sub x16, x29, #1088
    ldr x1, [x16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_206
    bl printf
    sub x16, x29, #1104
    ldr w1, [x16]
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
    ldr x1, =str_lit_207
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_208
    bl printf
    sub x16, x29, #1120
    ldr w1, [x16]
    cmp w1, #0
    beq L_else_14
L_then_14:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_209
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_210
    bl printf
    b L_end_14
L_else_14:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_211
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_212
    bl printf
L_end_14:
    sub x16, x29, #1136
    ldr w1, [x16]
    mov w19, w1
    sub x16, x29, #1120
    ldr w1, [x16]
    mov w20, w1
    and w1, w19, w20
    cmp w1, #0
    beq L_end_15
L_then_15:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_213
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_214
    bl printf
L_end_15:
    sub x16, x29, #1152
    ldr w1, [x16]
    cmp w1, #0
    beq L_end_16
L_then_16:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_215
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_216
    bl printf
L_end_16:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_217
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_218
    bl printf
L_func_exit_1:
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "=== PRUEBAS BÁSICAS APLICADAS ==="
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "\n--- CALCULADORA BÁSICA ---"
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz "Operación: "
str_lit_6:    .asciz " + "
str_lit_7:    .asciz "\n"
str_lit_8:    .asciz "Resultado: "
str_lit_9:    .asciz "\n"
str_lit_10:    .asciz "\n"
str_lit_11:    .asciz "Operación: "
str_lit_12:    .asciz " - "
str_lit_13:    .asciz "\n"
str_lit_14:    .asciz "Resultado: "
str_lit_15:    .asciz "\n"
str_lit_16:    .asciz "\n"
str_lit_17:    .asciz "Operación: "
str_lit_18:    .asciz " * "
str_lit_19:    .asciz "\n"
str_lit_20:    .asciz "Resultado: "
str_lit_21:    .asciz "\n"
str_lit_22:    .asciz "\n"
dbl_lit_23:    .double 144.0
str_lit_24:    .asciz "Operación: "
str_lit_25:    .asciz " / "
str_lit_26:    .asciz "\n"
str_lit_27:    .asciz "Resultado: "
str_lit_28:    .asciz "\n"
str_lit_29:    .asciz "\n"
str_lit_30:    .asciz "Operación: "
str_lit_31:    .asciz " % "
str_lit_32:    .asciz "\n"
str_lit_33:    .asciz "Resultado: "
str_lit_34:    .asciz "\n"
str_lit_35:    .asciz "\n"
str_lit_36:    .asciz "Operación: "
str_lit_37:    .asciz " - "
str_lit_38:    .asciz "\n"
str_lit_39:    .asciz "Resultado: "
str_lit_40:    .asciz "\n"
str_lit_41:    .asciz "\n"
str_lit_42:    .asciz "Operación: "
str_lit_43:    .asciz " >> "
str_lit_44:    .asciz "\n"
str_lit_45:    .asciz "Resultado: "
str_lit_46:    .asciz " (1110)"
str_lit_47:    .asciz "\n"
str_lit_48:    .asciz "\n"
str_lit_49:    .asciz "\n--- CONVERSIONES DE TEMPERATURA ---"
str_lit_50:    .asciz "\n"
dbl_lit_51:    .double 32.0
dbl_lit_52:    .double 32.0
dbl_lit_53:    .double 5.0
dbl_lit_54:    .double 9.0
str_lit_55:    .asciz "°F = "
str_lit_56:    .asciz "°C"
str_lit_57:    .asciz "\n"
dbl_lit_58:    .double 100.0
dbl_lit_59:    .double 9.0
dbl_lit_60:    .double 5.0
dbl_lit_61:    .double 32.0
str_lit_62:    .asciz "°C = "
str_lit_63:    .asciz "°F"
str_lit_64:    .asciz "\n"
dbl_lit_65:    .double 25.0
dbl_lit_66:    .double 9.0
dbl_lit_67:    .double 5.0
dbl_lit_68:    .double 32.0
str_lit_69:    .asciz "°C = "
str_lit_70:    .asciz "°F"
str_lit_71:    .asciz "\n"
str_lit_72:    .asciz "\r--- CÁLCULOS GEOMÉTRICOS ---"
str_lit_73:    .asciz "\n"
dbl_lit_74:    .double 5.0
dbl_lit_75:    .double 8.0
dbl_lit_76:    .double 2.0
str_lit_77:    .asciz "Rectángulo: "
str_lit_78:    .asciz "m x "
str_lit_79:    .asciz "m"
str_lit_80:    .asciz "\n"
str_lit_81:    .asciz "Área: "
str_lit_82:    .asciz " m²"
str_lit_83:    .asciz "\n"
str_lit_84:    .asciz "Perímetro: "
str_lit_85:    .asciz " m"
str_lit_86:    .asciz "\n"
str_lit_87:    .asciz "\n"
dbl_lit_88:    .double 3.5
dbl_lit_89:    .double 3.14159
dbl_lit_90:    .double 2.0
str_lit_91:    .asciz "Círculo: radio "
str_lit_92:    .asciz "m"
str_lit_93:    .asciz "\n"
str_lit_94:    .asciz "Área: "
str_lit_95:    .asciz " m²"
str_lit_96:    .asciz "\n"
str_lit_97:    .asciz "Circunferencia: "
str_lit_98:    .asciz " m"
str_lit_99:    .asciz "\n"
str_lit_100:    .asciz "\r\n--- VALIDACIONES NUMÉRICAS ---"
str_lit_101:    .asciz "\n"
str_lit_102:    .asciz "El número "
str_lit_103:    .asciz " es par"
str_lit_104:    .asciz "\n"
str_lit_105:    .asciz "El número "
str_lit_106:    .asciz " es impar"
str_lit_107:    .asciz "\n"
str_lit_108:    .asciz "El número "
str_lit_109:    .asciz " es positivo"
str_lit_110:    .asciz "\n"
str_lit_111:    .asciz "El número "
str_lit_112:    .asciz " es negativo"
str_lit_113:    .asciz "\n"
str_lit_114:    .asciz "El número "
str_lit_115:    .asciz " es neutro"
str_lit_116:    .asciz "\n"
str_lit_117:    .asciz "El año "
str_lit_118:    .asciz " es bisiesto"
str_lit_119:    .asciz "\n"
str_lit_120:    .asciz "El año "
str_lit_121:    .asciz " no es bisiesto"
str_lit_122:    .asciz "\n"
str_lit_123:    .asciz "\r\n\r\n--- SISTEMA DE CALIFICACIONES ---"
str_lit_124:    .asciz "\n"
str_lit_125:    .asciz "Juan"
str_lit_126:    .asciz "Aprobado"
str_lit_127:    .asciz "Reprobado"
str_lit_128:    .asciz "Estudiante "
str_lit_129:    .asciz ": "
str_lit_130:    .asciz " puntos"
str_lit_131:    .asciz "\n"
str_lit_132:    .asciz "Calificación: "
str_lit_133:    .asciz "\n"
str_lit_134:    .asciz "Estado: "
str_lit_135:    .asciz "\n"
str_lit_136:    .asciz "\n"
str_lit_137:    .asciz "María"
str_lit_138:    .asciz "Aprobado"
str_lit_139:    .asciz "Estudiante "
str_lit_140:    .asciz ": "
str_lit_141:    .asciz " puntos"
str_lit_142:    .asciz "\n"
str_lit_143:    .asciz "Calificación: "
str_lit_144:    .asciz "\n"
str_lit_145:    .asciz "Estado: "
str_lit_146:    .asciz "\n"
str_lit_147:    .asciz "\n"
str_lit_148:    .asciz "Pedro"
str_lit_149:    .asciz "Reprobado"
str_lit_150:    .asciz "Estudiante "
str_lit_151:    .asciz ": "
str_lit_152:    .asciz " puntos"
str_lit_153:    .asciz "\n"
str_lit_154:    .asciz "Calificación: "
str_lit_155:    .asciz "\n"
str_lit_156:    .asciz "Estado: "
str_lit_157:    .asciz "\n"
str_lit_158:    .asciz "\n--- CÁLCULO DE COMPRA ---"
str_lit_159:    .asciz "\n"
str_lit_160:    .asciz "Laptop"
dbl_lit_161:    .double 800.0
dbl_lit_162:    .double 15.0
dbl_lit_163:    .double 12.0
dbl_lit_164:    .double 100.0
dbl_lit_165:    .double 100.0
str_lit_166:    .asciz "Producto: "
str_lit_167:    .asciz "\n"
str_lit_168:    .asciz "Precio: $"
str_lit_169:    .asciz "\n"
str_lit_170:    .asciz "Descuento: "
str_lit_171:    .asciz "%"
str_lit_172:    .asciz "\n"
str_lit_173:    .asciz "Precio final: $"
str_lit_174:    .asciz "\n"
str_lit_175:    .asciz "IVA ("
str_lit_176:    .asciz "%): $"
str_lit_177:    .asciz "\n"
str_lit_178:    .asciz "Total a pagar: $"
str_lit_179:    .asciz "\n"
str_lit_180:    .asciz "\n"
dbl_lit_181:    .double 800.0
str_lit_182:    .asciz "Dinero entregado: $"
str_lit_183:    .asciz "\n"
str_lit_184:    .asciz "Cambio: $"
str_lit_185:    .asciz "\n"
str_lit_186:    .asciz "\n--- ANÁLISIS DE EDAD ---"
str_lit_187:    .asciz "\n"
str_lit_188:    .asciz "Ana"
str_lit_189:    .asciz "Persona: "
str_lit_190:    .asciz ", "
str_lit_191:    .asciz " años"
str_lit_192:    .asciz "\n"
str_lit_193:    .asciz "Es mayor de edad"
str_lit_194:    .asciz "\n"
str_lit_195:    .asciz "Es menor de edad"
str_lit_196:    .asciz "\n"
str_lit_197:    .asciz "Puede estudiar preparatoria"
str_lit_198:    .asciz "\n"
str_lit_199:    .asciz "Puede votar"
str_lit_200:    .asciz "\n"
str_lit_201:    .asciz "No puede votar"
str_lit_202:    .asciz "\n"
str_lit_203:    .asciz "\n"
str_lit_204:    .asciz "Carlos"
str_lit_205:    .asciz "Persona: "
str_lit_206:    .asciz ", "
str_lit_207:    .asciz " años"
str_lit_208:    .asciz "\n"
str_lit_209:    .asciz "Es mayor de edad"
str_lit_210:    .asciz "\n"
str_lit_211:    .asciz "Es menor de edad"
str_lit_212:    .asciz "\n"
str_lit_213:    .asciz "Puede votar y trabajar"
str_lit_214:    .asciz "\n"
str_lit_215:    .asciz "Puede obtener licencia"
str_lit_216:    .asciz "\n"
str_lit_217:    .asciz "\n=== FIN PRUEBAS BÁSICAS ==="
str_lit_218:    .asciz "\n"

// --- Variables globales ---
g_num1:    .quad 25
g_num2:    .quad 17
g_suma:    .quad 0
g_cantidad:    .quad 100
g_gastado:    .quad 35
g_restante:    .quad 0
g_docenas:    .quad 12
g_huevos:    .quad 8
g_totalHuevos:    .quad 0
g_totalPagar:    .quad 0
g_personas:    .quad 12
g_porPersona:    .quad 0
g_diasMes:    .quad 29
g_semana:    .quad 7
g_sobrante:    .quad 0
g_letraCalc:    .quad 117
g_letracalc2:    .quad 117
g_resultadoLetras:    .quad 0
g_a:    .quad 0
g_b:    .quad 1
g_resultadoBitABit:    .quad 0
g_fahrenheit:    .quad 0
g_celsius:    .quad 0
g_tempCelsius:    .quad 0
g_tempFahrenheit:    .quad 0
g_temperatura:    .quad 0
g_enFahrenheit:    .quad 0
g_largo:    .quad 0
g_ancho:    .quad 0
g_area:    .quad 0
g_perimetro:    .quad 0
g_radio:    .quad 0
g_pi:    .quad 0
g_areaCirculo:    .quad 0
g_circunferencia:    .quad 0
g_numero:    .quad 15
g_esPar:    .quad 0
g_valor:    .quad 0
g_anio:    .quad 2024
g_bisiesto:    .quad 0
g_nombre1:    .quad 0
g_puntos1:    .quad 85
g_letra1:    .quad 0
g_estado1:    .quad 0
g_nombre2:    .quad 0
g_puntos2:    .quad 72
g_letra2:    .quad 117
g_estado2:    .quad 0
g_nombre3:    .quad 0
g_puntos3:    .quad 55
g_letra3:    .quad 117
g_estado3:    .quad 0
g_producto:    .quad 0
g_precio:    .quad 0
g_descuentoPorcentaje:    .quad 0
g_ivaPorcentaje:    .quad 0
g_montoDescuento:    .quad 0
g_precioConDescuento:    .quad 0
g_montoIva:    .quad 0
g_total:    .quad 0
g_dineroEntregado:    .quad 0
g_cambio:    .quad 0
g_nombrePersona1:    .quad 0
g_edad1:    .quad 17
g_mayorEdad1:    .quad 0
g_puedeVotar1:    .quad 0
g_puedeEstudiar1:    .quad 0
g_nombrePersona2:    .quad 0
g_edad2:    .quad 25
g_mayorEdad2:    .quad 0
g_puedeTrabajar2:    .quad 0
g_puedeLicencia2:    .quad 0
