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
    mov x15, #8
    uxtw x16, w19
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    mov x27, x17
    lsl x18, x21, #2
    add x22, x17, x18
    mov x0, x22
    bl malloc
    mov x23, x0
    str w19, [x23]
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
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    mov x19, #0
    mov w20, #0
L_lin_outer:
    cmp w20, w11
    b.ge L_lin_done
    add x21, x10, x20, uxtw #2
    ldr w22, [x21]
    uxtw x22, w22
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
    mov w1, #42
    sub x16, x29, #16
    str w1, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_3
    ldr d0, [x16]
    sub x16, x29, #32
    str d0, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_4
    ldr d0, [x16]
    sub x16, x29, #48
    str d0, [x16]
    sub sp, sp, #16
    mov w1, #65
    sub x16, x29, #64
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #1
    sub x16, x29, #80
    str w1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_5
    sub x16, x29, #96
    str x1, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_6
    ldr d0, [x16]
    sub x16, x29, #112
    str d0, [x16]
    sub sp, sp, #16
    mov w1, #100
    sub x16, x29, #128
    str w1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_7
    sub x16, x29, #144
    str x1, [x16]
    // reasignación a constante ignorada en codegen
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    sub x16, x29, #144
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_8
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    sub x16, x29, #112
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
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
    ldr x1, =str_lit_13
    bl printf
    mov w1, #100
    sub x16, x29, #16
    str w1, [x16]
    ldr x16, =dbl_lit_14
    ldr d0, [x16]
    sub x16, x29, #32
    str d0, [x16]
    mov w1, #90
    sub x16, x29, #64
    str w1, [x16]
    mov w1, #0
    sub x16, x29, #80
    str w1, [x16]
    ldr x1, =str_lit_15
    sub x16, x29, #96
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_17
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_18
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
    ldr x1, =str_lit_19
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_20
    bl printf
    sub x16, x29, #32
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    mov x1, x19
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
    sub x16, x29, #64
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
    ldr x1, =str_lit_23
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_24
    bl printf
    sub x16, x29, #80
    ldr w1, [x16]
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_25
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_26
    bl printf
    sub x16, x29, #96
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_27
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_28
    bl printf
    sub sp, sp, #16
    mov w1, #25
    sub x16, x29, #160
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #7
    sub x16, x29, #176
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_29
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_30
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_31
    bl printf
    sub x16, x29, #160
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
    ldr x1, =str_lit_33
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_34
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
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
    ldr x1, =str_lit_35
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_36
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
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
    ldr x1, =str_lit_37
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_38
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
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
    ldr x1, =str_lit_39
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_40
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w1, w19, w1
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
    ldr x1, =str_lit_41
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_42
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w21, w19, w1
    msub w1, w21, w1, w19
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_44
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_45
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_46
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, gt
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_47
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_48
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_49
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_50
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_51
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_52
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, le
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_53
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_54
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_55
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_56
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #176
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ne
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_57
    bl printf
    sub sp, sp, #16
    mov w1, #1
    sub x16, x29, #192
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #208
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_58
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_59
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_60
    bl printf
    sub x16, x29, #192
    ldr w1, [x16]
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_61
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_62
    bl printf
    sub x16, x29, #208
    ldr w1, [x16]
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_63
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_64
    bl printf
    sub x16, x29, #192
    ldr w1, [x16]
    mov w19, w1
    sub x16, x29, #208
    ldr w1, [x16]
    mov w20, w1
    and w1, w19, w20
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_65
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_66
    bl printf
    sub x16, x29, #192
    ldr w1, [x16]
    mov w19, w1
    sub x16, x29, #208
    ldr w1, [x16]
    mov w20, w1
    orr w1, w19, w20
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_67
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_68
    bl printf
    sub x16, x29, #192
    ldr w1, [x16]
    eor w1, w1, #1
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_69
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_70
    bl printf
    sub x16, x29, #208
    ldr w1, [x16]
    eor w1, w1, #1
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_71
    bl printf
    sub sp, sp, #16
    mov w1, #12
    sub x16, x29, #224
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #10
    sub x16, x29, #240
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_72
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_73
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_74
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
    ldr x1, =str_lit_75
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_76
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_77
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
    ldr x1, =str_lit_78
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_79
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_80
    bl printf
    sub x16, x29, #224
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #240
    ldr w1, [x16]
    mov w20, w1
    ldr w19, [sp]
    add sp, sp, #16
    and w1, w19, w20
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
    ldr x1, =str_lit_81
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_82
    bl printf
    sub x16, x29, #224
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #240
    ldr w1, [x16]
    mov w20, w1
    ldr w19, [sp]
    add sp, sp, #16
    orr w1, w19, w20
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
    ldr x1, =str_lit_83
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_84
    bl printf
    sub x16, x29, #224
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #240
    ldr w1, [x16]
    mov w20, w1
    ldr w19, [sp]
    add sp, sp, #16
    eor w1, w19, w20
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
    ldr x1, =str_lit_85
    bl printf
    sub sp, sp, #16
    mov w1, #16
    sub x16, x29, #256
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_86
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_87
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_88
    bl printf
    sub x16, x29, #256
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
    ldr x1, =str_lit_89
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_90
    bl printf
    sub x16, x29, #256
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #2
    mov w20, w1
    ldr w19, [sp]
    add sp, sp, #16
    lsl w1, w19, w20
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
    ldr x1, =str_lit_91
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_92
    bl printf
    sub x16, x29, #256
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #2
    mov w20, w1
    ldr w19, [sp]
    add sp, sp, #16
    asr w1, w19, w20
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
    ldr x1, =str_lit_93
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_94
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_95
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_96
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_97
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_102
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_103
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_104
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_105
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_106
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_107
    bl printf
    sub sp, sp, #16
    mov x1, #0
    sub x16, x29, #272
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_108
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_109
    bl printf
    sub x16, x29, #272
    ldr x1, [x16]
    cmp x1, #0
    cset w1, eq
    cmp w1, #0
    beq L_end_2
L_then_2:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_110
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_111
    bl printf
    ldr x1, =str_lit_112
    sub x16, x29, #272
    str x1, [x16]
L_end_2:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_113
    bl printf
    sub x16, x29, #272
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_114
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_115
    bl printf
    sub sp, sp, #16
    mov x1, #0
    sub x16, x29, #288
    str x1, [x16]
    sub sp, sp, #16
    mov x1, #0
    sub x16, x29, #304
    str x1, [x16]
    sub x16, x29, #288
    ldr x1, [x16]
    cmp x1, #0
    cset w1, eq
    cmp w1, #0
    beq L_else_3
L_then_3:
    ldr x1, =str_lit_116
    sub x16, x29, #304
    str x1, [x16]
    b L_end_3
L_else_3:
    sub x16, x29, #288
    ldr x1, [x16]
    sub x16, x29, #304
    str x1, [x16]
L_end_3:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_117
    bl printf
    sub x16, x29, #304
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_118
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_119
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_120
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_121
    bl printf
    sub sp, sp, #16
    mov w1, #77
    sub x16, x29, #320
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #320
    ldr w1, [x16]
    sub x16, x29, #336
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #336
    ldr w1, [x16]
    scvtf d0, w1
    sub x16, x29, #352
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #352
    ldr d0, [x16]
    sub x16, x29, #368
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_122
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_123
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_124
    bl printf
    sub x16, x29, #320
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
    ldr x1, =str_lit_125
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
    ldr x1, =str_lit_126
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_127
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
    ldr x1, =str_lit_128
    bl printf
    sub x16, x29, #352
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_129
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_130
    bl printf
    sub x16, x29, #352
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_131
    bl printf
    sub x16, x29, #368
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_132
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_133
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_134
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_135
    ldr d0, [x16]
    sub x16, x29, #384
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #384
    ldr d0, [x16]
    sub x16, x29, #400
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #400
    ldr d0, [x16]
    fcvtzs w1, d0
    sub x16, x29, #416
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #416
    ldr w1, [x16]
    sub x16, x29, #432
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_136
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_137
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_138
    bl printf
    sub x16, x29, #384
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_139
    bl printf
    sub x16, x29, #400
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_140
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_141
    bl printf
    sub x16, x29, #400
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_142
    bl printf
    sub x16, x29, #416
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
    ldr x1, =str_lit_143
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_144
    bl printf
    sub x16, x29, #416
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
    ldr x1, =str_lit_145
    bl printf
    sub x16, x29, #432
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
    ldr x1, =str_lit_146
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_147
    bl printf
    sub sp, sp, #16
    mov w1, #50
    sub x16, x29, #448
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #416
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #336
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    ldr d8, [sp]
    scvtf d9, w1
    fmul d0, d8, d9
    add sp, sp, #16
    sub sp, sp, #16
    str d0, [sp]
    ldr x16, =dbl_lit_148
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    fdiv d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #464
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_149
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_150
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_151
    bl printf
    sub x16, x29, #464
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    mov x1, x19
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_152
    bl printf
    sub sp, sp, #16
    sub x16, x29, #416
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #336
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    ldr x16, =dbl_lit_153
    ldr d0, [x16]
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fdiv d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #480
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #480
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #480
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #496
    str d0, [x16]
    sub sp, sp, #16
    mov w1, #2
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #112
    ldr d0, [x16]
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #480
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #512
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #160
    ldr w1, [x16]
    scvtf d0, w1
    sub x16, x29, #528
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #176
    ldr w1, [x16]
    scvtf d0, w1
    sub x16, x29, #544
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #528
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #544
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #560
    str d0, [x16]
    sub sp, sp, #16
    mov w1, #2
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #528
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #544
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    fadd d0, d8, d9
    add sp, sp, #16
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #576
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_154
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_155
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_156
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
    ldr x1, =str_lit_157
    bl printf
    sub x16, x29, #496
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_158
    bl printf
    sub x16, x29, #512
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_159
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_160
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_161
    bl printf
    sub x16, x29, #528
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_162
    bl printf
    sub x16, x29, #544
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_163
    bl printf
    sub x16, x29, #560
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_164
    bl printf
    sub x16, x29, #576
    ldr d0, [x16]
    ldr x19, =tmpbuf
    mov x0, x19
    mov x1, #1024
    bl java_format_double
    ldr x0, =fmt_string
    mov x1, x19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_165
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_166
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_167
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_168
    bl printf
L_func_exit_1:
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "=== SISTEMA DE CALCULO CIENTIFICO ==="
str_lit_2:    .asciz "\n"
dbl_lit_3:    .double 3.14
dbl_lit_4:    .double 2.718281828
str_lit_5:    .asciz "Resultado"
dbl_lit_6:    .double 3.14159265359
str_lit_7:    .asciz "Calculadora Científica v1.0"
str_lit_8:    .asciz "null"
str_lit_9:    .asciz "\n"
str_lit_10:    .asciz "Constante PI: "
str_lit_11:    .asciz "\n"
str_lit_12:    .asciz "Constante máxima: "
str_lit_13:    .asciz "\n"
dbl_lit_14:    .double 5.67
str_lit_15:    .asciz "Nuevo resultado"
str_lit_16:    .asciz "\n--- VALORES ASIGNADOS ---"
str_lit_17:    .asciz "\n"
str_lit_18:    .asciz "Entero: "
str_lit_19:    .asciz "\n"
str_lit_20:    .asciz "Flotante: "
str_lit_21:    .asciz "\n"
str_lit_22:    .asciz "Carácter: "
str_lit_23:    .asciz "\n"
str_lit_24:    .asciz "Booleano: "
str_lit_25:    .asciz "\n"
str_lit_26:    .asciz "Cadena: "
str_lit_27:    .asciz "null"
str_lit_28:    .asciz "\n"
str_lit_29:    .asciz "\n--- OPERACIONES ARITMETICAS ---"
str_lit_30:    .asciz "\n"
str_lit_31:    .asciz "a = "
str_lit_32:    .asciz ", b = "
str_lit_33:    .asciz "\n"
str_lit_34:    .asciz "Suma (a + b): "
str_lit_35:    .asciz "\n"
str_lit_36:    .asciz "Resta (a - b): "
str_lit_37:    .asciz "\n"
str_lit_38:    .asciz "Multiplicación (a * b): "
str_lit_39:    .asciz "\n"
str_lit_40:    .asciz "División (a / b): "
str_lit_41:    .asciz "\n"
str_lit_42:    .asciz "Módulo (a % b): "
str_lit_43:    .asciz "\n"
str_lit_44:    .asciz "\n--- OPERACIONES RELACIONALES ---"
str_lit_45:    .asciz "\n"
str_lit_46:    .asciz "a > b: "
str_lit_47:    .asciz "\n"
str_lit_48:    .asciz "a < b: "
str_lit_49:    .asciz "\n"
str_lit_50:    .asciz "a >= b: "
str_lit_51:    .asciz "\n"
str_lit_52:    .asciz "a <= b: "
str_lit_53:    .asciz "\n"
str_lit_54:    .asciz "a == b: "
str_lit_55:    .asciz "\n"
str_lit_56:    .asciz "a != b: "
str_lit_57:    .asciz "\n"
str_lit_58:    .asciz "\n--- OPERACIONES LOGICAS ---"
str_lit_59:    .asciz "\n"
str_lit_60:    .asciz "condicion1 = "
str_lit_61:    .asciz "\n"
str_lit_62:    .asciz "condicion2 = "
str_lit_63:    .asciz "\n"
str_lit_64:    .asciz "condicion1 && condicion2: "
str_lit_65:    .asciz "\n"
str_lit_66:    .asciz "condicion1 || condicion2: "
str_lit_67:    .asciz "\n"
str_lit_68:    .asciz "!condicion1: "
str_lit_69:    .asciz "\n"
str_lit_70:    .asciz "!condicion2: "
str_lit_71:    .asciz "\n"
str_lit_72:    .asciz "\n--- OPERADORES DE BITS ---"
str_lit_73:    .asciz "\n"
str_lit_74:    .asciz "x = "
str_lit_75:    .asciz " (binario: 1100)"
str_lit_76:    .asciz "\n"
str_lit_77:    .asciz "y = "
str_lit_78:    .asciz " (binario: 1010)"
str_lit_79:    .asciz "\n"
str_lit_80:    .asciz "x & y (AND): "
str_lit_81:    .asciz "\n"
str_lit_82:    .asciz "x | y (OR): "
str_lit_83:    .asciz "\n"
str_lit_84:    .asciz "x ^ y (XOR): "
str_lit_85:    .asciz "\n"
str_lit_86:    .asciz "\n--- DESPLAZAMIENTO DE BITS ---"
str_lit_87:    .asciz "\n"
str_lit_88:    .asciz "valor = "
str_lit_89:    .asciz "\n"
str_lit_90:    .asciz "valor << 2: "
str_lit_91:    .asciz "\n"
str_lit_92:    .asciz "valor >> 2: "
str_lit_93:    .asciz "\n"
str_lit_94:    .asciz "\n--- SECUENCIAS DE ESCAPE ---"
str_lit_95:    .asciz "\n"
str_lit_96:    .asciz "Comillas dobles: \"Hola mundo\""
str_lit_97:    .asciz "\n"
str_lit_98:    .asciz "Barra invertida: \\"
str_lit_99:    .asciz "\n"
str_lit_100:    .asciz "Nueva línea:\nTexto en línea nueva"
str_lit_101:    .asciz "\n"
str_lit_102:    .asciz "Retorno de carro:\rTexto con retorno"
str_lit_103:    .asciz "\n"
str_lit_104:    .asciz "Tabulación:\t\tTexto con tab"
str_lit_105:    .asciz "\n"
str_lit_106:    .asciz "Línea antes del salto compuesto\r\nLínea después del salto compuesto"
str_lit_107:    .asciz "\n"
str_lit_108:    .asciz "\n--- MANEJO DE NULL ---"
str_lit_109:    .asciz "\n"
str_lit_110:    .asciz "La variable textoNulo es null"
str_lit_111:    .asciz "\n"
str_lit_112:    .asciz "Valor asignado después de verificar null"
str_lit_113:    .asciz "textoNulo ahora: "
str_lit_114:    .asciz "null"
str_lit_115:    .asciz "\n"
str_lit_116:    .asciz "Es null"
str_lit_117:    .asciz "Resultado condicional: "
str_lit_118:    .asciz "null"
str_lit_119:    .asciz "\n"
str_lit_120:    .asciz "\n--- WIDENING CASTING AUTOMATICO ---"
str_lit_121:    .asciz "\n"
str_lit_122:    .asciz "Casting automático progresivo:"
str_lit_123:    .asciz "\n"
str_lit_124:    .asciz "char '"
str_lit_125:    .asciz "' -> int "
str_lit_126:    .asciz "\n"
str_lit_127:    .asciz "int "
str_lit_128:    .asciz " -> float "
str_lit_129:    .asciz "\n"
str_lit_130:    .asciz "float "
str_lit_131:    .asciz " -> double "
str_lit_132:    .asciz "\n"
str_lit_133:    .asciz "\n--- NARROWING CASTING MANUAL ---"
str_lit_134:    .asciz "\n"
dbl_lit_135:    .double 75.89
str_lit_136:    .asciz "Casting manual regresivo:"
str_lit_137:    .asciz "\n"
str_lit_138:    .asciz "double "
str_lit_139:    .asciz " -> float "
str_lit_140:    .asciz "\n"
str_lit_141:    .asciz "float "
str_lit_142:    .asciz " -> int "
str_lit_143:    .asciz "\n"
str_lit_144:    .asciz "int "
str_lit_145:    .asciz " -> char '"
str_lit_146:    .asciz "'"
str_lit_147:    .asciz "\n"
dbl_lit_148:    .double 2.0
str_lit_149:    .asciz "\n--- CALCULO FINAL (SIMAULACION CÁLCULO REAL ) ---"
str_lit_150:    .asciz "\n"
str_lit_151:    .asciz "Resultado científico: "
str_lit_152:    .asciz "\n"
dbl_lit_153:    .double 10.0
str_lit_154:    .asciz "\n--- FIGURAS GEOMETRICAS ---"
str_lit_155:    .asciz "\n"
str_lit_156:    .asciz "Circulo -> radio="
str_lit_157:    .asciz " cm, area="
str_lit_158:    .asciz " cm^2, perimetro="
str_lit_159:    .asciz " cm"
str_lit_160:    .asciz "\n"
str_lit_161:    .asciz "Rectangulo -> base="
str_lit_162:    .asciz " cm, altura="
str_lit_163:    .asciz " cm, area="
str_lit_164:    .asciz " cm^2, perimetro="
str_lit_165:    .asciz " cm"
str_lit_166:    .asciz "\n"
str_lit_167:    .asciz "\n=== FIN DEL SISTEMA ==="
str_lit_168:    .asciz "\n"

// --- Variables globales ---
g_numeroEntero:    .quad 42
g_numeroFlotante:    .quad 0
g_numeroDoble:    .quad 0
g_caracter:    .quad 65
g_esVerdadero:    .quad 1
g_cadenaTexto:    .quad 0
g_PI:    .quad 0
g_CONSTANTE_MAXIMA:    .quad 100
g_MENSAJE_SISTEMA:    .quad 0
g_a:    .quad 25
g_b:    .quad 7
g_condicion1:    .quad 1
g_condicion2:    .quad 0
g_x:    .quad 12
g_y:    .quad 10
g_valorDesplazamiento:    .quad 16
g_textoNulo:    .quad 0
g_otroTextoNulo:    .quad 0
g_resultado:    .quad 0
g_letraInicial:    .quad 77
g_codigoAscii:    .quad 0
g_codigoFloat:    .quad 0
g_codigoDouble:    .quad 0
g_valorGrande:    .quad 0
g_valorMedio:    .quad 0
g_valorEntero:    .quad 0
g_caracterFinal:    .quad 0
g_variableComentada:    .quad 50
g_resultadoFinal:    .quad 0
g_radioCirculoCm:    .quad 0
g_areaCirculoCm2:    .quad 0
g_perimetroCirculoCm:    .quad 0
g_baseRectCm:    .quad 0
g_alturaRectCm:    .quad 0
g_areaRectCm2:    .quad 0
g_perimetroRectCm:    .quad 0
