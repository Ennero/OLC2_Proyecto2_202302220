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
    ldr x0, =fmt_string
    ldr x1, =str_dbg_start
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_1
    mov x23, x1
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub sp, sp, #128
    ldr x1, =str_lit_2
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
    ldr x1, =str_lit_3
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
    ldr x1, =str_lit_4
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    add sp, sp, #128
    ldr x0, =tmpbuf
    bl strdup
    mov x1, x0
    sub x16, x29, #16
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    sub x16, x29, #16
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_6
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_8
    mov x23, x1
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub sp, sp, #128
    ldr x1, =str_lit_9
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
    ldr x1, =str_lit_10
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
    ldr x1, =str_lit_11
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    add sp, sp, #128
    ldr x0, =tmpbuf
    bl strdup
    mov x1, x0
    sub x16, x29, #32
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    sub x16, x29, #32
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_13
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    sub x16, x29, #48
    str x0, [x16]
    add sp, sp, #16
    sub x16, x29, #48
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
    ldr x1, =str_lit_15
    str x1, [x20]
    sub x16, x29, #48
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
    ldr x1, =str_lit_16
    str x1, [x20]
    sub x16, x29, #48
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
    ldr x1, =str_lit_17
    str x1, [x20]
    sub sp, sp, #16
    ldr x1, =str_lit_18
    mov x23, x1
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, x23
    bl join_array_strings
    bl strdup
    mov x1, x0
    sub x16, x29, #64
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_19
    bl printf
    sub x16, x29, #64
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_20
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_21
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_22
    mov x23, x1
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub sp, sp, #128
    ldr x1, =str_lit_23
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
    ldr x1, =str_lit_24
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
    ldr x1, =str_lit_25
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
    ldr x1, =str_lit_26
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    add sp, sp, #128
    ldr x0, =tmpbuf
    bl strdup
    mov x1, x0
    sub x16, x29, #80
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_27
    bl printf
    sub x16, x29, #80
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_28
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_29
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
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
    ldr x1, =str_lit_30
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
    ldr x1, =str_lit_31
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
    ldr x1, =str_lit_32
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
    mov x21, #3
    add x20, x19, x21, lsl #3
    ldr x1, =str_lit_33
    str x1, [x20]
    sub sp, sp, #16
    ldr x1, =str_lit_34
    mov x23, x1
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, x23
    bl join_array_strings
    bl strdup
    mov x1, x0
    sub x16, x29, #112
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_35
    bl printf
    sub x16, x29, #112
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_36
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_37
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    sub x16, x29, #128
    str x0, [x16]
    add sp, sp, #16
    sub x16, x29, #128
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
    ldr x1, =str_lit_38
    str x1, [x20]
    sub x16, x29, #128
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
    ldr x1, =str_lit_39
    str x1, [x20]
    sub x16, x29, #128
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
    ldr x1, =str_lit_40
    str x1, [x20]
    sub x16, x29, #128
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
    add x20, x19, x21, lsl #3
    ldr x1, =str_lit_41
    str x1, [x20]
    sub sp, sp, #16
    ldr x1, =str_lit_42
    mov x23, x1
    sub x16, x29, #128
    ldr x0, [x16]
    mov x1, x23
    bl join_array_strings
    bl strdup
    mov x1, x0
    sub x16, x29, #144
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_43
    bl printf
    sub x16, x29, #144
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_44
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_45
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_46
    mov x23, x1
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub sp, sp, #128
    ldr x1, =str_lit_47
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    add sp, sp, #128
    ldr x0, =tmpbuf
    bl strdup
    mov x1, x0
    sub x16, x29, #160
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_48
    bl printf
    sub x16, x29, #160
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_49
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_50
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    sub x16, x29, #176
    str x0, [x16]
    add sp, sp, #16
    sub x16, x29, #176
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
    ldr x1, =str_lit_51
    str x1, [x20]
    sub x16, x29, #176
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
    ldr x1, =str_lit_52
    str x1, [x20]
    sub x16, x29, #176
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
    ldr x1, =str_lit_53
    str x1, [x20]
    sub sp, sp, #16
    ldr x1, =str_lit_54
    mov x23, x1
    sub x16, x29, #176
    ldr x0, [x16]
    mov x1, x23
    bl join_array_strings
    bl strdup
    mov x1, x0
    sub x16, x29, #192
    str x1, [x16]
    sub sp, sp, #16
    // String concatenation to tmpbuf
    sub sp, sp, #128
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_55
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #192
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    add sp, sp, #128
    ldr x1, =tmpbuf
    sub x16, x29, #208
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    sub x16, x29, #208
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_56
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_57
    bl printf
    sub sp, sp, #16
    mov w1, #100
    sub sp, sp, #128
    mov w21, w1
    mov x0, sp
    ldr x1, =fmt_int
    mov w2, w21
    bl sprintf
    mov x0, sp
    bl strdup
    add sp, sp, #128
    mov x1, x0
    sub x16, x29, #224
    str x1, [x16]
    sub sp, sp, #16
    mov w1, #200
    sub sp, sp, #128
    mov w21, w1
    mov x0, sp
    ldr x1, =fmt_int
    mov w2, w21
    bl sprintf
    mov x0, sp
    bl strdup
    add sp, sp, #128
    mov x1, x0
    sub x16, x29, #240
    str x1, [x16]
    sub sp, sp, #16
    mov w1, #300
    sub sp, sp, #128
    mov w21, w1
    mov x0, sp
    ldr x1, =fmt_int
    mov w2, w21
    bl sprintf
    mov x0, sp
    bl strdup
    add sp, sp, #128
    mov x1, x0
    sub x16, x29, #256
    str x1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_58
    mov x23, x1
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub sp, sp, #128
    sub x16, x29, #224
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
    sub x16, x29, #240
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =tmpbuf
    mov x1, x23
    bl strcat
    sub x16, x29, #256
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    add sp, sp, #128
    ldr x0, =tmpbuf
    bl strdup
    mov x1, x0
    sub x16, x29, #272
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_59
    bl printf
    sub x16, x29, #272
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_60
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_61
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    sub x16, x29, #288
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    ldr x1, =str_lit_62
    mov x23, x1
    sub x16, x29, #288
    ldr x0, [x16]
    mov x1, x23
    bl join_array_strings
    bl strdup
    mov x1, x0
    sub x16, x29, #304
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_63
    bl printf
    sub x16, x29, #304
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_64
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_65
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_66
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    sub x16, x29, #320
    str x0, [x16]
    add sp, sp, #16
    sub x16, x29, #320
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
    ldr x1, =str_lit_67
    str x1, [x20]
    sub x16, x29, #320
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
    ldr x1, =str_lit_68
    str x1, [x20]
    sub x16, x29, #320
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
    ldr x1, =str_lit_69
    str x1, [x20]
    sub sp, sp, #16
    ldr x1, =str_lit_70
    mov x23, x1
    sub x16, x29, #320
    ldr x0, [x16]
    mov x1, x23
    bl join_array_strings
    bl strdup
    mov x1, x0
    sub x16, x29, #336
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    ldr x0, =fmt_string
    ldr x1, =str_lit_71
    bl printf
    sub x16, x29, #336
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_72
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_73
    bl printf
L_func_exit_1:
    add sp, sp, #1024
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "-"
str_lit_2:    .asciz "2025"
str_lit_3:    .asciz "08"
str_lit_4:    .asciz "03"
str_lit_5:    .asciz "Fecha formateada: "
str_lit_6:    .asciz "null"
str_lit_7:    .asciz "\n"
str_lit_8:    .asciz " | "
str_lit_9:    .asciz "10"
str_lit_10:    .asciz "20"
str_lit_11:    .asciz "30"
str_lit_12:    .asciz "Números separados: "
str_lit_13:    .asciz "null"
str_lit_14:    .asciz "\n"
str_lit_15:    .asciz "manzana"
str_lit_16:    .asciz "banana"
str_lit_17:    .asciz "cereza"
str_lit_18:    .asciz ","
str_lit_19:    .asciz "CSV de frutas: "
str_lit_20:    .asciz "null"
str_lit_21:    .asciz "\n"
str_lit_22:    .asciz "/"
str_lit_23:    .asciz "home"
str_lit_24:    .asciz "usuario"
str_lit_25:    .asciz "documentos"
str_lit_26:    .asciz "archivo.txt"
str_lit_27:    .asciz "Ruta completa: "
str_lit_28:    .asciz "null"
str_lit_29:    .asciz "\n"
str_lit_30:    .asciz "Hola"
str_lit_31:    .asciz "mundo"
str_lit_32:    .asciz "desde"
str_lit_33:    .asciz "Java"
str_lit_34:    .asciz " "
str_lit_35:    .asciz "Frase unida: "
str_lit_36:    .asciz "null"
str_lit_37:    .asciz "\n"
str_lit_38:    .asciz "J"
str_lit_39:    .asciz "a"
str_lit_40:    .asciz "v"
str_lit_41:    .asciz "a"
str_lit_42:    .asciz ""
str_lit_43:    .asciz "Palabra formada: "
str_lit_44:    .asciz "null"
str_lit_45:    .asciz "\n"
str_lit_46:    .asciz "-"
str_lit_47:    .asciz "único"
str_lit_48:    .asciz "Elemento único: "
str_lit_49:    .asciz "null"
str_lit_50:    .asciz "\n"
str_lit_51:    .asciz "Ana"
str_lit_52:    .asciz "Luis"
str_lit_53:    .asciz "María"
str_lit_54:    .asciz ", "
str_lit_55:    .asciz "Los participantes son: "
str_lit_56:    .asciz "null"
str_lit_57:    .asciz "\n"
str_lit_58:    .asciz " + "
str_lit_59:    .asciz "Operación: "
str_lit_60:    .asciz "null"
str_lit_61:    .asciz "\n"
str_lit_62:    .asciz ","
str_lit_63:    .asciz "Arreglo vacío: '"
str_lit_64:    .asciz "null"
str_lit_65:    .asciz "'"
str_lit_66:    .asciz "\n"
str_lit_67:    .asciz "a,b"
str_lit_68:    .asciz "c,d"
str_lit_69:    .asciz "e,f"
str_lit_70:    .asciz "|"
str_lit_71:    .asciz "Elementos con comas: "
str_lit_72:    .asciz "null"
str_lit_73:    .asciz "\n"

// --- Variables globales ---
g_fecha:    .quad 0
g_numeros:    .quad 0
g_csv:    .quad 0
g_path:    .quad 0
g_frase:    .quad 0
g_palabra:    .quad 0
g_solo:    .quad 0
g_listaNombres:    .quad 0
g_mensaje:    .quad 0
g_num1:    .quad 0
g_num2:    .quad 0
g_num3:    .quad 0
g_sumaTexto:    .quad 0
g_resultado_vacio:    .quad 0
g_con_comas:    .quad 0
.data
str_dbg_start:    .asciz "[ARM64] START\n"
