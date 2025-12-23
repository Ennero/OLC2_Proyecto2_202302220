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
L_for_cond_129:
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
    beq L_break_129
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
L_for_cond_130:
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
    b.ne L_len_flat_131
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_131
L_len_flat_131:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_131:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_130
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
    b.ne L_len_flat_133
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_133
L_len_flat_133:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_133:
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
    beq L_end_132
L_then_132:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_end_132:
L_continue_130:
    sub x16, x29, #48
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #48
    str w20, [x16]
    b L_for_cond_130
L_break_130:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_129:
    sub x16, x29, #32
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #32
    str w20, [x16]
    b L_for_cond_129
L_break_129:
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_128:
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
    b.ne L_len_flat_135
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_135
L_len_flat_135:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_135:
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
L_for_cond_136:
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
    beq L_break_136
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #112
    str w1, [x16]
L_for_cond_137:
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
    beq L_break_137
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
L_continue_137:
    sub x16, x29, #112
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #112
    str w20, [x16]
    b L_for_cond_137
L_break_137:
L_continue_136:
    sub x16, x29, #96
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #96
    str w20, [x16]
    b L_for_cond_136
L_break_136:
    sub x16, x29, #80
    ldr x1, [x16]
    mov x0, x1
    b L_func_exit_134
L_func_exit_134:
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
    b.ne L_len_flat_139
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_139
L_len_flat_139:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_139:
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
    b.ne L_len_flat_140
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_140
L_len_flat_140:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_140:
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
L_for_cond_141:
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
    beq L_break_141
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #128
    str w1, [x16]
L_for_cond_142:
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
    beq L_break_142
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
L_for_cond_143:
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
    beq L_break_143
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
L_continue_143:
    sub x16, x29, #144
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #144
    str w20, [x16]
    b L_for_cond_143
L_break_143:
L_continue_142:
    sub x16, x29, #128
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #128
    str w20, [x16]
    b L_for_cond_142
L_break_142:
L_continue_141:
    sub x16, x29, #112
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #112
    str w20, [x16]
    b L_for_cond_141
L_break_141:
    sub x16, x29, #96
    ldr x1, [x16]
    mov x0, x1
    b L_func_exit_138
L_func_exit_138:
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
    b.ne L_len_flat_145
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_145
L_len_flat_145:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_145:
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
L_for_cond_146:
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
    beq L_break_146
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #96
    str w1, [x16]
L_for_cond_147:
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
    beq L_break_147
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
L_continue_147:
    sub x16, x29, #96
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #96
    str w20, [x16]
    b L_for_cond_147
L_break_147:
L_continue_146:
    sub x16, x29, #80
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #80
    str w20, [x16]
    b L_for_cond_146
L_break_146:
    sub x16, x29, #64
    ldr x1, [x16]
    mov x0, x1
    b L_func_exit_144
L_func_exit_144:
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
    b L_func_exit_148
L_func_exit_148:
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
    b L_func_exit_149
L_func_exit_149:
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
    b.ne L_len_flat_151
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_151
L_len_flat_151:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_151:
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
    b.ne L_len_flat_152
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_152
L_len_flat_152:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_152:
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
    b.ne L_len_flat_153
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_153
L_len_flat_153:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_153:
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
    b.ne L_len_flat_154
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_154
L_len_flat_154:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_154:
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_14
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
    ldr x1, =str_lit_15
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
    ldr x1, =str_lit_16
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
    ldr x16, =dbl_lit_17
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
    ldr x16, =dbl_lit_18
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
    ldr x16, =dbl_lit_19
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
    ldr x16, =dbl_lit_20
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
    ldr x16, =dbl_lit_21
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
    ldr x16, =dbl_lit_22
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_23
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_24
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
    ldr x1, =str_lit_25
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_26
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_27
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_28
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #80
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
    ldr x1, =str_lit_29
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_30
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_31
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_32
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #96
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_33
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #112
    str w1, [x16]
L_for_cond_155:
    sub x16, x29, #112
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
    beq L_break_155
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
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #96
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
    ldr x1, =str_lit_35
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
    sub x16, x29, #128
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #144
    str w1, [x16]
L_for_cond_156:
    sub x16, x29, #144
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_157
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_157
L_len_flat_157:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_157:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_156
    sub sp, sp, #16
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
    sub x16, x29, #160
    str w1, [x16]
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
    sub x16, x29, #144
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #80
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
    ldr x1, =str_lit_37
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #160
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
    sub x16, x29, #128
    ldr w19, [x16]
    sub x16, x29, #160
    ldr w1, [x16]
    add w1, w19, w1
    sub x16, x29, #128
    str w1, [x16]
L_continue_156:
    sub x16, x29, #144
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #144
    str w20, [x16]
    b L_for_cond_156
L_break_156:
    sub sp, sp, #16
    sub x16, x29, #128
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_158
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_158
L_len_flat_158:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_158:
    add sp, sp, #16
    scvtf d0, w1
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fdiv d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #176
    str d0, [x16]
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
    sub x16, x29, #176
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
L_continue_155:
    sub x16, x29, #112
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #112
    str w20, [x16]
    b L_for_cond_155
L_break_155:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_39
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
    ldr x1, =str_lit_40
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
    ldr x1, =str_lit_41
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #96
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
    sub x16, x29, #80
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
    ldr x1, =str_lit_42
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #96
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
    sub x16, x29, #80
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
    ldr x1, =str_lit_43
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_44
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
    ldr x1, =str_lit_45
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
    sub x16, x29, #192
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_46
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #192
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
    sub x16, x29, #208
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_47
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #208
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
    ldr x1, =str_lit_48
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_49
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_50
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_51
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
    sub x16, x29, #224
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_52
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #224
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #224
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularTranspuesta
    mov x1, x0
    sub x16, x29, #240
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_53
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #240
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
    ldr x1, =str_lit_54
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
    bl fn_calcularTranspuesta
    mov x1, x0
    sub x16, x29, #256
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #256
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularTranspuesta
    mov x1, x0
    sub x16, x29, #272
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_55
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #272
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
    ldr x1, =str_lit_56
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
    sub x16, x29, #288
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_57
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #288
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_mostrarMatriz
    mov w1, w0
    sub sp, sp, #16
    sub x16, x29, #288
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_calcularDeterminante2x2
    mov w1, w0
    sub x16, x29, #304
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_58
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #304
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
    ldr x1, =str_lit_59
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
    sub x16, x29, #320
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_60
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #320
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
    ldr x1, =str_lit_61
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
    sub x16, x29, #336
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
    ldr x16, =dbl_lit_62
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_63
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_64
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
    ldr x16, =dbl_lit_65
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_66
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_67
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
    ldr x16, =dbl_lit_68
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_69
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_70
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
    ldr x16, =dbl_lit_71
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_72
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_73
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
    ldr x16, =dbl_lit_74
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_75
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_76
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
    ldr x16, =dbl_lit_77
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_78
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_79
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
    sub x16, x29, #352
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_80
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
    ldr x1, =str_lit_81
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #336
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
    sub x16, x29, #336
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_159
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_159
L_len_flat_159:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_159:
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
    sub x16, x29, #336
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_160
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
    b L_len_done_160
L_len_flat_160:
    add x18, x0, #16
    ldr w1, [x18]
L_len_done_160:
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
    ldr x1, =str_lit_82
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #352
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
    sub x16, x29, #352
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_161
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_161
L_len_flat_161:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_161:
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
    sub x16, x29, #352
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_162
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
    b L_len_done_162
L_len_flat_162:
    add x18, x0, #16
    ldr w1, [x18]
L_len_done_162:
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
    ldr x1, =str_lit_83
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    ldr x1, =str_lit_84
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
    ldr x1, =str_lit_85
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    ldr x1, =str_lit_86
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #336
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
    sub x16, x29, #352
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_87
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
    sub x16, x29, #352
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    ldr x16, =dbl_lit_88
    ldr d0, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str d0, [x9]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_89
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_90
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_91
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
    ldr x1, =str_lit_92
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_93
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_94
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #368
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #384
    str w1, [x16]
L_for_cond_163:
    sub x16, x29, #384
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_163
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
    sub sp, sp, #16
    sub x16, x29, #384
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #96
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
    ldr x1, =str_lit_35
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
    sub x16, x29, #400
    str w1, [x16]
L_for_cond_164:
    sub x16, x29, #400
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_164
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
    sub x16, x29, #400
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #80
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
    ldr x1, =str_lit_35
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
    sub x16, x29, #416
    str w1, [x16]
L_for_cond_165:
    sub x16, x29, #416
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #384
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #400
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #336
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_166
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
    b L_len_done_166
L_len_flat_166:
    add x18, x0, #16
    ldr w1, [x18]
L_len_done_166:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_165
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #384
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #400
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #416
    ldr w1, [x16]
    str w1, [sp, #8]
    sub x16, x29, #336
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub x16, x29, #432
    str w1, [x16]
    sub x16, x29, #432
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #0
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, gt
    cmp w1, #0
    beq L_end_167
L_then_167:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_95
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #416
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #368
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
    ldr x1, =str_lit_37
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #432
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
L_end_167:
L_continue_165:
    sub x16, x29, #416
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #416
    str w20, [x16]
    b L_for_cond_165
L_break_165:
L_continue_164:
    sub x16, x29, #400
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #400
    str w20, [x16]
    b L_for_cond_164
L_break_164:
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_163:
    sub x16, x29, #384
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #384
    str w20, [x16]
    b L_for_cond_163
L_break_163:
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
    ldr x1, =str_lit_97
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_98
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #448
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
    ldr x1, =str_lit_99
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_100
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_101
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #464
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
    ldr x1, =str_lit_102
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_103
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_104
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #480
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #496
    str w1, [x16]
L_for_cond_168:
    sub x16, x29, #496
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #352
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_168
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub sp, sp, #16
    sub x16, x29, #496
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #448
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
    ldr x1, =str_lit_35
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
    sub x16, x29, #512
    str w1, [x16]
L_for_cond_169:
    sub x16, x29, #512
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #496
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #352
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_170
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_170
L_len_flat_170:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_170:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_169
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
    sub x16, x29, #512
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #464
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
    ldr x1, =str_lit_35
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
    sub x16, x29, #528
    str w1, [x16]
L_for_cond_171:
    sub x16, x29, #528
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #496
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #512
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #352
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_172
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
    b L_len_done_172
L_len_flat_172:
    add x18, x0, #16
    ldr w1, [x18]
L_len_done_172:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_171
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #496
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #512
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #528
    ldr w1, [x16]
    str w1, [sp, #8]
    sub x16, x29, #352
    ldr x0, [x16]
    mov x1, sp
    mov w2, #3
    bl array_element_addr_ptr
    ldr d0, [x0]
    add sp, sp, #16
    sub x16, x29, #544
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_95
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #528
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #480
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
    ldr x1, =str_lit_37
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #544
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
    ldr x1, =str_lit_105
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
L_continue_171:
    sub x16, x29, #528
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #528
    str w20, [x16]
    b L_for_cond_171
L_break_171:
L_continue_169:
    sub x16, x29, #512
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #512
    str w20, [x16]
    b L_for_cond_169
L_break_169:
L_continue_168:
    sub x16, x29, #496
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #496
    str w20, [x16]
    b L_for_cond_168
L_break_168:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_106
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
    movz w1, #1
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
    movz w1, #6
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
    movz w1, #7
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #8
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
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
    movz w1, #9
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #10
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
    movz w1, #11
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #12
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
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
    movz w1, #13
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #14
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
    movz w1, #15
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #16
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #1
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #560
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #576
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #592
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #608
    str w1, [x16]
L_for_cond_173:
    sub x16, x29, #608
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #560
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_173
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #624
    str w1, [x16]
L_for_cond_174:
    sub x16, x29, #624
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #608
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #560
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_175
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_175
L_len_flat_175:
    add x18, x0, #12
    ldr w1, [x18]
L_len_done_175:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_174
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #640
    str w1, [x16]
L_for_cond_176:
    sub x16, x29, #640
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #608
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #624
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #560
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_177
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
    b L_len_done_177
L_len_flat_177:
    add x18, x0, #16
    ldr w1, [x18]
L_len_done_177:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_176
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #656
    str w1, [x16]
L_for_cond_178:
    sub x16, x29, #656
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #608
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #624
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #640
    ldr w1, [x16]
    str w1, [sp, #8]
    sub x16, x29, #560
    ldr x0, [x16]
    ldr w12, [x0]
    cmp w12, #1
    b.ne L_len_flat_179
    add x1, sp, #0
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x1, sp, #4
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x1, sp, #8
    mov w2, #1
    bl array_element_addr_ptr
    ldr x0, [x0]
    add x18, x0, #8
    ldr w1, [x18]
    b L_len_done_179
L_len_flat_179:
    add x18, x0, #20
    ldr w1, [x18]
L_len_done_179:
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_178
    sub x16, x29, #576
    ldr w19, [x16]
    sub sp, sp, #16
    sub x16, x29, #608
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #624
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #640
    ldr w1, [x16]
    str w1, [sp, #8]
    sub x16, x29, #656
    ldr w1, [x16]
    str w1, [sp, #12]
    sub x16, x29, #560
    ldr x0, [x16]
    mov x1, sp
    mov w2, #4
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    add w1, w19, w1
    sub x16, x29, #576
    str w1, [x16]
    sub x16, x29, #592
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #592
    str w20, [x16]
L_continue_178:
    sub x16, x29, #656
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #656
    str w20, [x16]
    b L_for_cond_178
L_break_178:
L_continue_176:
    sub x16, x29, #640
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #640
    str w20, [x16]
    b L_for_cond_176
L_break_176:
L_continue_174:
    sub x16, x29, #624
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #624
    str w20, [x16]
    b L_for_cond_174
L_break_174:
L_continue_173:
    sub x16, x29, #608
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #608
    str w20, [x16]
    b L_for_cond_173
L_break_173:
    sub sp, sp, #16
    sub x16, x29, #576
    ldr w1, [x16]
    scvtf d0, w1
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #592
    ldr w1, [x16]
    ldr d8, [sp]
    scvtf d9, w1
    fdiv d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #672
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_107
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #576
    ldr w1, [x16]
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
    sub x16, x29, #592
    ldr w1, [x16]
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_109
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #672
    ldr d0, [x16]
    sub sp, sp, #128
    mov x0, sp
    mov x1, #128
    bl java_format_double
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_110
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_150:
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
str_lit_13:    .asciz "\n--- MODIFICACION DE ELEMENTOS 2D ---"
str_lit_14:    .asciz "Calificación original del Estudiante 1 en Física: "
str_lit_15:    .asciz "Nueva calificación del Estudiante 1 en Física: "
str_lit_16:    .asciz "Modificaciones adicionales realizadas en otras posiciones"
dbl_lit_17:    .double 85.5
dbl_lit_18:    .double 87.2
dbl_lit_19:    .double 89.1
dbl_lit_20:    .double 90.3
dbl_lit_21:    .double 88.7
dbl_lit_22:    .double 91.2
str_lit_23:    .asciz "Matriz de promedios por semestre inicializada"
str_lit_24:    .asciz "\n--- ACCESO A ELEMENTOS 2D ---"
str_lit_25:    .asciz "Matemáticas"
str_lit_26:    .asciz "Física"
str_lit_27:    .asciz "Química"
str_lit_28:    .asciz "Biología"
str_lit_29:    .asciz "Ana"
str_lit_30:    .asciz "Luis"
str_lit_31:    .asciz "María"
str_lit_32:    .asciz "Carlos"
str_lit_33:    .asciz "Análisis de calificaciones por estudiante:"
str_lit_34:    .asciz "Estudiante "
str_lit_35:    .asciz ":"
str_lit_36:    .asciz "  "
str_lit_37:    .asciz ": "
str_lit_38:    .asciz "  Promedio: "
str_lit_39:    .asciz "Acceso directo a elementos específicos:"
str_lit_40:    .asciz "Primera calificación (Ana, Matemáticas): "
str_lit_41:    .asciz "Última calificación (Carlos, Biología): "
str_lit_42:    .asciz "Elemento central: "
str_lit_43:    .asciz "\n--- OPERACIONES CON MATRICES ---"
str_lit_44:    .asciz "Matriz A:"
str_lit_45:    .asciz "Matriz B:"
str_lit_46:    .asciz "Suma A + B:"
str_lit_47:    .asciz "Producto A * B:"
str_lit_48:    .asciz "Verificando operaciones:"
str_lit_49:    .asciz "- Suma completada correctamente"
str_lit_50:    .asciz "- Multiplicación completada correctamente"
str_lit_51:    .asciz "\n--- TRANSPUESTA DE MATRIZ ---"
str_lit_52:    .asciz "Matriz original (3x4):"
str_lit_53:    .asciz "Matriz transpuesta (4x3):"
str_lit_54:    .asciz "Matriz original A:"
str_lit_55:    .asciz "Doble transpuesta de A (debe ser igual a A original):"
str_lit_56:    .asciz "\n--- CALCULO DE DETERMINANTES ---"
str_lit_57:    .asciz "Matriz 2x2:"
str_lit_58:    .asciz "Determinante 2x2: "
str_lit_59:    .asciz "\nMatriz A (3x3):"
str_lit_60:    .asciz "Determinante 3x3 de matriz A: "
str_lit_61:    .asciz "\n--- DECLARACION DE MATRICES 3D ---"
dbl_lit_62:    .double 20.5
dbl_lit_63:    .double 22.1
dbl_lit_64:    .double 25.3
dbl_lit_65:    .double 19.8
dbl_lit_66:    .double 21.5
dbl_lit_67:    .double 24.7
dbl_lit_68:    .double 21.2
dbl_lit_69:    .double 23.0
dbl_lit_70:    .double 26.1
dbl_lit_71:    .double 18.5
dbl_lit_72:    .double 20.1
dbl_lit_73:    .double 23.3
dbl_lit_74:    .double 17.8
dbl_lit_75:    .double 19.5
dbl_lit_76:    .double 22.7
dbl_lit_77:    .double 19.2
dbl_lit_78:    .double 21.0
dbl_lit_79:    .double 24.1
str_lit_80:    .asciz "Matrices 3D declaradas exitosamente:"
str_lit_81:    .asciz "- evaluacionesDetalladas: "
str_lit_82:    .asciz "- temperaturasPorDia: "
str_lit_83:    .asciz "\n--- MODIFICACION DE ELEMENTOS 3D ---"
str_lit_84:    .asciz "Cubo de evaluaciones detalladas inicializado:"
str_lit_85:    .asciz "- Estudiante 1, Matemáticas: ["
str_lit_86:    .asciz "- Estudiante 4, Biología: ["
dbl_lit_87:    .double 25.5
dbl_lit_88:    .double 21.8
str_lit_89:    .asciz "Temperaturas específicas modificadas"
str_lit_90:    .asciz "\n--- ACCESO A ELEMENTOS 3D ---"
str_lit_91:    .asciz "Análisis de evaluaciones detalladas:"
str_lit_92:    .asciz "Examen 1"
str_lit_93:    .asciz "Examen 2"
str_lit_94:    .asciz "Proyecto"
str_lit_95:    .asciz "    "
str_lit_96:    .asciz "Temperaturas registradas:"
str_lit_97:    .asciz "Semana 1"
str_lit_98:    .asciz "Semana 2"
str_lit_99:    .asciz "Lunes"
str_lit_100:    .asciz "Martes"
str_lit_101:    .asciz "Miércoles"
str_lit_102:    .asciz "Mañana"
str_lit_103:    .asciz "Tarde"
str_lit_104:    .asciz "Noche"
str_lit_105:    .asciz "°C"
str_lit_106:    .asciz "\n--- CALCULO DE PROMEDIOS ---"
str_lit_107:    .asciz "Suma total = "
str_lit_108:    .asciz "Cantidad de elementos = "
str_lit_109:    .asciz "Promedio = "
str_lit_110:    .asciz "\n=== ANALISIS DE DATOS ACADEMICOS COMPLETADO ==="

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
g_determinante2x2:    .quad 0
g_determinante3x3:    .quad 0
g_estudiante:    .quad 0
g_materia:    .quad 0
g_evaluacion:    .quad 0
g_semana:    .quad 0
g_dia:    .quad 0
g_periodo:    .quad 0
g_temp:    .quad 0
g_contador:    .quad 0
g_l:    .quad 0
.data
