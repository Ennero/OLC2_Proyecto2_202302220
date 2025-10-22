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

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    sub sp, sp, #1024
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #1000
    sub x16, x29, #16
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #30
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #16
    sub x16, x29, #48
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_4
    sub x16, x29, #64
    str x1, [x16]
    sub sp, sp, #16
    movz w1, #20
    sub x16, x29, #80
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #5
    sub x16, x29, #96
    str w1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_5
    sub x16, x29, #112
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_6
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #64
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
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    // String concatenation to tmpbuf
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_7
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #80
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
    ldr x1, =tmpbuf
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #128
    str x1, [x16]
    sub x16, x29, #80
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #18
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    beq L_else_106
L_then_106:
    // string += (local)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #128
    ldr x1, [x16]
    cmp x1, #0
    ldr x17, =null_str
    csel x1, x17, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_9
    ldr x0, =joinbuf
    bl strcpy
    ldr x0, =tmpbuf
    ldr x1, =joinbuf
    bl strcat
    ldr x0, =tmpbuf
    bl strdup
    sub x16, x29, #128
    str x0, [x16]
    b L_end_106
L_else_106:
    // string += (local)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #128
    ldr x1, [x16]
    cmp x1, #0
    ldr x17, =null_str
    csel x1, x17, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_10
    ldr x0, =joinbuf
    bl strcpy
    ldr x0, =tmpbuf
    ldr x1, =joinbuf
    bl strcat
    ldr x0, =tmpbuf
    bl strdup
    sub x16, x29, #128
    str x0, [x16]
L_end_106:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    sub x16, x29, #128
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_11
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #80
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #18
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    beq L_else_107
L_then_107:
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
    sub x16, x29, #96
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
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_13
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #112
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
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_14
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_107
L_else_107:
    sub x16, x29, #80
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
    beq L_else_108
L_then_108:
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
    sub x16, x29, #96
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
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_13
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #112
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
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_108
L_else_108:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_end_108:
L_end_107:
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_17
    sub x16, x29, #144
    str x1, [x16]
    sub sp, sp, #16
    movz w1, #16
    sub x16, x29, #160
    str w1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_18
    sub x16, x29, #176
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_6
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
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    // String concatenation to tmpbuf
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_7
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
    ldr x1, =str_lit_8
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =tmpbuf
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #192
    str x1, [x16]
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #18
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    beq L_else_109
L_then_109:
    // string += (local)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #192
    ldr x1, [x16]
    cmp x1, #0
    ldr x17, =null_str
    csel x1, x17, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_9
    ldr x0, =joinbuf
    bl strcpy
    ldr x0, =tmpbuf
    ldr x1, =joinbuf
    bl strcat
    ldr x0, =tmpbuf
    bl strdup
    sub x16, x29, #192
    str x0, [x16]
    b L_end_109
L_else_109:
    // string += (local)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #192
    ldr x1, [x16]
    cmp x1, #0
    ldr x17, =null_str
    csel x1, x17, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_10
    ldr x0, =joinbuf
    bl strcpy
    ldr x0, =tmpbuf
    ldr x1, =joinbuf
    bl strcat
    ldr x0, =tmpbuf
    bl strdup
    sub x16, x29, #192
    str x0, [x16]
L_end_109:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    sub x16, x29, #192
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_11
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub x16, x29, #160
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #18
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    beq L_else_110
L_then_110:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_19
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_110
L_else_110:
    sub x16, x29, #160
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
    beq L_else_111
L_then_111:
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
    sub x16, x29, #96
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
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_13
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #176
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
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_15
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_111
L_else_111:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_16
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_end_111:
L_end_110:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_20
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
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
    ldr x1, =str_lit_21
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_22
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_23
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_24
    str x1, [x22, x23, lsl #3]
    mov x23, #4
    ldr x1, =str_lit_25
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #208
    str x0, [x16]
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
    ldr x1, =str_lit_26
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_27
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_28
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_29
    str x1, [x22, x23, lsl #3]
    mov x23, #4
    ldr x1, =str_lit_30
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #224
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #240
    str w1, [x16]
L_while_cond_112:
    sub x16, x29, #240
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #208
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_112
    sub sp, sp, #16
    sub x16, x29, #240
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub x16, x29, #256
    str w1, [x16]
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
    ldr x1, =str_lit_32
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #240
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #208
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
    ldr x1, =str_lit_33
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #240
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
    ldr x1, =str_lit_34
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
    sub x16, x29, #240
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #240
    str w20, [x16]
L_continue_112:
    b L_while_cond_112
L_break_112:
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
    ldr x1, =str_lit_36
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
    ldr x1, =str_lit_37
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_38
    sub x16, x29, #272
    str x1, [x16]
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
    movz w1, #85
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #92
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #78
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #288
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #304
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_6
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #272
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
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #320
    str w1, [x16]
L_for_cond_113:
    sub x16, x29, #320
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #288
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_113
    sub sp, sp, #16
    sub x16, x29, #320
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub x16, x29, #336
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_39
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
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
    ldr x1, =str_lit_32
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #320
    ldr w1, [x16]
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
    ldr x1, =str_lit_40
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
    sub x16, x29, #304
    ldr w19, [x16]
    sub sp, sp, #16
    sub x16, x29, #320
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #288
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    add w1, w19, w1
    sub x16, x29, #304
    str w1, [x16]
L_continue_113:
    sub x16, x29, #320
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #320
    str w20, [x16]
    b L_for_cond_113
L_break_113:
    sub sp, sp, #16
    sub x16, x29, #304
    ldr w1, [x16]
    scvtf d0, w1
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #288
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr d8, [sp]
    scvtf d9, w1
    fdiv d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #352
    str d0, [x16]
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
    sub x16, x29, #352
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
    sub x16, x29, #352
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    ldr x16, =dbl_lit_42
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    add sp, sp, #16
    fcmp d8, d9
    cset w1, ge
    cmp w1, #0
    beq L_else_114
L_then_114:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_43
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_114
L_else_114:
    sub x16, x29, #352
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    ldr x16, =dbl_lit_44
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    add sp, sp, #16
    fcmp d8, d9
    cset w1, ge
    cmp w1, #0
    beq L_else_115
L_then_115:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_45
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_115
L_else_115:
    sub x16, x29, #352
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    ldr x16, =dbl_lit_46
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    add sp, sp, #16
    fcmp d8, d9
    cset w1, ge
    cmp w1, #0
    beq L_else_116
L_then_116:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_47
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_116
L_else_116:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_48
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_end_116:
L_end_115:
L_end_114:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_49
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #2
    sub x16, x29, #368
    str w1, [x16]
    sub sp, sp, #16
    // String concatenation to tmpbuf
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_50
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #368
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
    ldr x1, =tmpbuf
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #384
    str x1, [x16]
    sub x16, x29, #368
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    cmp w1, #0
    beq L_end_117
L_then_117:
    // string += (local)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #384
    ldr x1, [x16]
    cmp x1, #0
    ldr x17, =null_str
    csel x1, x17, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_51
    ldr x0, =joinbuf
    bl strcpy
    ldr x0, =tmpbuf
    ldr x1, =joinbuf
    bl strcat
    ldr x0, =tmpbuf
    bl strdup
    sub x16, x29, #384
    str x0, [x16]
L_end_117:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    sub x16, x29, #384
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_11
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // --- Generando switch ---
    sub x16, x29, #368
    ldr w1, [x16]
    mov w19, w1
    // comparar selector int con case int
    movz w1, #1
    mov w20, w1
    cmp w19, w20
    beq L_case_0_118
    // comparar selector int con case int
    movz w1, #2
    mov w20, w1
    cmp w19, w20
    beq L_case_1_118
    // comparar selector int con case int
    movz w1, #3
    mov w20, w1
    cmp w19, w20
    beq L_case_2_118
    // comparar selector int con case int
    movz w1, #4
    mov w20, w1
    cmp w19, w20
    beq L_case_3_118
    // comparar selector int con case int
    movz w1, #5
    mov w20, w1
    cmp w19, w20
    beq L_case_4_118
    b L_default_118
L_case_0_118:
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
    b L_break_118
L_case_1_118:
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
    ldr x1, =str_lit_54
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_break_118
L_case_2_118:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_55
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_56
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_break_118
L_case_3_118:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_57
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_58
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_break_118
L_case_4_118:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_59
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_60
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_break_118
L_default_118:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_61
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_62
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_break_118:
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #6
    sub x16, x29, #400
    str w1, [x16]
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
    sub x16, x29, #400
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
    ldr x1, =str_lit_2
    bl printf
    // --- Generando switch ---
    sub x16, x29, #400
    ldr w1, [x16]
    mov w19, w1
    // comparar selector int con case int
    movz w1, #1
    mov w20, w1
    cmp w19, w20
    beq L_case_0_119
    // comparar selector int con case int
    movz w1, #2
    mov w20, w1
    cmp w19, w20
    beq L_case_1_119
    // comparar selector int con case int
    movz w1, #3
    mov w20, w1
    cmp w19, w20
    beq L_case_2_119
    // comparar selector int con case int
    movz w1, #4
    mov w20, w1
    cmp w19, w20
    beq L_case_3_119
    // comparar selector int con case int
    movz w1, #5
    mov w20, w1
    cmp w19, w20
    beq L_case_4_119
    b L_default_119
L_case_0_119:
L_case_1_119:
L_case_2_119:
L_case_3_119:
L_case_4_119:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_64
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_break_119
L_default_119:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_61
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_62
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_break_119:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_65
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
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
    ldr x1, =str_lit_66
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_67
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_68
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_69
    str x1, [x22, x23, lsl #3]
    mov x23, #4
    ldr x1, =str_lit_70
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #416
    str x0, [x16]
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
    ldr x1, =str_lit_71
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_72
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_73
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_74
    str x1, [x22, x23, lsl #3]
    mov x23, #4
    ldr x1, =str_lit_75
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #432
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_76
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #448
    str w1, [x16]
L_for_cond_120:
    sub x16, x29, #448
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #416
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_120
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub sp, sp, #16
    sub x16, x29, #448
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #416
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
    ldr x1, =str_lit_32
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #448
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #432
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
L_continue_120:
    sub x16, x29, #448
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #448
    str w20, [x16]
    b L_for_cond_120
L_break_120:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_77
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #9
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
    movz w1, #85
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #75
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #65
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    movz w1, #55
    str w1, [x22, x23, lsl #2]
    mov x23, #5
    movz w1, #45
    str w1, [x22, x23, lsl #2]
    mov x23, #6
    movz w1, #35
    str w1, [x22, x23, lsl #2]
    mov x23, #7
    movz w1, #85
    str w1, [x22, x23, lsl #2]
    mov x23, #8
    movz w1, #90
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #464
    str x0, [x16]
    sub x16, x29, #464
    ldr x9, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w20, #0
    sub x16, x29, #496
    str w20, [x16]
L_for_cond_121:
    // ForEach: recomputar base de datos y longitud
    sub x16, x29, #464
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
    sub x16, x29, #496
    ldr w20, [x16]
    cmp w20, w19
    b.ge L_break_121
    add x22, x21, x20, lsl #2
    ldr w1, [x22]
    sub x16, x29, #480
    str w1, [x16]
    sub x16, x29, #496
    str w20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_78
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #480
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
    ldr x1, =str_lit_79
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
    sub x16, x29, #480
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #40
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_end_122
L_then_122:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_80
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_break_121
L_end_122:
    sub x16, x29, #480
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #50
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_end_123
L_then_123:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_80
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_continue_121
L_end_123:
    sub x16, x29, #480
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #90
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    beq L_else_124
L_then_124:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_81
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_124
L_else_124:
    sub x16, x29, #480
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #80
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    beq L_else_125
L_then_125:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_82
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_125
L_else_125:
    sub x16, x29, #480
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #70
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    beq L_else_126
L_then_126:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_83
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    b L_end_126
L_else_126:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_84
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_end_126:
L_end_125:
L_end_124:
L_continue_121:
    sub x16, x29, #496
    ldr w20, [x16]
    add w20, w20, #1
    sub x16, x29, #496
    str w20, [x16]
    b L_for_cond_121
L_break_121:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_85
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
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
    movz w1, #88
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #76
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #94
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #82
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    movz w1, #90
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #512
    str x0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_86
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #1
    sub x16, x29, #528
    str w1, [x16]
    sub x16, x29, #512
    ldr x9, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w20, #0
    sub x16, x29, #560
    str w20, [x16]
L_for_cond_127:
    // ForEach: recomputar base de datos y longitud
    sub x16, x29, #512
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
    sub x16, x29, #560
    ldr w20, [x16]
    cmp w20, w19
    b.ge L_break_127
    add x22, x21, x20, lsl #2
    ldr w1, [x22]
    sub x16, x29, #544
    str w1, [x16]
    sub x16, x29, #560
    str w20, [x16]
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
    ldr x1, =str_lit_32
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #544
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
    ldr x1, =str_lit_40
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
    sub x16, x29, #528
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #528
    str w20, [x16]
L_continue_127:
    sub x16, x29, #560
    ldr w20, [x16]
    add w20, w20, #1
    sub x16, x29, #560
    str w20, [x16]
    b L_for_cond_127
L_break_127:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_88
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #100
    sub x16, x29, #576
    str w1, [x16]
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_90
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #50000
    sub x16, x29, #592
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_91
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #592
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
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_92
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_93
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #30
    sub x16, x29, #608
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_94
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
    sub sp, sp, #16
    movz w1, #15
    sub x16, x29, #624
    str w1, [x16]
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
    sub x16, x29, #624
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
    ldr x1, =str_lit_96
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
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
    ldr x1, =str_lit_97
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_27
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_28
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_29
    str x1, [x22, x23, lsl #3]
    mov x23, #4
    ldr x1, =str_lit_30
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #640
    str x0, [x16]
    sub x16, x29, #640
    ldr x9, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w20, #0
    sub x16, x29, #672
    str w20, [x16]
L_for_cond_128:
    // ForEach: recomputar base de datos y longitud
    sub x16, x29, #640
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
    sub x16, x29, #672
    ldr w20, [x16]
    cmp w20, w19
    b.ge L_break_128
    add x22, x21, x20, lsl #3
    ldr x1, [x22]
    sub x16, x29, #656
    str x1, [x16]
    sub x16, x29, #672
    str w20, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_98
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #656
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
    ldr x1, =str_lit_2
    bl printf
L_continue_128:
    sub x16, x29, #672
    ldr w20, [x16]
    add w20, w20, #1
    sub x16, x29, #672
    str w20, [x16]
    b L_for_cond_128
L_break_128:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_99
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
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
    movz w1, #3
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #4
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #5
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #2
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    movz w1, #4
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #688
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #150
    sub x16, x29, #704
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #1
    sub x16, x29, #720
    str w1, [x16]
L_for_cond_129:
    sub x16, x29, #720
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, le
    cmp w1, #0
    beq L_break_129
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_100
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #720
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
    ldr x1, =str_lit_101
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
    sub x16, x29, #736
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #752
    str w1, [x16]
L_for_cond_130:
    sub x16, x29, #752
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #688
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_130
    sub sp, sp, #16
    sub sp, sp, #16
    sub x16, x29, #752
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #688
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #704
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    sub x16, x29, #768
    str w1, [x16]
    sub x16, x29, #736
    ldr w19, [x16]
    sub x16, x29, #768
    ldr w1, [x16]
    add w1, w19, w1
    sub x16, x29, #736
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_102
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #752
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
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
    ldr x1, =str_lit_32
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #752
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #688
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
    ldr x1, =str_lit_103
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #768
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
L_continue_130:
    sub x16, x29, #752
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #752
    str w20, [x16]
    b L_for_cond_130
L_break_130:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_104
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #736
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
L_continue_129:
    sub x16, x29, #720
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #720
    str w20, [x16]
    b L_for_cond_129
L_break_129:
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
    ldr x1, =str_lit_107
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_108
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_21
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #784
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
    ldr x1, =str_lit_109
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_110
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_111
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #800
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
    movz w1, #85
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #92
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #78
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
    movz w1, #90
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #87
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #82
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
    movz w1, #88
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #95
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #91
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    ldp x20, x21, [sp]
    add sp, sp, #32
    mov x23, #2
    str x0, [x21, x23, lsl #3]
    mov x0, x20
    add sp, sp, #16
    sub x16, x29, #816
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #832
    str w1, [x16]
L_for_cond_131:
    sub x16, x29, #832
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #784
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_131
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_6
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #832
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #784
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
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #848
    str w1, [x16]
L_for_cond_132:
    sub x16, x29, #848
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #800
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_132
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_112
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #848
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #800
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
    ldr x1, =str_lit_32
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #832
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #848
    ldr w1, [x16]
    str w1, [sp, #4]
    sub x16, x29, #816
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
    ldr x1, =str_lit_113
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
L_continue_132:
    sub x16, x29, #848
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #848
    str w20, [x16]
    b L_for_cond_132
L_break_132:
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_131:
    sub x16, x29, #832
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #832
    str w20, [x16]
    b L_for_cond_131
L_break_131:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_114
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
    ldr x1, =str_lit_115
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_116
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_117
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #864
    str x0, [x16]
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
    movz w1, #150
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #180
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #200
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #880
    str x0, [x16]
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
    movz w1, #120
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #160
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #175
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #896
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #912
    str w1, [x16]
L_for_cond_133:
    sub x16, x29, #912
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #864
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_133
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_118
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #912
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #864
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_119
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #912
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #880
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_120
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #912
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #896
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
    sub x16, x29, #912
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #896
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    scvtf d0, w1
    sub sp, sp, #16
    str d0, [sp]
    sub sp, sp, #16
    sub x16, x29, #912
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #880
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #16
    ldr d8, [sp]
    scvtf d9, w1
    fdiv d0, d8, d9
    add sp, sp, #16
    sub sp, sp, #16
    str d0, [sp]
    ldr x16, =dbl_lit_121
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #928
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_122
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #928
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
    ldr x1, =str_lit_123
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
    ldr x1, =str_lit_124
    sub x16, x29, #944
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #928
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    movz w1, #10
    ldr d8, [sp]
    scvtf d9, w1
    fdiv d0, d8, d9
    add sp, sp, #16
    fcvtzs w1, d0
    sub x16, x29, #960
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #976
    str w1, [x16]
L_for_cond_134:
    sub x16, x29, #976
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #10
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_134
    sub x16, x29, #976
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #960
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_else_135
L_then_135:
    // string += (local)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #944
    ldr x1, [x16]
    cmp x1, #0
    ldr x17, =null_str
    csel x1, x17, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_125
    ldr x0, =joinbuf
    bl strcpy
    ldr x0, =tmpbuf
    ldr x1, =joinbuf
    bl strcat
    ldr x0, =tmpbuf
    bl strdup
    sub x16, x29, #944
    str x0, [x16]
    b L_end_135
L_else_135:
    // string += (local)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #944
    ldr x1, [x16]
    cmp x1, #0
    ldr x17, =null_str
    csel x1, x17, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_126
    ldr x0, =joinbuf
    bl strcpy
    ldr x0, =tmpbuf
    ldr x1, =joinbuf
    bl strcat
    ldr x0, =tmpbuf
    bl strdup
    sub x16, x29, #944
    str x0, [x16]
L_end_135:
L_continue_134:
    sub x16, x29, #976
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #976
    str w20, [x16]
    b L_for_cond_134
L_break_134:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    sub x16, x29, #944
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_11
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=0
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_133:
    sub x16, x29, #912
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #912
    str w20, [x16]
    b L_for_cond_133
L_break_133:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_127
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
    ldr x1, =str_lit_26
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_27
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_28
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #992
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
    ldr x16, =dbl_lit_128
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #1
    ldr x16, =dbl_lit_129
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    mov x23, #2
    ldr x16, =dbl_lit_130
    ldr d0, [x16]
    str d0, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #1008
    str x0, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_131
    ldr d0, [x16]
    sub x16, x29, #1024
    str d0, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_105
    sub x16, x29, #1040
    str x1, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #1056
    str w1, [x16]
L_for_cond_136:
    sub x16, x29, #1056
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #992
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_136
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_132
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #1056
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #992
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
    ldr x1, =str_lit_32
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #1056
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #1008
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
    ldr x1, =str_lit_113
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
    sub x16, x29, #1056
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #1008
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr d0, [x0]
    add sp, sp, #16
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #1024
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    add sp, sp, #16
    fcmp d8, d9
    cset w1, gt
    cmp w1, #0
    beq L_end_137
L_then_137:
    sub sp, sp, #16
    sub x16, x29, #1056
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #1008
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr d0, [x0]
    add sp, sp, #16
    sub x16, x29, #1024
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #1056
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #992
    ldr x0, [x16]
    mov x1, sp
    mov w2, #1
    bl array_element_addr_ptr
    ldr x1, [x0]
    add sp, sp, #16
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #1040
    str x1, [x16]
L_end_137:
L_continue_136:
    sub x16, x29, #1056
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #1056
    str w20, [x16]
    b L_for_cond_136
L_break_136:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_133
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #1040
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_134
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #1024
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
    ldr x1, =str_lit_113
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_135
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
    ldr x1, =str_lit_136
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_137
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_138
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #1072
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
    ldr x1, =str_lit_139
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_140
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_141
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_142
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #1088
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #0
    sub x16, x29, #1104
    str w1, [x16]
L_for_cond_138:
    sub x16, x29, #1104
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #1072
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_138
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub sp, sp, #16
    sub x16, x29, #1104
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #1072
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
    ldr x1, =str_lit_101
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
    sub x16, x29, #1120
    str w1, [x16]
L_for_cond_139:
    sub x16, x29, #1120
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #1088
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, lt
    cmp w1, #0
    beq L_break_139
    sub sp, sp, #16
    sub x16, x29, #1104
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #1120
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w21, w19, w1
    msub w1, w21, w1, w19
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #0
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    sub x16, x29, #1136
    str w1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_105
    sub x16, x29, #1152
    str x1, [x16]
    sub x16, x29, #1136
    ldr w1, [x16]
    cmp w1, #0
    beq L_else_140
L_then_140:
    ldr x1, =str_lit_143
    sub x16, x29, #1152
    str x1, [x16]
    b L_end_140
L_else_140:
    ldr x1, =str_lit_144
    sub x16, x29, #1152
    str x1, [x16]
L_end_140:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_112
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub sp, sp, #16
    sub x16, x29, #1120
    ldr w1, [x16]
    str w1, [sp, #0]
    sub x16, x29, #1088
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
    ldr x1, =str_lit_79
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #1152
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
    ldr x1, =str_lit_2
    bl printf
L_continue_139:
    sub x16, x29, #1120
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #1120
    str w20, [x16]
    b L_for_cond_139
L_break_139:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_105
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_continue_138:
    sub x16, x29, #1104
    ldr w1, [x16]
    add w20, w1, #1
    sub x16, x29, #1104
    str w20, [x16]
    b L_for_cond_138
L_break_138:
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_145
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_105:
    add sp, sp, #1024
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "=== SISTEMA DE GESTIÓN ESTUDIANTIL ==="
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "\n--- SISTEMA DE INSCRIPCIONES ---"
str_lit_4:    .asciz "Ana García"
str_lit_5:    .asciz "Matemáticas"
str_lit_6:    .asciz "Estudiante: "
str_lit_7:    .asciz "Edad: "
str_lit_8:    .asciz " años - "
str_lit_9:    .asciz "Puede inscribirse"
str_lit_10:    .asciz "Requiere autorización"
str_lit_11:    .asciz "null"
str_lit_12:    .asciz "Cursos disponibles: "
str_lit_13:    .asciz "Seleccionó curso: "
str_lit_14:    .asciz "Estado: Inscrita exitosamente"
str_lit_15:    .asciz "Estado: Pendiente autorización"
str_lit_16:    .asciz "Estado: Rechazado por edad"
str_lit_17:    .asciz "Luis Pérez"
str_lit_18:    .asciz "Historia"
str_lit_19:    .asciz "Estado: Inscrito exitosamente"
str_lit_20:    .asciz "\n--- PROCESAMIENTO POR LOTES ---"
str_lit_21:    .asciz "María"
str_lit_22:    .asciz "Juan"
str_lit_23:    .asciz "Carmen"
str_lit_24:    .asciz "Pedro"
str_lit_25:    .asciz "Sofia"
str_lit_26:    .asciz "Ingeniería"
str_lit_27:    .asciz "Medicina"
str_lit_28:    .asciz "Derecho"
str_lit_29:    .asciz "Arquitectura"
str_lit_30:    .asciz "Psicología"
str_lit_31:    .asciz "Procesando estudiante "
str_lit_32:    .asciz ": "
str_lit_33:    .asciz " ("
str_lit_34:    .asciz ")"
str_lit_35:    .asciz "Total procesados: "
str_lit_36:    .asciz " estudiantes"
str_lit_37:    .asciz "\n--- SISTEMA DE EVALUACIÓN ---"
str_lit_38:    .asciz "Roberto"
str_lit_39:    .asciz "Examen "
str_lit_40:    .asciz " puntos"
str_lit_41:    .asciz "Promedio: "
dbl_lit_42:    .double 90.0
str_lit_43:    .asciz "Resultado: Aprobado con honores"
dbl_lit_44:    .double 80.0
str_lit_45:    .asciz "Resultado: Aprobado"
dbl_lit_46:    .double 70.0
str_lit_47:    .asciz "Resultado: Aprobado condicionalmente"
str_lit_48:    .asciz "Resultado: Reprobado"
str_lit_49:    .asciz "\n--- CONTROL DE ACCESO POR HORARIOS ---"
str_lit_50:    .asciz "Día de la semana: "
str_lit_51:    .asciz " (Martes)"
str_lit_52:    .asciz "Horario: Clases matutinas"
str_lit_53:    .asciz "Estado: Biblioteca abierta"
str_lit_54:    .asciz "Estado: Aula 101 disponible"
str_lit_55:    .asciz "Horario: Laboratorios"
str_lit_56:    .asciz "Estado: Equipos disponibles"
str_lit_57:    .asciz "Horario: Clases vespertinas"
str_lit_58:    .asciz "Estado: Cafetería abierta"
str_lit_59:    .asciz "Horario: Exámenes"
str_lit_60:    .asciz "Estado: Modo silencioso"
str_lit_61:    .asciz "Horario: Fin de semana"
str_lit_62:    .asciz "Estado: Campus cerrado"
str_lit_63:    .asciz " (Sábado)"
str_lit_64:    .asciz "Estado: Campus operativo"
str_lit_65:    .asciz "\n--- GENERACIÓN DE HORARIOS ---"
str_lit_66:    .asciz "Lunes"
str_lit_67:    .asciz "Martes"
str_lit_68:    .asciz "Miércoles"
str_lit_69:    .asciz "Jueves"
str_lit_70:    .asciz "Viernes"
str_lit_71:    .asciz "Cálculo I"
str_lit_72:    .asciz "Física I"
str_lit_73:    .asciz "Química General"
str_lit_74:    .asciz "Programación"
str_lit_75:    .asciz "Inglés Técnico"
str_lit_76:    .asciz "Semana académica:"
str_lit_77:    .asciz "\n--- ANÁLISIS DE NOTAS ---"
str_lit_78:    .asciz "Revisando calificación: "
str_lit_79:    .asciz " - "
str_lit_80:    .asciz "Muy baja, necesita tutoría"
str_lit_81:    .asciz "Excelente, continuar"
str_lit_82:    .asciz "Buena, continuar"
str_lit_83:    .asciz "Regular, continuar"
str_lit_84:    .asciz "Baja, continuar"
str_lit_85:    .asciz "\n--- ESTADÍSTICAS DE CURSOS ---"
str_lit_86:    .asciz "Curso de Matemáticas:"
str_lit_87:    .asciz "Estudiante "
str_lit_88:    .asciz "\n--- CONTROL DE AMBIENTES ---"
str_lit_89:    .asciz "En ambiente global: variable = "
str_lit_90:    .asciz "Entrando a función administrativa"
str_lit_91:    .asciz "En ambiente local: presupuesto = "
str_lit_92:    .asciz "Acceso a variable global desde local: "
str_lit_93:    .asciz "Saliendo de función administrativa"
str_lit_94:    .asciz "En ambiente de aula: capacidad = "
str_lit_95:    .asciz "En ambiente de laboratorio: equipos = "
str_lit_96:    .asciz "\n--- REGISTRO DE CARRERAS ---"
str_lit_97:    .asciz "Ingeniería en Sistemas"
str_lit_98:    .asciz "Carrera encontrada: "
str_lit_99:    .asciz "\n--- CÁLCULO DE MATRÍCULA POR CRÉDITOS ---"
str_lit_100:    .asciz "Semestre "
str_lit_101:    .asciz ":"
str_lit_102:    .asciz "  Materia "
str_lit_103:    .asciz " créditos = Q"
str_lit_104:    .asciz "  Total semestre: Q"
str_lit_105:    .asciz ""
str_lit_106:    .asciz "--- REPORTE DE CALIFICACIONES ---"
str_lit_107:    .asciz "Ana"
str_lit_108:    .asciz "Luis"
str_lit_109:    .asciz "Mate"
str_lit_110:    .asciz "Física"
str_lit_111:    .asciz "Química"
str_lit_112:    .asciz "  "
str_lit_113:    .asciz " pts"
str_lit_114:    .asciz "--- ANÁLISIS DE RENDIMIENTO ACADÉMICO ---"
str_lit_115:    .asciz "Enero"
str_lit_116:    .asciz "Febrero"
str_lit_117:    .asciz "Marzo"
str_lit_118:    .asciz "Período: "
str_lit_119:    .asciz "  Inscritos: "
str_lit_120:    .asciz "  Aprobados: "
dbl_lit_121:    .double 100.0
str_lit_122:    .asciz "  Porcentaje de aprobación: "
str_lit_123:    .asciz "%"
str_lit_124:    .asciz "  Progreso: "
str_lit_125:    .asciz "█"
str_lit_126:    .asciz "░"
str_lit_127:    .asciz "--- COMPARACIÓN INTER-FACULTADES ---"
dbl_lit_128:    .double 82.5
dbl_lit_129:    .double 88.3
dbl_lit_130:    .double 79.8
dbl_lit_131:    .double 0.0
str_lit_132:    .asciz "Facultad de "
str_lit_133:    .asciz "Mejor rendimiento: "
str_lit_134:    .asciz " con "
str_lit_135:    .asciz "--- DISTRIBUCIÓN DE LABORATORIOS ---"
str_lit_136:    .asciz "Lab-A"
str_lit_137:    .asciz "Lab-B"
str_lit_138:    .asciz "Lab-C"
str_lit_139:    .asciz "08:00"
str_lit_140:    .asciz "10:00"
str_lit_141:    .asciz "14:00"
str_lit_142:    .asciz "16:00"
str_lit_143:    .asciz "OCUPADO"
str_lit_144:    .asciz "LIBRE"
str_lit_145:    .asciz "=== FIN SISTEMA ESTUDIANTIL ==="

// --- Variables globales ---
g_totalEstudiantes:    .quad 1000
g_cuposPorCurso:    .quad 30
g_EDAD_MINIMA:    .quad 16
g_nombreEstudiante1:    .quad 0
g_edadEstudiante1:    .quad 20
g_cursosDisponibles:    .quad 5
g_cursoSeleccionado:    .quad 0
g_mensaje:    .quad 0
g_nombreEstudiante2:    .quad 0
g_edadEstudiante2:    .quad 16
g_cursoSeleccionado2:    .quad 0
g_mensaje2:    .quad 0
g_contador:    .quad 0
g_numeroEstudiante:    .quad 0
g_estudiante:    .quad 0
g_sumaNotas:    .quad 0
g_i:    .quad 0
g_numeroExamen:    .quad 0
g_promedio:    .quad 0
g_diaSemana:    .quad 2
g_mensaje3:    .quad 0
g_diaSemana2:    .quad 6
g_d:    .quad 0
g_numeroEstudianteStat:    .quad 1
g_variableGlobal:    .quad 100
g_presupuesto:    .quad 50000
g_capacidadAula:    .quad 30
g_equiposLab:    .quad 15
g_costoPorCredito:    .quad 150
g_semestre:    .quad 1
g_totalSemestre:    .quad 0
g_materia:    .quad 0
g_costoMateria:    .quad 0
g_est:    .quad 0
g_mat:    .quad 0
g_periodo:    .quad 0
g_porcentajeAprobacion:    .quad 0
g_barraCompleta:    .quad 0
g_barras:    .quad 0
g_barra:    .quad 0
g_mejorPromedio:    .quad 0
g_mejorFacultad:    .quad 0
g_f:    .quad 0
g_lab:    .quad 0
g_hora:    .quad 0
g_ocupado:    .quad 0
g_estado:    .quad 0
.data
