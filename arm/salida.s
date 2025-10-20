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
// x0 = dims (w0), x1 = ptr a sizes[int32] -> retorna x0 puntero a arreglo de elementos de 4 bytes
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
    mov w12, #0
L_arr_prod_loop:
    cmp w12, w19
    b.ge L_arr_prod_done
    add x14, x20, x12, uxtw #2
    ldr w13, [x14]
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

// x0 = dims (w0), x1 = ptr a sizes[int32] -> retorna x0 puntero a arreglo de elementos de 8 bytes
new_array_flat_ptr:
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
    mov w12, #0
L_arrp_prod_loop:
    cmp w12, w19
    b.ge L_arrp_prod_done
    add x14, x20, x12, uxtw #2
    ldr w13, [x14]
    uxtw x13, w13
    mul x21, x21, x13
    add w12, w12, #1
    b L_arrp_prod_loop
L_arrp_prod_done:
    mov x15, #8
    uxtw x16, w19
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    mov x27, x17
    lsl x18, x21, #3
    add x22, x17, x18
    mov x0, x22
    bl malloc
    mov x23, x0
    str w19, [x23]
    add x24, x23, #8
    mov w12, #0
L_arrp_store_sizes:
    cmp w12, w19
    b.ge L_arrp_sizes_done
    add x14, x20, x12, uxtw #2
    ldr w13, [x14]
    add x25, x24, x12, uxtw #2
    str w13, [x25]
    add w12, w12, #1
    b L_arrp_store_sizes
L_arrp_sizes_done:
    add x26, x23, x27
    mov x25, #0
L_arrp_zero_loop:
    cmp x25, x21
    b.ge L_arrp_zero_done
    add x28, x26, x25, lsl #3
    mov x14, xzr
    str x14, [x28]
    add x25, x25, #1
    b L_arrp_zero_loop
L_arrp_zero_done:
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

// x0 = arr_ptr, x1 = indices ptr, w2 = num_indices -> x0 = puntero a elemento de 8 bytes
array_element_addr_ptr:
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
L_lin_outer_p:
    cmp w20, w11
    b.ge L_lin_done_p
    add x21, x10, x20, uxtw #2
    ldr w22, [x21]
    uxtw x22, w22
    mov x23, #1
    add w24, w20, #1
L_lin_stride_p:
    cmp w24, w12
    b.ge L_lin_stride_done_p
    add x25, x18, x24, uxtw #2
    ldr w26, [x25]
    uxtw x26, w26
    mul x23, x23, x26
    add w24, w24, #1
    b L_lin_stride_p
L_lin_stride_done_p:
    madd x19, x22, x23, x19
    add w20, w20, #1
    b L_lin_outer_p
L_lin_done_p:
    add x0, x9, x17
    add x0, x0, x19, lsl #3
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
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #16
    str x0, [x16]
    add sp, sp, #16
    sub x16, x29, #16
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #0
    add x20, x19, x21, lsl #2
    mov w1, #10
    str w1, [x20]
    sub x16, x29, #16
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #1
    add x20, x19, x21, lsl #2
    mov w1, #20
    str w1, [x20]
    sub x16, x29, #16
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #2
    add x20, x19, x21, lsl #2
    mov w1, #30
    str w1, [x20]
    sub x16, x29, #16
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #3
    add x20, x19, x21, lsl #2
    mov w1, #40
    str w1, [x20]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
    str w1, [sp, #0]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #32
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #65
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #69
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #73
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #79
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #85
    str w1, [x0]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldrb w1, [x0]
    add sp, sp, #16
    mov w0, w1
    bl char_to_utf8
    mov x1, x0
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #99
    str w1, [x0]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
    str w1, [sp, #0]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #48
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #10
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #20
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #30
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #40
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #50
    str w1, [x0]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub x16, x29, #64
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    sub x16, x29, #64
    ldr w1, [x16]
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #80
    str x0, [x16]
    add sp, sp, #16
    sub x16, x29, #80
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #0
    add x20, x19, x21, lsl #2
    mov w1, #2
    str w1, [x20]
    sub x16, x29, #80
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #1
    add x20, x19, x21, lsl #2
    mov w1, #3
    str w1, [x20]
    sub x16, x29, #80
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #2
    add x20, x19, x21, lsl #2
    mov w1, #5
    str w1, [x20]
    sub x16, x29, #80
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #3
    add x20, x19, x21, lsl #2
    mov w1, #7
    str w1, [x20]
    sub x16, x29, #80
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #4
    add x20, x19, x21, lsl #2
    mov w1, #11
    str w1, [x20]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_17
    bl printf
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_18
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    sub x16, x29, #96
    str x0, [x16]
    add sp, sp, #16
    sub x16, x29, #96
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #0
    add x20, x19, x21, lsl #3
    ldr x1, =str_lit_19
    str x1, [x20]
    sub x16, x29, #96
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #1
    add x20, x19, x21, lsl #3
    ldr x1, =str_lit_20
    str x1, [x20]
    sub x16, x29, #96
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #2
    add x20, x19, x21, lsl #3
    ldr x1, =str_lit_21
    str x1, [x20]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_22
    bl printf
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr x1, [x0]
    add sp, sp, #16
    cmp x1, #0
    ldr x16, =str_lit_23
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_24
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #112
    str x0, [x16]
    add sp, sp, #16
    sub x16, x29, #112
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #0
    add x20, x19, x21, lsl #2
    mov w1, #10
    str w1, [x20]
    sub x16, x29, #112
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #1
    add x20, x19, x21, lsl #2
    mov w1, #20
    str w1, [x20]
    sub x16, x29, #112
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #2
    add x20, x19, x21, lsl #2
    mov w1, #30
    str w1, [x20]
    sub x16, x29, #112
    ldr x19, [x16]
    ldr w12, [x19]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x19, x19, x17
    mov x21, #3
    add x20, x19, x21, lsl #2
    mov w1, #40
    str w1, [x20]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_25
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #112
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_26
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_27
    bl printf
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp, #0]
    sub x16, x29, #112
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_28
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
    str w1, [sp, #0]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #128
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #10
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #20
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #30
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #40
    str w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    mov w1, #50
    str w1, [x0]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_29
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_30
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_31
    bl printf
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_32
    bl printf
L_func_exit_1:
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "Primer número: "
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "Último número: "
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz "Vocal en posición 2: "
str_lit_6:    .asciz "\n"
str_lit_7:    .asciz "Nuevo valor en nums[1]: "
str_lit_8:    .asciz "\n"
str_lit_9:    .asciz "numeros[0] = "
str_lit_10:    .asciz "\n"
str_lit_11:    .asciz "numeros[4] = "
str_lit_12:    .asciz "\n"
str_lit_13:    .asciz "x = "
str_lit_14:    .asciz "\n"
str_lit_15:    .asciz "primos[0] = "
str_lit_16:    .asciz "\n"
str_lit_17:    .asciz "primos[4] = "
str_lit_18:    .asciz "\n"
str_lit_19:    .asciz "Ana"
str_lit_20:    .asciz "Luis"
str_lit_21:    .asciz "Elena"
str_lit_22:    .asciz "nombres[1] = "
str_lit_23:    .asciz "null"
str_lit_24:    .asciz "\n"
str_lit_25:    .asciz "Primer número: "
str_lit_26:    .asciz "\n"
str_lit_27:    .asciz "Último número: "
str_lit_28:    .asciz "\n"
str_lit_29:    .asciz "numeros[0] = "
str_lit_30:    .asciz "\n"
str_lit_31:    .asciz "numeros[4] = "
str_lit_32:    .asciz "\n"

// --- Variables globales ---
g_x:    .quad 0
