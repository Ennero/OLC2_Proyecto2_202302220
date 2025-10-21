.data

// Cadenas de formato para printf (sin salto de línea) 
fmt_int:        .asciz "%d"
fmt_double:     .asciz "%f"
fmt_string:     .asciz "%s"
fmt_char:       .asciz "%c"

true_str:       .asciz "true"
false_str:      .asciz "false"

null_str:       .asciz "null"

empty_str:      .asciz ""

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

// join_array_strings(x0=arr_ptr, x1=delim) -> x0=tmpbuf
join_array_strings:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #48
    stp x19, x20, [sp, #0]
    stp x21, x22, [sp, #16]
    stp x23, x24, [sp, #32]
    mov x24, x0
    mov x23, x1
    cbnz x24, 0f
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldp x23, x24, [sp, #32]
    ldp x21, x22, [sp, #16]
    ldp x19, x20, [sp, #0]
    add sp, sp, #48
    ldp x29, x30, [sp], 16
    ret
0:
    cbnz x23, 9f
    ldr x23, =empty_str
9:
    ldr w12, [x24]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x24, #8
    ldr w19, [x18]
    add x21, x24, x17
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    mov w20, #0
1:
    cmp w20, w19
    b.ge 2f
    // if i>0 append delim
    cbz w20, 3f
    // Reload x0 with tmpbuf before strcat (x0 is caller-saved)
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
3:
    // load element ptr from data base (x21) + i*8
    add x22, x21, x20, lsl #3
    ldr x22, [x22]
    cbnz x22, 4f
    ldr x22, =null_str
4:
    // Append element string (reload x0)
    ldr x0, =tmpbuf
    mov x1, x22
    bl strcat
    add w20, w20, #1
    b 1b
2:
    ldp x23, x24, [sp, #32]
    ldp x21, x22, [sp, #16]
    ldp x19, x20, [sp, #0]
    add sp, sp, #48
    ldp x29, x30, [sp], 16
    ret

// join_array_ints(x0=arr_ptr, x1=delim) -> x0=tmpbuf
join_array_ints:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #112
    stp x19, x20, [sp, #0]
    stp x21, x22, [sp, #16]
    stp x23, x24, [sp, #32]
    mov x24, x0
    mov x23, x1
    cbnz x24, 0f
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldp x23, x24, [sp, #32]
    ldp x21, x22, [sp, #16]
    ldp x19, x20, [sp, #0]
    add sp, sp, #112
    ldp x29, x30, [sp], 16
    ret
0:
    cbnz x23, 9f
    ldr x23, =empty_str
9:
    ldr w12, [x24]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x24, #8
    ldr w19, [x18]
    add x21, x24, x17
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    mov w20, #0
1:
    cmp w20, w19
    b.ge 2f
    cbz w20, 3f
    // Reload x0 with tmpbuf before strcat (x0 is caller-saved)
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
3:
    add x22, x21, x20, lsl #2
    ldr w22, [x22]
    add x0, sp, #48
    ldr x1, =fmt_int
    mov w2, w22
    bl sprintf
    add x1, sp, #48
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    add w20, w20, #1
    b 1b
2:
    ldp x23, x24, [sp, #32]
    ldp x21, x22, [sp, #16]
    ldp x19, x20, [sp, #0]
    add sp, sp, #112
    ldp x29, x30, [sp], 16
    ret

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    sub sp, sp, #1024
    sub sp, sp, #16
    mov w1, #5
    sub x16, x29, #16
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #5
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #10
    sub x16, x29, #48
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #32
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
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #32
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
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
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
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
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
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #32
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
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
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
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    ldr x16, =dbl_lit_9
    ldr d0, [x16]
    sub x16, x29, #64
    str d0, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_10
    ldr d0, [x16]
    sub x16, x29, #80
    str d0, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_11
    ldr d0, [x16]
    sub x16, x29, #96
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    sub x16, x29, #64
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #80
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    add sp, sp, #16
    fcmp d8, d9
    cset w1, eq
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    sub x16, x29, #64
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #96
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    add sp, sp, #16
    fcmp d8, d9
    cset w1, ne
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    sub x16, x29, #64
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #96
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    add sp, sp, #16
    fcmp d8, d9
    cset w1, lt
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    sub x16, x29, #96
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #64
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    add sp, sp, #16
    fcmp d8, d9
    cset w1, gt
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_17
    sub x16, x29, #112
    str x1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_17
    sub x16, x29, #128
    str x1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_18
    sub x16, x29, #144
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_20
    bl printf
    sub x16, x29, #112
    ldr x1, [x16]
    mov x19, x1
    sub x16, x29, #128
    ldr x1, [x16]
    mov x20, x1
    cmp x19, #0
    beq 1f
    cmp x20, #0
    beq 1f
    mov x0, x19
    mov x1, x20
    bl strcmp
    cmp w0, #0
    cset w1, eq
    b 2f
1:
    cmp x19, x20
    cset w1, eq
2:
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_21
    bl printf
    sub x16, x29, #112
    ldr x1, [x16]
    mov x19, x1
    sub x16, x29, #144
    ldr x1, [x16]
    mov x20, x1
    cmp x19, #0
    beq 1f
    cmp x20, #0
    beq 1f
    mov x0, x19
    mov x1, x20
    bl strcmp
    cmp w0, #0
    cset w1, ne
    b 2f
1:
    cmp x19, x20
    cset w1, ne
2:
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_22
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_23
    bl printf
    // EqualsMethod: evaluar punteros de string
    // lhs
    sub x16, x29, #112
    ldr x1, [x16]
    mov x19, x1
    // rhs
    sub x16, x29, #128
    ldr x1, [x16]
    mov x20, x1
    mov x0, x19
    mov x1, x20
    bl strcmp
    cmp w0, #0
    cset w1, eq
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_24
    bl printf
    // EqualsMethod: evaluar punteros de string
    // lhs
    sub x16, x29, #112
    ldr x1, [x16]
    mov x19, x1
    // rhs
    sub x16, x29, #144
    ldr x1, [x16]
    mov x20, x1
    mov x0, x19
    mov x1, x20
    bl strcmp
    cmp w0, #0
    cset w1, eq
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_25
    sub x16, x29, #160
    str x1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_25
    sub x16, x29, #176
    str x1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_26
    sub x16, x29, #192
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_27
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_28
    bl printf
    // EqualsMethod: evaluar punteros de string
    // lhs
    sub x16, x29, #160
    ldr x1, [x16]
    mov x19, x1
    // rhs
    sub x16, x29, #176
    ldr x1, [x16]
    mov x20, x1
    mov x0, x19
    mov x1, x20
    bl strcmp
    cmp w0, #0
    cset w1, eq
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_29
    bl printf
    // EqualsMethod: evaluar punteros de string
    // lhs
    sub x16, x29, #160
    ldr x1, [x16]
    mov x19, x1
    // rhs
    sub x16, x29, #192
    ldr x1, [x16]
    mov x20, x1
    mov x0, x19
    mov x1, x20
    bl strcmp
    cmp w0, #0
    cset w1, eq
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_1:
    add sp, sp, #1024
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "Comparación de enteros:"
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "a == b: "
str_lit_4:    .asciz "a != b: "
str_lit_5:    .asciz "a < c: "
str_lit_6:    .asciz "a > c: "
str_lit_7:    .asciz "a <= b: "
str_lit_8:    .asciz "a >= c: "
dbl_lit_9:    .double 5.5
dbl_lit_10:    .double 5.5
dbl_lit_11:    .double 10.5
str_lit_12:    .asciz "\nComparación de valores flotantes:"
str_lit_13:    .asciz "f1 == f2: "
str_lit_14:    .asciz "f1 != f3: "
str_lit_15:    .asciz "f1 < f3: "
str_lit_16:    .asciz "f3 > f1: "
str_lit_17:    .asciz "hola"
str_lit_18:    .asciz "mundo"
str_lit_19:    .asciz "\nComparación de strings:"
str_lit_20:    .asciz "x == y: "
str_lit_21:    .asciz "x != z: "
str_lit_22:    .asciz "\nMétodo equals para strings:"
str_lit_23:    .asciz "x.equals(y): "
str_lit_24:    .asciz "x.equals(z): "
str_lit_25:    .asciz "Hola Mundo"
str_lit_26:    .asciz "Adiós"
str_lit_27:    .asciz "\nMás pruebas con equals:"
str_lit_28:    .asciz "mensaje1.equals(mensaje2): "
str_lit_29:    .asciz "mensaje1.equals(mensaje3): "

// --- Variables globales ---
g_a:    .quad 5
g_b:    .quad 5
g_c:    .quad 10
g_f1:    .quad 0
g_f2:    .quad 0
g_f3:    .quad 0
g_x:    .quad 0
g_y:    .quad 0
g_z:    .quad 0
g_mensaje1:    .quad 0
g_mensaje2:    .quad 0
g_mensaje3:    .quad 0
.data
