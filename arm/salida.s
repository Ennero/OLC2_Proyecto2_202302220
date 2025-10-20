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

    sub sp, sp, #16
    mov w1, #3
    str w1, [x29, -16]
    sub sp, sp, #16
    mov w1, #2
    str w1, [x29, -32]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    mov w1, #3
    mov w19, w1
    mov w1, #342
    mov w20, w1
    mul w1, w19, w20
    mov w19, w1
    mov w1, #3
    mov w19, w1
    mov w1, #65
    mov w19, w1
    mov w1, #2
    mov w20, w1
    add w1, w19, w20
    mov w20, w1
    mul w1, w19, w20
    mov w20, w1
    add w1, w19, w20
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    sub sp, sp, #16
    mov w1, #10
    str w1, [x29, -48]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -48]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    mov w1, #20
    str w1, [x29, -64]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -64]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -48]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    ldr w1, [x29, -32]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    add sp, sp, #32
L_func_exit_4:

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
