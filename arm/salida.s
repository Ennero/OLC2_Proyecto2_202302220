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

tmpbuf:         .skip 16384
joinbuf:        .skip 16384
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

// join_array_strings(x0=arr_ptr, x1=delim) -> x0=joinbuf
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
    ldr x0, =joinbuf
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
    ldr x0, =joinbuf
    mov w2, #0
    strb w2, [x0]
    mov w20, #0
1:
    cmp w20, w19
    b.ge 2f
    // if i>0 append delim
    cbz w20, 3f
    // Reload x0 with joinbuf before strcat (x0 is caller-saved)
    ldr x0, =joinbuf
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
    ldr x0, =joinbuf
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

// join_array_ints(x0=arr_ptr, x1=delim) -> x0=joinbuf
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
    ldr x0, =joinbuf
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
    ldr x0, =joinbuf
    mov w2, #0
    strb w2, [x0]
    mov w20, #0
1:
    cmp w20, w19
    b.ge 2f
    cbz w20, 3f
    // Reload x0 with joinbuf before strcat (x0 is caller-saved)
    ldr x0, =joinbuf
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
    ldr x0, =joinbuf
    bl strcat
    ldr x0, =joinbuf
    add w20, w20, #1
    b 1b
2:
    ldp x23, x24, [sp, #32]
    ldp x21, x22, [sp, #16]
    ldp x19, x20, [sp, #0]
    add sp, sp, #112
    ldp x29, x30, [sp], 16
    ret

fn_mostrarMatriz:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #32
    str w1, [x16]
L_for_cond_2:
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #16
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_2
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #48
    str w1, [x16]
L_for_cond_3:
    sub x16, x29, #48
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #32
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_4
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_4
L_len_flat_4:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_4:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_3
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: StringValueof
    sub sp, sp, #16
    sub x16, x29, #32
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
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
    sub x16, x29, #48
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #32
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_6
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_6
L_len_flat_6:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_6:
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_end_5
L_then_5:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_end_5:
L_continue_3:
    sub x16, x29, #48
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #48
    str w20, [x16]
    b L_for_cond_3
L_break_3:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_2:
    sub x16, x29, #32
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #32
    str w20, [x16]
    b L_for_cond_2
L_break_2:
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_1:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_sumarMatrices:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub x16, x29, #48
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_8
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_8
L_len_flat_8:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_8:
    add sp, sp, #16
    sub x16, x29, #64
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #48
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #64
    ldr w1, [x16]
    str w1, [sp, #4]
    mov w0, #2
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #80
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #96
    str w1, [x16]
L_for_cond_9:
    sub x16, x29, #96
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
    beq L_break_9
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #112
    str w1, [x16]
L_for_cond_10:
    sub x16, x29, #112
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #64
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_10
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
L_continue_10:
    sub x16, x29, #112
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #112
    str w20, [x16]
    b L_for_cond_10
L_break_10:
L_continue_9:
    sub x16, x29, #96
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #96
    str w20, [x16]
    b L_for_cond_9
L_break_9:
    sub x16, x29, #80
    ldr x1, [x16]
    mov x0, x1
    b L_func_exit_7
L_func_exit_7:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_multiplicarMatrices:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub x16, x29, #48
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_12
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_12
L_len_flat_12:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_12:
    add sp, sp, #16
    sub x16, x29, #64
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_13
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_13
L_len_flat_13:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_13:
    add sp, sp, #16
    sub x16, x29, #80
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #48
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr w1, [x16]
    str w1, [sp, #4]
    mov w0, #2
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #96
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #112
    str w1, [x16]
L_for_cond_14:
    sub x16, x29, #112
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
    beq L_break_14
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #128
    str w1, [x16]
L_for_cond_15:
    sub x16, x29, #128
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #80
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_15
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #0
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #144
    str w1, [x16]
L_for_cond_16:
    sub x16, x29, #144
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #64
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_16
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #144
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #144
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #128
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
L_continue_16:
    sub x16, x29, #144
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #144
    str w20, [x16]
    b L_for_cond_16
L_break_16:
L_continue_15:
    sub x16, x29, #128
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #128
    str w20, [x16]
    b L_for_cond_15
L_break_15:
L_continue_14:
    sub x16, x29, #112
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #112
    str w20, [x16]
    b L_for_cond_14
L_break_14:
    sub x16, x29, #96
    ldr x1, [x16]
    mov x0, x1
    b L_func_exit_11
L_func_exit_11:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_calcularTranspuesta:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_18
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_18
L_len_flat_18:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_18:
    add sp, sp, #16
    sub x16, x29, #48
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #48
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr w1, [x16]
    str w1, [sp, #4]
    mov w0, #2
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #64
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #80
    str w1, [x16]
L_for_cond_19:
    sub x16, x29, #80
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #32
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_19
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #96
    str w1, [x16]
L_for_cond_20:
    sub x16, x29, #96
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
    beq L_break_20
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #64
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    sub sp, sp, #16
    sub x16, x29, #80
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
L_continue_20:
    sub x16, x29, #96
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #96
    str w20, [x16]
    b L_for_cond_20
L_break_20:
L_continue_19:
    sub x16, x29, #80
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #80
    str w20, [x16]
    b L_for_cond_19
L_break_19:
    sub x16, x29, #64
    ldr x1, [x16]
    mov x0, x1
    b L_func_exit_17
L_func_exit_17:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_calcularDeterminante2x2:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    mov w0, w1
    b L_func_exit_21
L_func_exit_21:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_calcularDeterminante3x3:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub x16, x29, #48
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub x16, x29, #64
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    sub x16, x29, #80
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    sub x16, x29, #96
    str w1, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    sub x16, x29, #112
    str w1, [x16]
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #80
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #96
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #64
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #112
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    mov w0, w1
    b L_func_exit_22
L_func_exit_22:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    sub sp, sp, #1024
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
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
    mov w1, #4
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #85
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #92
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #78
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #90
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #90
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #88
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #85
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #93
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #78
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #82
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #90
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #87
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #2
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #95
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #91
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #88
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #94
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #3
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #4
    str w1, [sp, #0]
    movz w1, #6
    str w1, [sp, #4]
    mov w0, #2
    mov x1, sp
    bl new_array_flat_ptr
    sub x16, x29, #32
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #4
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #2
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #48
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #2
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #64
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
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
    sub x16, x29, #16
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
    ldr x1, =str_lit_9
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_24
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_24
L_len_flat_24:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_24:
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_10
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #32
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
    ldr x1, =str_lit_9
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_25
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_25
L_len_flat_25:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_25:
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_11
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #48
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
    ldr x1, =str_lit_9
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_26
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_26
L_len_flat_26:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_26:
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_12
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #64
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
    ldr x1, =str_lit_9
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #64
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_27
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_27
L_len_flat_27:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_27:
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_13
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    movz w1, #4
    str w1, [sp, #0]
    movz w1, #4
    str w1, [sp, #4]
    movz w1, #3
    str w1, [sp, #8]
    mov w0, #3
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #80
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
    sub sp, sp, #16
    mov w1, #3
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
    ldr x16, =dbl_lit_14
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_15
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_16
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
    sub sp, sp, #16
    mov w1, #3
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
    ldr x16, =dbl_lit_17
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_18
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_19
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
    sub sp, sp, #16
    mov w1, #3
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
    ldr x16, =dbl_lit_20
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_21
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_22
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #2
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
    sub sp, sp, #16
    mov w1, #3
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
    ldr x16, =dbl_lit_23
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_24
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_25
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
    sub sp, sp, #16
    mov w1, #3
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
    mov x23, #2
    ldr x16, =dbl_lit_28
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
    sub sp, sp, #16
    mov w1, #3
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
    ldr x16, =dbl_lit_29
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_30
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_31
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #2
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #96
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_32
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
    sub x16, x29, #80
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
    ldr x1, =str_lit_9
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_28
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_28
L_len_flat_28:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_28:
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
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #80
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_29
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x1, sp, #4
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_29
L_len_flat_29:
    add x18, x0, #16
    ldr w1, [x18]
L_len_done_29:
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_34
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
    ldr x1, =str_lit_9
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_30
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_30
L_len_flat_30:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_30:
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
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #96
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_31
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x1, sp, #4
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_31
L_len_flat_31:
    add x18, x0, #16
    ldr w1, [x18]
L_len_done_31:
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
    ldr x1, =str_lit_36
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
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
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #95
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #82
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #3
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #90
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_37
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_38
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_39
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_40
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_41
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_42
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_43
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_44
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_45
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_46
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    movz w1, #0
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #88
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    movz w1, #1
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #92
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    movz w1, #2
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #85
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    movz w1, #0
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #85
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    movz w1, #1
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #90
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    movz w1, #2
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #88
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    movz w1, #0
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #92
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    movz w1, #1
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #87
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #2
    str w1, [sp, #0]
    movz w1, #2
    str w1, [sp, #4]
    movz w1, #2
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #94
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #3
    str w1, [sp, #0]
    movz w1, #3
    str w1, [sp, #4]
    movz w1, #0
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #96
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #3
    str w1, [sp, #0]
    movz w1, #3
    str w1, [sp, #4]
    movz w1, #1
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #93
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #3
    str w1, [sp, #0]
    movz w1, #3
    str w1, [sp, #4]
    movz w1, #2
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    movz w1, #97
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_47
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
    ldr x1, =str_lit_48
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    movz w1, #0
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
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
    ldr x1, =str_lit_3
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    movz w1, #1
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
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
    ldr x1, =str_lit_3
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    movz w1, #2
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
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
    ldr x1, =str_lit_4
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
    ldr x1, =str_lit_49
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #3
    str w1, [sp, #0]
    movz w1, #3
    str w1, [sp, #4]
    movz w1, #0
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
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
    ldr x1, =str_lit_3
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #3
    str w1, [sp, #0]
    movz w1, #3
    str w1, [sp, #4]
    movz w1, #1
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
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
    ldr x1, =str_lit_3
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #3
    str w1, [sp, #0]
    movz w1, #3
    str w1, [sp, #4]
    movz w1, #2
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
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
    ldr x1, =str_lit_4
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
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #1
    str w1, [sp, #4]
    movz w1, #2
    str w1, [sp, #8]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_50
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    movz w1, #1
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    movz w1, #1
    str w1, [sp, #8]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_51
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_52
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_53
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
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
    ldr x1, =str_lit_54
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_55
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_56
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_57
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #112
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
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
    ldr x1, =str_lit_58
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_59
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_60
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_61
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #128
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_62
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #144
    str w1, [x16]
L_for_cond_32:
    sub x16, x29, #144
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #16
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_32
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_63
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #144
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #128
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
    ldr x1, =str_lit_64
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
    movz w1, #0
    sub x16, x29, #160
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #176
    str w1, [x16]
L_for_cond_33:
    sub x16, x29, #176
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #144
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_34
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_34
L_len_flat_34:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_34:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_33
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #144
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #176
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub x16, x29, #192
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_65
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #176
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #112
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
    ldr x1, =str_lit_66
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #192
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
    sub x16, x29, #160
    ldr w19, [x16]
    sub x16, x29, #192
    ldr w1, [x16]
    add w1, w19, w1
    sub x16, x29, #160
    str w1, [x16]
L_continue_33:
    sub x16, x29, #176
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #176
    str w20, [x16]
    b L_for_cond_33
L_break_33:
    sub sp, sp, #16
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #144
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_35
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_35
L_len_flat_35:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_35:
    add sp, sp, #16
    scvtf d0, w1
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fdiv d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #208
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_67
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #208
    ldr d0, [x16]
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
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_32:
    sub x16, x29, #144
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #144
    str w20, [x16]
    b L_for_cond_32
L_break_32:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_68
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
    ldr x1, =str_lit_69
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    movz w1, #0
    str w1, [sp, #0]
    movz w1, #0
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_70
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #128
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #112
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_71
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #128
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #112
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w1, w19, w1
    str w1, [sp, #4]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #2
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_72
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_73
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
    ldr x1, =str_lit_74
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_75
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_76
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #224
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #240
    str w1, [x16]
L_for_cond_36:
    sub x16, x29, #240
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_36
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_63
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #240
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #128
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
    ldr x1, =str_lit_64
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
    movz w1, #0
    sub x16, x29, #256
    str w1, [x16]
L_for_cond_37:
    sub x16, x29, #256
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_37
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_65
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #256
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #112
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
    ldr x1, =str_lit_64
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
    movz w1, #0
    sub x16, x29, #272
    str w1, [x16]
L_for_cond_38:
    sub x16, x29, #272
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #240
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #256
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #80
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_39
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x1, sp, #4
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_39
L_len_flat_39:
    add x18, x0, #16
    ldr w1, [x18]
L_len_done_39:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_38
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #240
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #256
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #272
    ldr w1, [x16]
    str w1, [sp, #8]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub x16, x29, #288
    str w1, [x16]
    sub x16, x29, #288
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #0
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, gt
    cmp w1, #0
    beq L_end_40
L_then_40:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_77
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #272
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #224
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
    ldr x1, =str_lit_66
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #288
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
L_end_40:
L_continue_38:
    sub x16, x29, #272
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #272
    str w20, [x16]
    b L_for_cond_38
L_break_38:
L_continue_37:
    sub x16, x29, #256
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #256
    str w20, [x16]
    b L_for_cond_37
L_break_37:
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_36:
    sub x16, x29, #240
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #240
    str w20, [x16]
    b L_for_cond_36
L_break_36:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_78
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
    ldr x1, =str_lit_79
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_80
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #304
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
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
    ldr x1, =str_lit_81
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_82
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_83
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #320
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
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
    ldr x1, =str_lit_84
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_85
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_86
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #336
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #352
    str w1, [x16]
L_for_cond_41:
    sub x16, x29, #352
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #96
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_41
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub sp, sp, #16
    sub x16, x29, #352
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #304
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
    ldr x1, =str_lit_64
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
    movz w1, #0
    sub x16, x29, #368
    str w1, [x16]
L_for_cond_42:
    sub x16, x29, #368
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #352
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_43
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_43
L_len_flat_43:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_43:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_42
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_65
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #368
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
    ldr x1, =str_lit_64
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
    movz w1, #0
    sub x16, x29, #384
    str w1, [x16]
L_for_cond_44:
    sub x16, x29, #384
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #352
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #368
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #96
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_45
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x1, sp, #4
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_45
L_len_flat_45:
    add x18, x0, #16
    ldr w1, [x18]
L_len_done_45:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_44
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #352
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #368
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #384
    ldr w1, [x16]
    str w1, [sp, #8]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr_ptr
    ldr d0, [x0]
    add sp, sp, #16
    sub x16, x29, #400
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_77
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #384
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #336
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
    ldr x1, =str_lit_66
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #400
    ldr d0, [x16]
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
    ldr x1, =str_lit_87
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
L_continue_44:
    sub x16, x29, #384
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #384
    str w20, [x16]
    b L_for_cond_44
L_break_44:
L_continue_42:
    sub x16, x29, #368
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #368
    str w20, [x16]
    b L_for_cond_42
L_break_42:
L_continue_41:
    sub x16, x29, #352
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #352
    str w20, [x16]
    b L_for_cond_41
L_break_41:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_88
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_89
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #48
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_90
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #64
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #48
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #64
    ldr x1, [x16]
    mov x1, x1
    sub sp, sp, #16
    str x1, [sp]
    ldr x1, [sp]
    add sp, sp, #16
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_sumarMatrices
    mov x1, x0
    sub x16, x29, #416
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_91
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #416
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #48
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #64
    ldr x1, [x16]
    mov x1, x1
    sub sp, sp, #16
    str x1, [sp]
    ldr x1, [sp]
    add sp, sp, #16
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_multiplicarMatrices
    mov x1, x0
    sub x16, x29, #432
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_92
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #432
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_93
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_94
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_95
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_96
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
    bl new_array_flat_ptr
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #4
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #5
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #6
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #7
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #8
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #9
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #10
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #11
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #12
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #2
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #448
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_97
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #448
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #448
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularTranspuesta
    mov x1, x0
    sub x16, x29, #464
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_98
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #464
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_99
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub x16, x29, #48
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularTranspuesta
    mov x1, x0
    sub x16, x29, #480
    str x0, [x16]
    sub x16, x29, #480
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #480
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularTranspuesta
    mov x1, x0
    sub x16, x29, #496
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_100
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #496
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_101
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
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #4
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #512
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_102
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #512
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #512
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularDeterminante2x2
    mov w1, w0
    sub x16, x29, #528
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_103
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #528
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
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #5
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #4
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #544
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_104
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #544
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #544
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularDeterminante2x2
    mov w1, w0
    sub x16, x29, #560
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_103
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #560
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
    ldr x1, =str_lit_105
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #48
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #48
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularDeterminante3x3
    mov w1, w0
    sub x16, x29, #576
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_106
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #576
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
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    mov x20, x0
    mov x21, x0
    ldr w12, [x21]
    mov x15, #8
    uxtw x16, w12
    lsl x16, x16, #2
    add x15, x15, x16
    add x17, x15, #7
    and x17, x17, #-8
    add x21, x21, x17
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #1
    neg w1, w1
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #0
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #0
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    sub sp, sp, #32
    stp x20, x21, [sp]
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
    movz w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #1
    neg w1, w1
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #2
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #592
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_107
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #592
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #592
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularDeterminante3x3
    mov w1, w0
    sub x16, x29, #608
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_108
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #608
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
    ldr x1, =str_lit_109
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_23:
    add sp, sp, #1024
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "  ["
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz ", "
str_lit_4:    .asciz "]"
str_lit_5:    .asciz "=== SISTEMA DE ANALISIS DE DATOS ACADEMICOS ==="
str_lit_6:    .asciz "\n--- DECLARACION DE MATRICES 2D ---"
str_lit_7:    .asciz "Matrices 2D declaradas exitosamente:"
str_lit_8:    .asciz "- calificacionesPorMateria: "
str_lit_9:    .asciz " x "
str_lit_10:    .asciz "- promediosPorSemestre: "
str_lit_11:    .asciz "- matrizA: "
str_lit_12:    .asciz "- matrizB: "
str_lit_13:    .asciz "\n--- DECLARACION DE MATRICES 3D ---"
dbl_lit_14:    .double 20.5
dbl_lit_15:    .double 22.1
dbl_lit_16:    .double 25.3
dbl_lit_17:    .double 19.8
dbl_lit_18:    .double 21.5
dbl_lit_19:    .double 24.7
dbl_lit_20:    .double 21.2
dbl_lit_21:    .double 23.0
dbl_lit_22:    .double 26.1
dbl_lit_23:    .double 18.5
dbl_lit_24:    .double 20.1
dbl_lit_25:    .double 23.3
dbl_lit_26:    .double 17.8
dbl_lit_27:    .double 19.5
dbl_lit_28:    .double 22.7
dbl_lit_29:    .double 19.2
dbl_lit_30:    .double 21.0
dbl_lit_31:    .double 24.1
str_lit_32:    .asciz "Matrices 3D declaradas exitosamente:"
str_lit_33:    .asciz "- evaluacionesDetalladas: "
str_lit_34:    .asciz "- temperaturasPorDia: "
str_lit_35:    .asciz "\n--- MODIFICACION DE ELEMENTOS 2D ---"
str_lit_36:    .asciz "Calificación original del Estudiante 1 en Física: "
str_lit_37:    .asciz "Nueva calificación del Estudiante 1 en Física: "
str_lit_38:    .asciz "Modificaciones adicionales realizadas en otras posiciones"
dbl_lit_39:    .double 85.5
dbl_lit_40:    .double 87.2
dbl_lit_41:    .double 89.1
dbl_lit_42:    .double 90.3
dbl_lit_43:    .double 88.7
dbl_lit_44:    .double 91.2
str_lit_45:    .asciz "Matriz de promedios por semestre inicializada"
str_lit_46:    .asciz "\n--- MODIFICACION DE ELEMENTOS 3D ---"
str_lit_47:    .asciz "Cubo de evaluaciones detalladas inicializado:"
str_lit_48:    .asciz "- Estudiante 1, Matemáticas: ["
str_lit_49:    .asciz "- Estudiante 4, Biología: ["
dbl_lit_50:    .double 25.5
dbl_lit_51:    .double 21.8
str_lit_52:    .asciz "Temperaturas específicas modificadas"
str_lit_53:    .asciz "\n--- ACCESO A ELEMENTOS 2D ---"
str_lit_54:    .asciz "Matemáticas"
str_lit_55:    .asciz "Física"
str_lit_56:    .asciz "Química"
str_lit_57:    .asciz "Biología"
str_lit_58:    .asciz "Ana"
str_lit_59:    .asciz "Luis"
str_lit_60:    .asciz "María"
str_lit_61:    .asciz "Carlos"
str_lit_62:    .asciz "Análisis de calificaciones por estudiante:"
str_lit_63:    .asciz "Estudiante "
str_lit_64:    .asciz ":"
str_lit_65:    .asciz "  "
str_lit_66:    .asciz ": "
str_lit_67:    .asciz "  Promedio: "
str_lit_68:    .asciz "Acceso directo a elementos específicos:"
str_lit_69:    .asciz "Primera calificación (Ana, Matemáticas): "
str_lit_70:    .asciz "Última calificación (Carlos, Biología): "
str_lit_71:    .asciz "Elemento central: "
str_lit_72:    .asciz "\n--- ACCESO A ELEMENTOS 3D ---"
str_lit_73:    .asciz "Análisis de evaluaciones detalladas:"
str_lit_74:    .asciz "Examen 1"
str_lit_75:    .asciz "Examen 2"
str_lit_76:    .asciz "Proyecto"
str_lit_77:    .asciz "    "
str_lit_78:    .asciz "Temperaturas registradas:"
str_lit_79:    .asciz "Semana 1"
str_lit_80:    .asciz "Semana 2"
str_lit_81:    .asciz "Lunes"
str_lit_82:    .asciz "Martes"
str_lit_83:    .asciz "Miércoles"
str_lit_84:    .asciz "Mañana"
str_lit_85:    .asciz "Tarde"
str_lit_86:    .asciz "Noche"
str_lit_87:    .asciz "°C"
str_lit_88:    .asciz "\n--- OPERACIONES CON MATRICES ---"
str_lit_89:    .asciz "Matriz A:"
str_lit_90:    .asciz "Matriz B:"
str_lit_91:    .asciz "Suma A + B:"
str_lit_92:    .asciz "Producto A * B:"
str_lit_93:    .asciz "Verificando operaciones:"
str_lit_94:    .asciz "- Suma completada correctamente"
str_lit_95:    .asciz "- Multiplicación completada correctamente"
str_lit_96:    .asciz "\n--- TRANSPUESTA DE MATRIZ ---"
str_lit_97:    .asciz "Matriz original (3x4):"
str_lit_98:    .asciz "Matriz transpuesta (4x3):"
str_lit_99:    .asciz "Transpuesta de matriz A:"
str_lit_100:    .asciz "Doble transpuesta de A (debe ser igual a A original):"
str_lit_101:    .asciz "\n--- CALCULO DE DETERMINANTES ---"
str_lit_102:    .asciz "Matriz 2x2:"
str_lit_103:    .asciz "Determinante 2x2: "
str_lit_104:    .asciz "\nSegunda matriz 2x2:"
str_lit_105:    .asciz "\nMatriz A (3x3):"
str_lit_106:    .asciz "Determinante 3x3 de matriz A: "
str_lit_107:    .asciz "\nMatriz especial 3x3:"
str_lit_108:    .asciz "Determinante 3x3: "
str_lit_109:    .asciz "\n=== ANALISIS DE DATOS ACADEMICOS COMPLETADO ==="

// --- Variables globales ---
g_i:    .quad 0
g_j:    .quad 0
g_filas:    .quad 0
g_columnas:    .quad 0
g_filasA:    .quad 0
g_columnasA:    .quad 0
g_columnasB:    .quad 0
g_k:    .quad 0
g_a:    .quad 0
g_b:    .quad 0
g_c:    .quad 0
g_menor1:    .quad 0
g_menor2:    .quad 0
g_menor3:    .quad 0
g_suma:    .quad 0
g_nota:    .quad 0
g_promedio:    .quad 0
g_estudiante:    .quad 0
g_materia:    .quad 0
g_evaluacion:    .quad 0
g_semana:    .quad 0
g_dia:    .quad 0
g_periodo:    .quad 0
g_temp:    .quad 0
g_determinante2x2:    .quad 0
g_det2x2_2:    .quad 0
g_determinante3x3:    .quad 0
g_det3x3_especial:    .quad 0
.data
