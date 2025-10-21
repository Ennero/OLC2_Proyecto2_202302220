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
joinbuf:        .skip 1024
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

fn_mostrarInventario:
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
    mov w1, #0
    sub x16, x29, #48
    str w1, [x16]
L_for_cond_2:
    sub x16, x29, #48
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
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_1
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #48
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
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
    ldr x1, =str_lit_2
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #48
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
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
    ldr x1, =str_lit_3
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #48
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
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
    ldr x1, =str_lit_4
    bl printf
L_continue_2:
    sub x16, x29, #48
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #48
    str w20, [x16]
    b L_for_cond_2
L_break_2:
L_func_exit_1:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_mostrarInventarioCantidad:
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
    mov w1, #0
    sub x16, x29, #48
    str w1, [x16]
L_for_cond_4:
    sub x16, x29, #48
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
    beq L_break_4
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_1
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #48
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
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
    ldr x1, =str_lit_2
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #48
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
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
    ldr x1, =str_lit_5
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #48
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
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
    ldr x1, =str_lit_6
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
L_continue_4:
    sub x16, x29, #48
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #48
    str w20, [x16]
    b L_for_cond_4
L_break_4:
L_func_exit_3:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_ordenamientoBurbuja:
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
    sub x16, x29, #48
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
    ldr x1, =str_lit_8
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #64
    str w1, [x16]
L_for_cond_6:
    sub x16, x29, #64
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
    ldr w1, [x16]
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
    beq L_break_6
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #80
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #96
    str w1, [x16]
L_for_cond_7:
    sub x16, x29, #96
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #64
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
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
    beq L_break_7
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, gt
    cmp w1, #0
    beq L_end_8
L_then_8:
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub x16, x29, #112
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #112
    ldr w1, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr x1, [x0]
    add sp, sp, #16
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #128
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    mov w1, #0
    add sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr x1, [x0]
    add sp, sp, #16
    mov x0, x1
    bl strdup
    mov x1, x0
    ldr x9, [sp]
    add sp, sp, #16
    str x1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #128
    ldr w1, [x16]
    sub x16, x29, #128
    ldr x1, [x16]
    mov x0, x1
    bl strdup
    mov x1, x0
    ldr x9, [sp]
    add sp, sp, #16
    str x1, [x9]
    add sp, sp, #16
    mov w1, #1
    sub x16, x29, #80
    str w1, [x16]
L_end_8:
L_continue_7:
    sub x16, x29, #96
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #96
    str w20, [x16]
    b L_for_cond_7
L_break_7:
    sub x16, x29, #80
    ldr w1, [x16]
    eor w1, w1, #1
    cmp w1, #0
    beq L_end_9
L_then_9:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_9
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #64
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
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
    ldr x1, =str_lit_4
    bl printf
    b L_break_6
L_end_9:
L_continue_6:
    sub x16, x29, #64
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #64
    str w20, [x16]
    b L_for_cond_6
L_break_6:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
L_func_exit_5:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_ordenamientoSeleccion:
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
    ldr x1, =str_lit_8
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #64
    str w1, [x16]
L_for_cond_11:
    sub x16, x29, #64
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
    ldr w1, [x16]
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
    beq L_break_11
    sub sp, sp, #16
    sub x16, x29, #64
    ldr w1, [x16]
    sub x16, x29, #80
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #64
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub x16, x29, #96
    str w1, [x16]
L_for_cond_12:
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
    beq L_break_12
    sub sp, sp, #16
    sub x16, x29, #96
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    sub x16, x29, #80
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, gt
    cmp w1, #0
    beq L_end_13
L_then_13:
    sub x16, x29, #96
    ldr w1, [x16]
    sub x16, x29, #80
    str w1, [x16]
L_end_13:
L_continue_12:
    sub x16, x29, #96
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #96
    str w20, [x16]
    b L_for_cond_12
L_break_12:
    sub x16, x29, #80
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #64
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ne
    cmp w1, #0
    beq L_end_14
L_then_14:
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #64
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub x16, x29, #112
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #64
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    sub sp, sp, #16
    sub x16, x29, #80
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #80
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #112
    ldr w1, [x16]
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #64
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr x1, [x0]
    add sp, sp, #16
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #128
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #64
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    sub sp, sp, #16
    sub x16, x29, #80
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    mov w1, #0
    add sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #80
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr x1, [x0]
    add sp, sp, #16
    mov x0, x1
    bl strdup
    mov x1, x0
    ldr x9, [sp]
    add sp, sp, #16
    str x1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #80
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #128
    ldr w1, [x16]
    sub x16, x29, #128
    ldr x1, [x16]
    mov x0, x1
    bl strdup
    mov x1, x0
    ldr x9, [sp]
    add sp, sp, #16
    str x1, [x9]
    add sp, sp, #16
L_end_14:
L_continue_11:
    sub x16, x29, #64
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #64
    str w20, [x16]
    b L_for_cond_11
L_break_11:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_12
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
L_func_exit_10:
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
    ldr x1, =str_lit_13
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
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
    ldr x1, =str_lit_15
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_16
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_17
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_18
    str x1, [x22, x23, lsl #3]
    mov x23, #4
    ldr x1, =str_lit_19
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
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
    mov w1, #15000
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #250
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    mov w1, #800
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    mov w1, #3500
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    mov w1, #2200
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #32
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
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
    mov w1, #50
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    mov w1, #30
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    mov w1, #15
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    mov w1, #8
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #48
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
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
    mov w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    mov w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    mov w1, #1
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    mov w1, #0
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #64
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
    str w1, [sp, #0]
    mov w0, #1
    mov x1, sp
    bl new_array_flat
    sub x16, x29, #80
    str x0, [x16]
    add sp, sp, #16
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #5
    str w1, [sp, #0]
    mov w0, #1
    mov x1, sp
    bl new_array_flat_ptr
    sub x16, x29, #96
    str x0, [x16]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_20
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_23
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_24
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_25
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_26
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_27
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_28
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_29
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_30
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #32
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
    ldr x1, =str_lit_4
    bl printf
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
    sub sp, sp, #16
    mov w1, #1
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
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
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #64
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    mov x0, x1
    bl strdup
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
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #32
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #280
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #48
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #45
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #64
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #1
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_33
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
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
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #32
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_35
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #1
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
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
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #64
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    mov x0, x1
    bl strdup
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
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #1001
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #1002
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #1003
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #1004
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #80
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #1005
    ldr x9, [sp]
    add sp, sp, #16
    str w1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #0
    ldr x1, =str_lit_37
    mov x0, x1
    bl strdup
    mov x1, x0
    ldr x9, [sp]
    add sp, sp, #16
    str x1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #1
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #0
    ldr x1, =str_lit_38
    mov x0, x1
    bl strdup
    mov x1, x0
    ldr x9, [sp]
    add sp, sp, #16
    str x1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #2
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #0
    ldr x1, =str_lit_39
    mov x0, x1
    bl strdup
    mov x1, x0
    ldr x9, [sp]
    add sp, sp, #16
    str x1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #3
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #0
    ldr x1, =str_lit_40
    mov x0, x1
    bl strdup
    mov x1, x0
    ldr x9, [sp]
    add sp, sp, #16
    str x1, [x9]
    add sp, sp, #16
    sub sp, sp, #16
    mov w1, #4
    str w1, [sp, #0]
    sub x16, x29, #96
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    sub sp, sp, #16
    str x0, [sp]
    mov w1, #0
    ldr x1, =str_lit_41
    mov x0, x1
    bl strdup
    mov x1, x0
    ldr x9, [sp]
    add sp, sp, #16
    str x1, [x9]
    add sp, sp, #16
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_42
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_43
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_44
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #112
    str w1, [x16]
L_for_cond_16:
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
    beq L_break_16
    sub sp, sp, #16
    mov x1, #0
    sub x16, x29, #128
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #64
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    cmp w1, #0
    cset w1, ne
    cmp w1, #0
    beq L_else_17
L_then_17:
    ldr x1, =str_lit_45
    sub x16, x29, #128
    str x1, [x16]
    b L_end_17
L_else_17:
    ldr x1, =str_lit_46
    sub x16, x29, #128
    str x1, [x16]
L_end_17:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_47
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #112
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
    ldr x1, =str_lit_48
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
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
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #80
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_50
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_51
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
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_52
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #112
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_53
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #112
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_54
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #128
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
L_continue_16:
    sub x16, x29, #112
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #112
    str w20, [x16]
    b L_for_cond_16
L_break_16:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_55
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_56
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    mov w1, #0
    str w1, [sp, #0]
    sub x16, x29, #16
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_57
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #16
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
    sub x16, x29, #16
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
    ldr x1, =str_lit_4
    bl printf
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
    sub sp, sp, #16
    sub x16, x29, #16
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w1, w19, w1
    str w1, [sp, #0]
    sub x16, x29, #16
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_59
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_18
    sub x16, x29, #144
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr x9, [x16]
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
    sub x16, x29, #144
    ldr x1, [x16]
    mov x23, x1
    mov w20, #0
    mov w24, #-1
L_idxof_loop_s_18:
    cmp w20, w19
    b.ge L_idxof_done_s_18
    add x22, x21, x20, lsl #3
    ldr x0, [x22]
    // Compare element vs search (handle NULL)
    cmp x23, #0
    b.eq L_cmp_null_s_18
    // strcmp(elem, search) == 0?
    mov x1, x23
    bl strcmp
    cmp w0, #0
    b.eq L_idxof_found_s_18
    b L_idxof_next_s_18
L_cmp_null_s_18:
    cmp x0, #0
    b.eq L_idxof_found_s_18
L_idxof_next_s_18:
    add w20, w20, #1
    b L_idxof_loop_s_18
L_idxof_found_s_18:
    mov w24, w20
L_idxof_done_s_18:
    mov w1, w24
    sub x16, x29, #160
    str w1, [x16]
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    neg w1, w1
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ne
    cmp w1, #0
    beq L_else_19
L_then_19:
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
    sub x16, x29, #144
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_61
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_62
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
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
    sub x16, x29, #160
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #80
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_52
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #160
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #32
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_53
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #160
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
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_51
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #160
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
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    b L_end_19
L_else_19:
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
    sub x16, x29, #144
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_63
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
L_end_19:
    sub sp, sp, #16
    mov w1, #1003
    sub x16, x29, #176
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #80
    ldr x9, [x16]
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
    sub x16, x29, #176
    ldr w1, [x16]
    mov w22, w1
    mov w20, #0
    mov w24, #-1
L_idxof_loop_i_20:
    cmp w20, w19
    b.ge L_idxof_done_i_20
    add x14, x21, x20, lsl #2
    ldr w0, [x14]
    cmp w0, w22
    b.eq L_idxof_found_i_20
    add w20, w20, #1
    b L_idxof_loop_i_20
L_idxof_found_i_20:
    mov w24, w20
L_idxof_done_i_20:
    mov w1, w24
    sub x16, x29, #192
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_64
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #176
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
    ldr x1, =str_lit_65
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
    ldr x1, =str_lit_4
    bl printf
    sub x16, x29, #192
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    mov w1, #1
    neg w1, w1
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ne
    cmp w1, #0
    beq L_end_21
L_then_21:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_66
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #192
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #16
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
    ldr x1, =str_lit_4
    bl printf
L_end_21:
    sub sp, sp, #16
    ldr x1, =str_lit_67
    sub x16, x29, #208
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr x9, [x16]
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
    sub x16, x29, #208
    ldr x1, [x16]
    mov x23, x1
    mov w20, #0
    mov w24, #-1
L_idxof_loop_s_22:
    cmp w20, w19
    b.ge L_idxof_done_s_22
    add x22, x21, x20, lsl #3
    ldr x0, [x22]
    // Compare element vs search (handle NULL)
    cmp x23, #0
    b.eq L_cmp_null_s_22
    // strcmp(elem, search) == 0?
    mov x1, x23
    bl strcmp
    cmp w0, #0
    b.eq L_idxof_found_s_22
    b L_idxof_next_s_22
L_cmp_null_s_22:
    cmp x0, #0
    b.eq L_idxof_found_s_22
L_idxof_next_s_22:
    add w20, w20, #1
    b L_idxof_loop_s_22
L_idxof_found_s_22:
    mov w24, w20
L_idxof_done_s_22:
    mov w1, w24
    sub x16, x29, #224
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_68
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #208
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_69
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #224
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
    ldr x1, =str_lit_70
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_71
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    sub x16, x29, #16
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub x16, x29, #240
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub x16, x29, #256
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #48
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub x16, x29, #272
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #64
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub x16, x29, #288
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_72
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_73
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #240
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_74
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_75
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #272
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_76
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
    ldr x1, =str_lit_22
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    sub x16, x29, #240
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #256
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    mov w9, w1
    sub x16, x29, #256
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #272
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    mov w10, w1
    and w1, w9, w10
    mov w9, w1
    sub x16, x29, #272
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #288
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    mov w10, w1
    and w1, w9, w10
    sub x16, x29, #304
    str w1, [x16]
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
    sub x16, x29, #304
    ldr w1, [x16]
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    mov x0, x1
    bl strdup
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_78
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #320
    str w1, [x16]
    sub sp, sp, #16
    mov w1, #0
    sub x16, x29, #336
    str w1, [x16]
L_for_cond_23:
    sub x16, x29, #336
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #64
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_23
    sub sp, sp, #16
    sub x16, x29, #336
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #64
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    cmp w1, #0
    cset w1, ne
    cmp w1, #0
    beq L_end_24
L_then_24:
    sub x16, x29, #320
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #320
    str w20, [x16]
L_end_24:
L_continue_23:
    sub x16, x29, #336
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #336
    str w20, [x16]
    b L_for_cond_23
L_break_23:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_79
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
    ldr x1, =str_lit_80
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #240
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
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_81
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
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
    ldr x1, =str_lit_83
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
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
L_copy_decl_25:
    cmp w10, w19
    b.ge L_copy_done_decl_25
    add x14, x21, x10, lsl #3
    ldr x0, [x14]
    add x15, x22, x10, lsl #3
    str x0, [x15]
    add w10, w10, #1
    b L_copy_decl_25
L_copy_done_decl_25:
    ldr x1, =str_lit_84
    mov x0, x1
    bl strdup
    mov x1, x0
    add x15, x22, x19, lsl #3
    str x1, [x15]
    add sp, sp, #16
    sub x16, x29, #352
    str x20, [x16]
    sub x16, x29, #352
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
L_copy_26:
    cmp w10, w19
    b.ge L_copy_done_26
    add x14, x21, x10, lsl #3
    ldr x0, [x14]
    add x15, x22, x10, lsl #3
    str x0, [x15]
    add w10, w10, #1
    b L_copy_26
L_copy_done_26:
    ldr x1, =str_lit_85
    mov x0, x1
    bl strdup
    mov x1, x0
    add x15, x22, x19, lsl #3
    str x1, [x15]
    add sp, sp, #16
    sub x16, x29, #352
    str x20, [x16]
    sub x16, x29, #352
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
L_copy_27:
    cmp w10, w19
    b.ge L_copy_done_27
    add x14, x21, x10, lsl #3
    ldr x0, [x14]
    add x15, x22, x10, lsl #3
    str x0, [x15]
    add w10, w10, #1
    b L_copy_27
L_copy_done_27:
    ldr x1, =str_lit_86
    mov x0, x1
    bl strdup
    mov x1, x0
    add x15, x22, x19, lsl #3
    str x1, [x15]
    add sp, sp, #16
    sub x16, x29, #352
    str x20, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
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
L_copy_decl_28:
    cmp w10, w19
    b.ge L_copy_done_decl_28
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_decl_28
L_copy_done_decl_28:
    mov w1, #450
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #368
    str x20, [x16]
    sub x16, x29, #368
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
L_copy_29:
    cmp w10, w19
    b.ge L_copy_done_29
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_29
L_copy_done_29:
    mov w1, #320
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #368
    str x20, [x16]
    sub x16, x29, #368
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
L_copy_30:
    cmp w10, w19
    b.ge L_copy_done_30
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_30
L_copy_done_30:
    mov w1, #180
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #368
    str x20, [x16]
    sub sp, sp, #16
    sub x16, x29, #48
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
    mov w1, #25
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #384
    str x20, [x16]
    sub x16, x29, #384
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
L_copy_32:
    cmp w10, w19
    b.ge L_copy_done_32
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_32
L_copy_done_32:
    mov w1, #40
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #384
    str x20, [x16]
    sub x16, x29, #384
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
L_copy_33:
    cmp w10, w19
    b.ge L_copy_done_33
    add x14, x21, x10, lsl #2
    ldr w0, [x14]
    add x15, x22, x10, lsl #2
    str w0, [x15]
    add w10, w10, #1
    b L_copy_33
L_copy_done_33:
    mov w1, #15
    add x15, x22, x19, lsl #2
    str w1, [x15]
    add sp, sp, #16
    sub x16, x29, #384
    str x20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_87
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
    ldr x1, =str_lit_83
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_88
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    sub x16, x29, #16
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    sub x16, x29, #400
    str w1, [x16]
L_for_cond_34:
    sub x16, x29, #400
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
    beq L_break_34
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_89
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #400
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #352
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
    ldr x1, =str_lit_90
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #400
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #368
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
    ldr x1, =str_lit_91
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #400
    ldr w1, [x16]
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
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
L_continue_34:
    sub x16, x29, #400
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #400
    str w20, [x16]
    b L_for_cond_34
L_break_34:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_92
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #8
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
    mov w1, #15000
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    mov w1, #280
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    mov w1, #800
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    mov w1, #3500
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    mov w1, #2200
    str w1, [x22, x23, lsl #2]
    mov x23, #5
    mov w1, #450
    str w1, [x22, x23, lsl #2]
    mov x23, #6
    mov w1, #320
    str w1, [x22, x23, lsl #2]
    mov x23, #7
    mov w1, #180
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #416
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #8
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
    ldr x1, =str_lit_15
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_16
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_17
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_18
    str x1, [x22, x23, lsl #3]
    mov x23, #4
    ldr x1, =str_lit_19
    str x1, [x22, x23, lsl #3]
    mov x23, #5
    ldr x1, =str_lit_84
    str x1, [x22, x23, lsl #3]
    mov x23, #6
    ldr x1, =str_lit_85
    str x1, [x22, x23, lsl #3]
    mov x23, #7
    ldr x1, =str_lit_86
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #432
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_93
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub x16, x29, #432
    ldr x1, [x16]
    mov x0, x1
    sub x16, x29, #416
    ldr x1, [x16]
    mov x1, x1
    bl fn_mostrarInventario
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_94
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub x16, x29, #416
    ldr x1, [x16]
    mov x0, x1
    sub x16, x29, #432
    ldr x1, [x16]
    mov x1, x1
    bl fn_ordenamientoBurbuja
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_95
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub x16, x29, #432
    ldr x1, [x16]
    mov x0, x1
    sub x16, x29, #416
    ldr x1, [x16]
    mov x1, x1
    bl fn_mostrarInventario
    mov w1, w0
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #8
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
    mov w1, #45
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    mov w1, #30
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    mov w1, #15
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    mov w1, #8
    str w1, [x22, x23, lsl #2]
    mov x23, #5
    mov w1, #25
    str w1, [x22, x23, lsl #2]
    mov x23, #6
    mov w1, #40
    str w1, [x22, x23, lsl #2]
    mov x23, #7
    mov w1, #15
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #448
    str x0, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #8
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
    ldr x1, =str_lit_15
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_16
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_17
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_18
    str x1, [x22, x23, lsl #3]
    mov x23, #4
    ldr x1, =str_lit_19
    str x1, [x22, x23, lsl #3]
    mov x23, #5
    ldr x1, =str_lit_84
    str x1, [x22, x23, lsl #3]
    mov x23, #6
    ldr x1, =str_lit_85
    str x1, [x22, x23, lsl #3]
    mov x23, #7
    ldr x1, =str_lit_86
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #464
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_96
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub x16, x29, #464
    ldr x1, [x16]
    mov x0, x1
    sub x16, x29, #448
    ldr x1, [x16]
    mov x1, x1
    bl fn_mostrarInventarioCantidad
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_97
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub x16, x29, #448
    ldr x1, [x16]
    mov x0, x1
    sub x16, x29, #464
    ldr x1, [x16]
    mov x1, x1
    bl fn_ordenamientoSeleccion
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_98
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    sub x16, x29, #464
    ldr x1, [x16]
    mov x0, x1
    sub x16, x29, #448
    ldr x1, [x16]
    mov x1, x1
    bl fn_mostrarInventarioCantidad
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_99
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
L_func_exit_15:
    add sp, sp, #1024
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "  "
str_lit_2:    .asciz ". "
str_lit_3:    .asciz " - Q"
str_lit_4:    .asciz "\n"
str_lit_5:    .asciz " - "
str_lit_6:    .asciz " unidades"
str_lit_7:    .asciz "Iniciando ordenamiento burbuja para "
str_lit_8:    .asciz " elementos..."
str_lit_9:    .asciz "Ordenamiento completado temprano en iteración "
str_lit_10:    .asciz "Ordenamiento burbuja completado"
str_lit_11:    .asciz "Iniciando ordenamiento por selección para "
str_lit_12:    .asciz "Ordenamiento por selección completado"
str_lit_13:    .asciz "=== SISTEMA DE GESTION DE INVENTARIO ==="
str_lit_14:    .asciz "\n--- DECLARACION DE ARREGLOS ---"
str_lit_15:    .asciz "Laptop"
str_lit_16:    .asciz "Mouse"
str_lit_17:    .asciz "Teclado"
str_lit_18:    .asciz "Monitor"
str_lit_19:    .asciz "Impresora"
str_lit_20:    .asciz "Arreglos declarados exitosamente:"
str_lit_21:    .asciz "- productos: arreglo de String con "
str_lit_22:    .asciz " elementos"
str_lit_23:    .asciz "- precios: arreglo de int con "
str_lit_24:    .asciz "- cantidades: arreglo de int con "
str_lit_25:    .asciz "- disponibles: arreglo de boolean con "
str_lit_26:    .asciz "- codigosProducto: arreglo vacío de "
str_lit_27:    .asciz "- proveedores: arreglo vacío de "
str_lit_28:    .asciz "\n--- MODIFICACION DE ELEMENTOS ---"
str_lit_29:    .asciz "Estado inicial del Mouse:"
str_lit_30:    .asciz "- Precio: "
str_lit_31:    .asciz "- Cantidad: "
str_lit_32:    .asciz "- Disponible: "
str_lit_33:    .asciz "\nDespués de modificaciones:"
str_lit_34:    .asciz "- Nuevo precio Mouse: "
str_lit_35:    .asciz "- Nueva cantidad Mouse: "
str_lit_36:    .asciz "- Impresora ahora disponible: "
str_lit_37:    .asciz "TechCorp"
str_lit_38:    .asciz "DeviceMax"
str_lit_39:    .asciz "KeyboardPro"
str_lit_40:    .asciz "ScreenTech"
str_lit_41:    .asciz "PrintSolutions"
str_lit_42:    .asciz "Códigos y proveedores asignados correctamente"
str_lit_43:    .asciz "\n--- ACCESO A ELEMENTOS ---"
str_lit_44:    .asciz "Inventario completo:"
str_lit_45:    .asciz "DISPONIBLE"
str_lit_46:    .asciz "AGOTADO"
str_lit_47:    .asciz "Posición "
str_lit_48:    .asciz ":"
str_lit_49:    .asciz "  Código: "
str_lit_50:    .asciz "  Producto: "
str_lit_51:    .asciz "  Proveedor: "
str_lit_52:    .asciz "  Precio: Q"
str_lit_53:    .asciz "  Cantidad: "
str_lit_54:    .asciz "  Estado: "
str_lit_55:    .asciz "Acceso directo a elementos específicos:"
str_lit_56:    .asciz "Primer producto: "
str_lit_57:    .asciz "Último producto: "
str_lit_58:    .asciz "Producto del medio: "
str_lit_59:    .asciz "\n--- BUSQUEDA CON Arrays.indexOf ---"
str_lit_60:    .asciz "Producto '"
str_lit_61:    .asciz "' encontrado en posición: "
str_lit_62:    .asciz "Detalles:"
str_lit_63:    .asciz "' no encontrado"
str_lit_64:    .asciz "Código "
str_lit_65:    .asciz " encontrado en posición: "
str_lit_66:    .asciz "Corresponde al producto: "
str_lit_67:    .asciz "Tablet"
str_lit_68:    .asciz "Búsqueda de '"
str_lit_69:    .asciz "': "
str_lit_70:    .asciz " (no encontrado)"
str_lit_71:    .asciz "\n--- TAMAÑO DE ARREGLOS (length) ---"
str_lit_72:    .asciz "Información de tamaños:"
str_lit_73:    .asciz "- Productos: "
str_lit_74:    .asciz "- Precios: "
str_lit_75:    .asciz "- Cantidades: "
str_lit_76:    .asciz "- Disponibilidad: "
str_lit_77:    .asciz "Todos los arreglos tienen el mismo tamaño: "
str_lit_78:    .asciz "\nUso de length en iteraciones:"
str_lit_79:    .asciz "Productos disponibles: "
str_lit_80:    .asciz " de "
str_lit_81:    .asciz "\n--- AGREGAR ELEMENTOS CON add() ---"
str_lit_82:    .asciz "Estado inicial: "
str_lit_83:    .asciz " productos"
str_lit_84:    .asciz "Webcam"
str_lit_85:    .asciz "Audífonos"
str_lit_86:    .asciz "Micrófono"
str_lit_87:    .asciz "Después de agregar: "
str_lit_88:    .asciz "Nuevos productos agregados:"
str_lit_89:    .asciz "- "
str_lit_90:    .asciz " | Precio: Q"
str_lit_91:    .asciz " | Cantidad: "
str_lit_92:    .asciz "\n--- ALGORITMOS DE ORDENAMIENTO ---"
str_lit_93:    .asciz "Productos antes del ordenamiento (por precio):"
str_lit_94:    .asciz "\nAplicando ordenamiento BURBUJA (precio ascendente):"
str_lit_95:    .asciz "Productos después del ordenamiento burbuja:"
str_lit_96:    .asciz "\nProductos antes del ordenamiento por SELECCION (cantidad descendente):"
str_lit_97:    .asciz "\nAplicando ordenamiento SELECCION (cantidad descendente):"
str_lit_98:    .asciz "Productos después del ordenamiento por selección:"
str_lit_99:    .asciz "\n=== GESTION DE INVENTARIO COMPLETADA ==="

// --- Variables globales ---
g_i:    .quad 0
g_n:    .quad 0
g_huboCambios:    .quad 0
g_j:    .quad 0
g_tempValor:    .quad 0
g_tempNombre:    .quad 0
g_indiceMayor:    .quad 0
g_estado:    .quad 0
g_productoBuscado:    .quad 0
g_posicionProducto:    .quad 0
g_codigoBuscado:    .quad 1003
g_posicionCodigo:    .quad 0
g_productoInexistente:    .quad 0
g_posicionInexistente:    .quad 0
g_totalProductos:    .quad 0
g_totalPrecios:    .quad 0
g_totalCantidades:    .quad 0
g_totalDisponibles:    .quad 0
g_datosConsistentes:    .quad 0
g_productosDisponibles:    .quad 0
.data
