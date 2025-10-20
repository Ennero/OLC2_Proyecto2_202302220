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

fn_incInt:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str w0, [x29, -16]
    ldr w1, [x29, -16]
    mov w19, w1
    mov w1, #1
    mov w20, w1
    add w1, w19, w20
    str w1, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr w1, [x29, -16]
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
    ldr x1, =str_lit_2
    bl printf
L_func_exit_1:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_flipBool:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str w0, [x29, -16]
    mov w1, #0
    str w1, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    ldr w1, [x29, -16]
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
    ldr x1, =str_lit_4
    bl printf
L_func_exit_2:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_bumpChar:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str w0, [x29, -16]
    ldr w1, [x29, -16]
    mov w19, w1
    mov w1, #1
    mov w20, w1
    add w1, w19, w20
    str w1, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    ldr w1, [x29, -16]
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
L_func_exit_3:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_mulFloat:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str d0, [x29, -16]
    ldr d0, [x29, -16]
    fmov d8, d0
    ldr x16, =dbl_lit_7
    ldr d0, [x16]
    fmov d9, d0
    fmul d0, d8, d9
    str d0, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    ldr d0, [x29, -16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
L_func_exit_4:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_widenToDouble:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str d0, [x29, -16]
    ldr d0, [x29, -16]
    fmov d8, d0
    ldr x16, =dbl_lit_10
    ldr d0, [x16]
    fmov d9, d0
    fadd d0, d8, d9
    str d0, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    ldr d0, [x29, -16]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
L_func_exit_5:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_setFirst:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str w0, [x29, -16]
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    ldr x0, [x29, -16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    ldr x0, [x29, -16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    mov w19, w1
    mov w1, #100
    mov w20, w1
    add w1, w19, w20
    str w1, [x0]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    ldr x0, [x29, -16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    ldr x1, =str_lit_14
    bl printf
L_func_exit_6:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_replaceArray:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str w0, [x29, -16]
    sub sp, sp, #16
    mov x1, #0
    str x1, [x29, -32]
    ldr w1, [x29, -32]
    str w1, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    ldr x0, [x29, -16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    ldr x1, =str_lit_16
    bl printf
L_func_exit_7:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_appendWorld:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str x0, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_17
    bl printf
    ldr x1, [x29, -16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_18
    bl printf
L_func_exit_8:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_overwriteHello:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str x0, [x29, -16]
    ldr x1, =str_lit_19
    str x1, [x29, -16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_20
    bl printf
    ldr x1, [x29, -16]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_21
    bl printf
L_func_exit_9:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_nestedString:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str x0, [x29, -16]
    ldr x1, [x29, -16]
    mov x0, x1
    bl fn_appendWorld
    mov w1, w0
L_func_exit_10:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_retInc:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    str w0, [x29, -16]
    ldr w1, [x29, -16]
    mov w19, w1
    mov w1, #1
    mov w20, w1
    add w1, w19, w20
    mov w0, w1
    b L_func_exit_11
L_func_exit_11:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_retArray:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    mov x1, #0
    str x1, [x29, -16]
    ldr w1, [x29, -16]
    mov w0, w1
    b L_func_exit_12
L_func_exit_12:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_retStr:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #16
    ldr x1, =str_lit_22
    str x1, [x29, -16]
    ldr x1, [x29, -16]
    mov x0, x1
    b L_func_exit_13
L_func_exit_13:
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_23
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_24
    bl printf
    sub sp, sp, #16
    mov w1, #10
    str w1, [x29, -16]
    sub sp, sp, #16
    mov w1, #0
    str w1, [x29, -32]
    sub sp, sp, #16
    mov w1, #65
    str w1, [x29, -48]
    sub sp, sp, #16
    ldr x16, =dbl_lit_25
    ldr d0, [x16]
    str d0, [x29, -64]
    sub sp, sp, #16
    ldr x16, =dbl_lit_26
    ldr d0, [x16]
    str d0, [x29, -80]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_27
    bl printf
    ldr w1, [x29, -16]
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
    ldr x1, =str_lit_28
    bl printf
    ldr w1, [x29, -16]
    mov w0, w1
    bl fn_incInt
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_29
    bl printf
    ldr w1, [x29, -16]
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
    ldr x1, =str_lit_30
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_31
    bl printf
    ldr w1, [x29, -32]
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
    ldr w1, [x29, -32]
    mov w0, w1
    bl fn_flipBool
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_33
    bl printf
    ldr w1, [x29, -32]
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_35
    bl printf
    ldr w1, [x29, -48]
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
    ldr x1, =str_lit_36
    bl printf
    ldr w1, [x29, -48]
    mov w0, w1
    bl fn_bumpChar
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_37
    bl printf
    ldr w1, [x29, -48]
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
    ldr x1, =str_lit_38
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_39
    bl printf
    ldr d0, [x29, -64]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_40
    bl printf
    ldr d0, [x29, -64]
    fmov d0, d0
    bl fn_mulFloat
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_41
    bl printf
    ldr d0, [x29, -64]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_42
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_43
    bl printf
    ldr d0, [x29, -80]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_44
    bl printf
    ldr d0, [x29, -80]
    fmov d0, d0
    bl fn_widenToDouble
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_45
    bl printf
    ldr d0, [x29, -80]
    ldr x19, =tmpbuf
    mov x0, x19
    ldr x1, =fmt_double
    bl sprintf
    mov x1, x19
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
    mov x1, #0
    str x1, [x29, -96]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_49
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    ldr x0, [x29, -96]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    ldr x1, =str_lit_50
    bl printf
    ldr w1, [x29, -96]
    mov w0, w1
    bl fn_setFirst
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_51
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    ldr x0, [x29, -96]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    ldr x1, =str_lit_52
    bl printf
    ldr w1, [x29, -96]
    mov w0, w1
    bl fn_replaceArray
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_53
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    ldr x0, [x29, -96]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    ldr x1, =str_lit_54
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_55
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_56
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_57
    str x1, [x29, -112]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_58
    bl printf
    ldr x1, [x29, -112]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_59
    bl printf
    ldr x1, [x29, -112]
    mov x0, x1
    bl fn_appendWorld
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_60
    bl printf
    ldr x1, [x29, -112]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_61
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_62
    str x1, [x29, -128]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_63
    bl printf
    ldr x1, [x29, -128]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_64
    bl printf
    ldr x1, =str_lit_65
    mov x0, x1
    bl fn_appendWorld
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_66
    bl printf
    ldr x1, [x29, -128]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_67
    bl printf
    mov x1, #0
    mov x0, x1
    bl fn_appendWorld
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_68
    bl printf
    ldr x1, [x29, -112]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_69
    bl printf
    ldr x1, [x29, -112]
    mov x0, x1
    bl fn_nestedString
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_70
    bl printf
    ldr x1, [x29, -112]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_71
    bl printf
    ldr x1, [x29, -112]
    mov x0, x1
    bl fn_overwriteHello
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_72
    bl printf
    ldr x1, [x29, -112]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_73
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_74
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_75
    bl printf
    mov w1, #4
    mov w0, w1
    bl fn_retInc
    mov w1, w0
    sub sp, sp, #16
    mov w1, #4
    mov w0, w1
    bl fn_retInc
    mov w1, w0
    str w1, [x29, -144]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_76
    bl printf
    ldr w1, [x29, -144]
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
    ldr x1, =str_lit_77
    bl printf
    bl fn_retArray
    mov w1, w0
    sub sp, sp, #16
    mov x1, #0
    str x1, [x29, -160]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_78
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    ldr x0, [x29, -160]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    ldr x1, =str_lit_79
    bl printf
    bl fn_retStr
    mov w1, w0
    sub sp, sp, #16
    bl fn_retStr
    mov w1, w0
    mov x1, #0
    str x1, [x29, -176]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_80
    bl printf
    ldr x1, [x29, -176]
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_81
    bl printf
L_func_exit_14:
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "incInt a= "
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "flipBool b= "
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz "bumpChar c= "
str_lit_6:    .asciz "\n"
dbl_lit_7:    .double 2.5
str_lit_8:    .asciz "mulFloat f= "
str_lit_9:    .asciz "\n"
dbl_lit_10:    .double 0.5
str_lit_11:    .asciz "widenToDouble d= "
str_lit_12:    .asciz "\n"
str_lit_13:    .asciz "setFirst arr[0]= "
str_lit_14:    .asciz "\n"
str_lit_15:    .asciz "replaceArray arr_local[0]= "
str_lit_16:    .asciz "\n"
str_lit_17:    .asciz "appendWorld s= "
str_lit_18:    .asciz "\n"
str_lit_19:    .asciz "Hello"
str_lit_20:    .asciz "overwriteHello s= "
str_lit_21:    .asciz "\n"
str_lit_22:    .asciz "X"
str_lit_23:    .asciz "-- PRIMITIVOS --"
str_lit_24:    .asciz "\n"
dbl_lit_25:    .double 1.2
dbl_lit_26:    .double 2.0
str_lit_27:    .asciz "init i= "
str_lit_28:    .asciz "\n"
str_lit_29:    .asciz "after i= "
str_lit_30:    .asciz "\n"
str_lit_31:    .asciz "init b= "
str_lit_32:    .asciz "\n"
str_lit_33:    .asciz "after b= "
str_lit_34:    .asciz "\n"
str_lit_35:    .asciz "init c= "
str_lit_36:    .asciz "\n"
str_lit_37:    .asciz "after c= "
str_lit_38:    .asciz "\n"
str_lit_39:    .asciz "init f= "
str_lit_40:    .asciz "\n"
str_lit_41:    .asciz "after f= "
str_lit_42:    .asciz "\n"
str_lit_43:    .asciz "init d= "
str_lit_44:    .asciz "\n"
str_lit_45:    .asciz "after d= "
str_lit_46:    .asciz "\n"
str_lit_47:    .asciz "-- ARREGLOS --"
str_lit_48:    .asciz "\n"
str_lit_49:    .asciz "A[0] before= "
str_lit_50:    .asciz "\n"
str_lit_51:    .asciz "A[0] after = "
str_lit_52:    .asciz "\n"
str_lit_53:    .asciz "A[0] still = "
str_lit_54:    .asciz "\n"
str_lit_55:    .asciz "-- STRINGS --"
str_lit_56:    .asciz "\n"
str_lit_57:    .asciz "Hi"
str_lit_58:    .asciz "s before= "
str_lit_59:    .asciz "\n"
str_lit_60:    .asciz "s after = "
str_lit_61:    .asciz "\n"
str_lit_62:    .asciz "Yo"
str_lit_63:    .asciz "t before= "
str_lit_64:    .asciz "\n"
str_lit_65:    .asciz "Yo"
str_lit_66:    .asciz "t after = "
str_lit_67:    .asciz "\n"
str_lit_68:    .asciz "s after2= "
str_lit_69:    .asciz "\n"
str_lit_70:    .asciz "s after3= "
str_lit_71:    .asciz "\n"
str_lit_72:    .asciz "s after4= "
str_lit_73:    .asciz "\n"
str_lit_74:    .asciz "-- RETORNOS --"
str_lit_75:    .asciz "\n"
str_lit_76:    .asciz "retInc= "
str_lit_77:    .asciz "\n"
str_lit_78:    .asciz "retArray R[0]= "
str_lit_79:    .asciz "\n"
str_lit_80:    .asciz "retStr= "
str_lit_81:    .asciz "\n"
