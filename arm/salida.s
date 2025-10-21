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
    cmp w12, w11
    b.ne L_pp_traverse_i
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

L_pp_traverse_i:
    mov w20, #0
L_pp_loop_i:
    add w24, w11, #-1
    cmp w20, w24
    b.ge L_pp_final_i
    // header align for current dims w12
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x9, x17
    add x25, x10, x20, uxtw #2
    ldr w22, [x25]
    uxtw x22, w22
    add x14, x21, x22, lsl #3
    ldr x9, [x14]
    ldr w12, [x9]
    add w20, w20, #1
    b L_pp_loop_i
L_pp_final_i:
    // header align for last array
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x9, x17
    add x25, x10, x20, uxtw #2
    ldr w22, [x25]
    uxtw x22, w22
    add x0, x21, x22, lsl #2
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
    cmp w12, w11
    b.ne L_pp_traverse_p
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

L_pp_traverse_p:
    mov w20, #0
L_pp_loop_p:
    add w24, w11, #-1
    cmp w20, w24
    b.ge L_pp_final_p
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x9, x17
    add x25, x10, x20, uxtw #2
    ldr w22, [x25]
    uxtw x22, w22
    add x14, x21, x22, lsl #3
    ldr x9, [x14]
    ldr w12, [x9]
    add w20, w20, #1
    b L_pp_loop_p
L_pp_final_p:
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x9, x17
    add x25, x10, x20, uxtw #2
    ldr w22, [x25]
    uxtw x22, w22
    add x0, x21, x22, lsl #3
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
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #5
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    mov w1, #7
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    mov w1, #8
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    mov w1, #11
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_8:
    cmp w10, w19
    b.ge L_copy_done_decl_8
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_8
L_copy_done_decl_8:
    sub x16, x29, #32
    ldr w1, [x16]
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #48
    str x20, [x16]
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
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_3
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #32
    ldr w1, [x16]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #64
    str w1, [x16]
L_for_cond_9:
    sub x16, x29, #64
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_9
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: StringValueof
    sub sp, sp, #16
    sub x16, x29, #64
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #64
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_end_10
L_then_10:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_end_10:
L_continue_9:
    sub x16, x29, #64
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #64
    str w20, [x16]
    b L_for_cond_9
L_break_9:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #42
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #80
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #80
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_11:
    cmp w10, w19
    b.ge L_copy_done_decl_11
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_11
L_copy_done_decl_11:
    mov w1, #100
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #96
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_7
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #96
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_8
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_9
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #2
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #112
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_12:
    cmp w10, w19
    b.ge L_copy_done_decl_12
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_12
L_copy_done_decl_12:
    mov w1, #3
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #128
    str x20, [x16]
    sub sp, sp, #16
    sub x16, x29, #128
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_13:
    cmp w10, w19
    b.ge L_copy_done_decl_13
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_13
L_copy_done_decl_13:
    mov w1, #4
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #144
    str x20, [x16]
    sub sp, sp, #16
    sub x16, x29, #144
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_14:
    cmp w10, w19
    b.ge L_copy_done_decl_14
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_14
L_copy_done_decl_14:
    mov w1, #5
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #160
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_11
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #176
    str w1, [x16]
L_for_cond_15:
    sub x16, x29, #176
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #160
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_15
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: StringValueof
    sub sp, sp, #16
    sub x16, x29, #176
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #160
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #176
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #160
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_end_16
L_then_16:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_end_16:
L_continue_15:
    sub x16, x29, #176
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #176
    str w20, [x16]
    b L_for_cond_15
L_break_15:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    ldr x16, =dbl_lit_12
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_13
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #192
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #192
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_17:
    cmp w10, w19
    b.ge L_copy_done_decl_17
    add x14, x21, x10, lsl #3
    ldr x0, [x14]
    add x15, x22, x10, lsl #3
    str x0, [x15]
    add w10, w10, #1
    b L_copy_decl_17
L_copy_done_decl_17:
    ldr x16, =dbl_lit_14
    ldr d0, [x16]
    add x15, x22, x19, lsl #3
    str d0, [x15]
    add sp, sp, #16
    sub x16, x29, #208
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_15
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #208
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_16
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #208
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #208
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr d0, [x0]
    add sp, sp, #16
    sub sp, sp, #128
    mov x0, sp
    mov x1, #128
    bl java_format_double
    mov x0, sp
    bl strdup
    add sp, sp, #128
    mov x1, x0
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #65
    strb w1, [x22, x23, lsl #0]
    mov x23, #1
    mov w1, #66
    strb w1, [x22, x23, lsl #0]
    mov x23, #2
    mov w1, #67
    strb w1, [x22, x23, lsl #0]
    add sp, sp, #16
    sub x16, x29, #224
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #224
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_18:
    cmp w10, w19
    b.ge L_copy_done_decl_18
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_18
L_copy_done_decl_18:
    mov w1, #68
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #240
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_17
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #256
    str w1, [x16]
L_for_cond_19:
    sub x16, x29, #256
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #240
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_19
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_18
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #256
    ldr w1, [x16]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_19
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #256
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #240
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldrb w1, [x0]
    add sp, sp, #16
    sub sp, sp, #128
    mov x0, sp
    mov w2, w1
    ldr x1, =fmt_int
    bl sprintf
    mov x1, sp
    ldr x0, =tmpbuf
    bl strcat
    add sp, sp, #128
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_19:
    sub x16, x29, #256
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #256
    str w20, [x16]
    b L_for_cond_19
L_break_19:
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #0
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #272
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #272
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_20:
    cmp w10, w19
    b.ge L_copy_done_decl_20
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_20
L_copy_done_decl_20:
    mov w1, #1
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #288
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_20
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #288
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_21
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #288
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    ldr x1, =str_lit_22
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_23
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #304
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #304
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_21:
    cmp w10, w19
    b.ge L_copy_done_decl_21
    add x14, x21, x10, lsl #3
    ldr x0, [x14]
    add x15, x22, x10, lsl #3
    str x0, [x15]
    add w10, w10, #1
    b L_copy_decl_21
L_copy_done_decl_21:
    ldr x1, =str_lit_24
    mov x0, x1
    bl strdup
    mov x1, x0
    add x15, x22, x19, lsl #3
    str x1, [x15]
    add sp, sp, #16
    sub x16, x29, #320
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_25
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #336
    str w1, [x16]
L_for_cond_22:
    sub x16, x29, #336
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #320
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_22
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #336
    ldr w1, [x16]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_19
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #336
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #320
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr x1, [x0]
    add sp, sp, #16
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_22:
    sub x16, x29, #336
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #336
    str w20, [x16]
    b L_for_cond_22
L_break_22:
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    ldr x16, =dbl_lit_26
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_27
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #352
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #352
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_23:
    cmp w10, w19
    b.ge L_copy_done_decl_23
    add x14, x21, x10, lsl #3
    ldr x0, [x14]
    add x15, x22, x10, lsl #3
    str x0, [x15]
    add w10, w10, #1
    b L_copy_decl_23
L_copy_done_decl_23:
    ldr x16, =dbl_lit_28
    ldr d0, [x16]
    add x15, x22, x19, lsl #3
    str d0, [x15]
    add sp, sp, #16
    sub x16, x29, #368
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_29
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #368
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_30
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #10
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #20
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    mov w1, #30
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #384
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #384
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_24:
    cmp w10, w19
    b.ge L_copy_done_decl_24
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_24
L_copy_done_decl_24:
    mov w1, #40
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #400
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_31
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #384
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_32
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #400
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_33
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #384
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_34
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #400
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    mov w1, #3
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #416
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #416
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_25:
    cmp w10, w19
    b.ge L_copy_done_decl_25
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_25
L_copy_done_decl_25:
    mov w1, #5
    neg w1, w1
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #432
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_35
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_16
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #432
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #432
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #100
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #200
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #448
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #448
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_26:
    cmp w10, w19
    b.ge L_copy_done_decl_26
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_26
L_copy_done_decl_26:
    mov w1, #0
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #464
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_36
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #464
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #1
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #480
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_37
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    mov w1, #2
    sub x16, x29, #496
    str w1, [x16]
L_for_cond_27:
    sub x16, x29, #496
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #5
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, le
    cmp w1, #0
    beq L_break_27
    sub x16, x29, #480
    ldr x9, [x16]
    // header align y longitud actual
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_28:
    cmp w10, w19
    b.ge L_copy_done_28
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_28
L_copy_done_28:
    sub x16, x29, #496
    ldr w1, [x16]
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #480
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_38
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #496
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_39
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #480
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_27:
    sub x16, x29, #496
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #496
    str w20, [x16]
    b L_for_cond_27
L_break_27:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_40
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #512
    str w1, [x16]
L_for_cond_29:
    sub x16, x29, #512
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #480
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_29
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: StringValueof
    sub sp, sp, #16
    sub x16, x29, #512
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #480
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #512
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #480
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_end_30
L_then_30:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_end_30:
L_continue_29:
    sub x16, x29, #512
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #512
    str w20, [x16]
    b L_for_cond_29
L_break_29:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #5
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #10
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #528
    str x0, [x16]
    sub sp, sp, #16
    mov w1, #15
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #5
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub x16, x29, #544
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #528
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_31:
    cmp w10, w19
    b.ge L_copy_done_decl_31
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_31
L_copy_done_decl_31:
    sub x16, x29, #544
    ldr w1, [x16]
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #560
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_41
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_16
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #560
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x22, x0
    ldr w12, [x22]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x22, x17
    mov x23, #0
    mov w1, #7
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #14
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    mov w1, #21
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #576
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #576
    ldr x9, [x16]
    // header align y longitud actual (ArrayAdd decl)
    ldr w12, [x9]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x18, x9, #8
    ldr w19, [x18]
    add x21, x9, x17
    sub sp, sp, #16
    add w1, w19, #1
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    mov x20, x0
    ldr w12, [x20]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x22, x20, x17
    mov w10, #0
L_copy_decl_32:
    cmp w10, w19
    b.ge L_copy_done_decl_32
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_32
L_copy_done_decl_32:
    mov w1, #28
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #592
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_42
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #576
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_43
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #592
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_44
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #592
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_7:
    add sp, sp, #1024
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "Array original: [2,5,7,8]"
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "Agregando: "
str_lit_4:    .asciz "Array resultante: ["
str_lit_5:    .asciz ","
str_lit_6:    .asciz "]"
str_lit_7:    .asciz "Array [42] + 100 = longitud: "
str_lit_8:    .asciz "Elementos: "
str_lit_9:    .asciz ", "
str_lit_10:    .asciz "Agregando secuencialmente 3, 4, 5:"
str_lit_11:    .asciz "Resultado final: ["
dbl_lit_12:    .double 1.5
dbl_lit_13:    .double 2.5
dbl_lit_14:    .double 3.7
str_lit_15:    .asciz "Array float: longitud "
str_lit_16:    .asciz "Último elemento: "
str_lit_17:    .asciz "Array de chars después de add:"
str_lit_18:    .asciz "Posición "
str_lit_19:    .asciz ": "
str_lit_20:    .asciz "Array boolean longitud: "
str_lit_21:    .asciz "Último valor: "
str_lit_22:    .asciz "Hola"
str_lit_23:    .asciz "mundo"
str_lit_24:    .asciz "JavaLang"
str_lit_25:    .asciz "Array de strings:"
dbl_lit_26:    .double 3.14159
dbl_lit_27:    .double 2.71828
dbl_lit_28:    .double 1.41421
str_lit_29:    .asciz "Array double con "
str_lit_30:    .asciz " elementos"
str_lit_31:    .asciz "Array original longitud: "
str_lit_32:    .asciz "Array nuevo longitud: "
str_lit_33:    .asciz "Original[0]: "
str_lit_34:    .asciz ", Nuevo[0]: "
str_lit_35:    .asciz "Agregando número negativo:"
str_lit_36:    .asciz "Agregando cero, último elemento: "
str_lit_37:    .asciz "Agregando elementos en bucle:"
str_lit_38:    .asciz "Paso "
str_lit_39:    .asciz ": longitud "
str_lit_40:    .asciz "Array final: ["
str_lit_41:    .asciz "Agregando resultado de cálculo (15+5):"
str_lit_42:    .asciz "Longitud antes: "
str_lit_43:    .asciz "Longitud después: "
str_lit_44:    .asciz "Nuevo elemento en posición: "

// --- Variables globales ---
g_nuevoVal:    .quad 11
g_i:    .quad 0
g_suma:    .quad 0
.data
