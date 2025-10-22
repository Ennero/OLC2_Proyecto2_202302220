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

fn_mostrarBienvenida:
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_27:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_mostrarMenuPrincipal:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_28:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_generarReporteFinal:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
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
L_func_exit_29:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_calcularPromedio:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str w0, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #48
    str w2, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #32
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub x16, x29, #64
    str w1, [x16]
    sub x16, x29, #64
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    ldr x16, =dbl_lit_12
    ldr d0, [x16]
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fdiv d0, d8, d9
    add sp, sp, #16
    b L_func_exit_30
L_func_exit_30:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_verificarAprobacion:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    str d1, [x16]
    sub x16, x29, #16
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #32
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    add sp, sp, #16
    fcmp d8, d9
    cset w1, ge
    mov w0, w1
    b L_func_exit_31
L_func_exit_31:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_generarMensaje:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    // String concatenation to tmpbuf
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_13
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #16
    ldr x1, [x16]
    ldr x1, [x1]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_14
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
    ldr x1, =tmpbuf
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #48
    str x1, [x16]
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #90
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    beq L_else_33
L_then_33:
    // String concatenation to tmpbuf
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #48
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_15
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =tmpbuf
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #48
    str x1, [x16]
    b L_end_33
L_else_33:
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #80
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, ge
    cmp w1, #0
    beq L_else_34
L_then_34:
    // String concatenation to tmpbuf
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #48
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_16
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =tmpbuf
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #48
    str x1, [x16]
    b L_end_34
L_else_34:
    // String concatenation to tmpbuf
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    sub x16, x29, #48
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_17
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =tmpbuf
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #48
    str x1, [x16]
L_end_34:
L_end_33:
    sub x16, x29, #48
    ldr x1, [x16]
    cbz x1, L_strret_null_35
    mov x0, x1
    bl strdup
    b L_strret_end_36
L_strret_null_35:
    mov x0, #0
L_strret_end_36:
    b L_func_exit_32
L_func_exit_32:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_calcularNotaFinal:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str w0, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #48
    str w2, [x16]
    sub sp, sp, #16
    sub x16, x29, #64
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #80
    str d1, [x16]
    sub sp, sp, #16
    sub x16, x29, #96
    str d2, [x16]
    sub sp, sp, #16
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #64
    ldr d0, [x16]
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #80
    ldr d0, [x16]
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    ldr d8, [sp]
    fmov d9, d0
    fadd d0, d8, d9
    add sp, sp, #16
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #48
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #96
    ldr d0, [x16]
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    ldr d8, [sp]
    fmov d9, d0
    fadd d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #112
    str d0, [x16]
    sub x16, x29, #112
    ldr d0, [x16]
    b L_func_exit_37
L_func_exit_37:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_busquedaBinaria:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #48
    str w2, [x16]
    sub sp, sp, #16
    sub x16, x29, #64
    str w3, [x16]
    sub x16, x29, #48
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #64
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, gt
    cmp w1, #0
    beq L_end_39
L_then_39:
    movz w1, #1
    neg w1, w1
    mov w0, w1
    b L_func_exit_38
L_end_39:
    sub sp, sp, #16
    sub x16, x29, #48
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #64
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #48
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #2
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w1, w19, w1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub x16, x29, #80
    str w1, [x16]
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
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #32
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    cmp w1, #0
    beq L_end_40
L_then_40:
    sub x16, x29, #80
    ldr w1, [x16]
    mov w0, w1
    b L_func_exit_38
L_end_40:
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
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #32
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, gt
    cmp w1, #0
    beq L_end_41
L_then_41:
    sub x16, x29, #16
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #32
    ldr w1, [x16]
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    str x1, [sp]
    sub x16, x29, #48
    ldr w1, [x16]
    mov w2, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w2, [sp]
    sub sp, sp, #16
    str x1, [sp]
    sub x16, x29, #80
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    mov w3, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w3, [sp]
    ldr w3, [sp]
    add sp, sp, #16
    ldr w2, [sp]
    add sp, sp, #16
    ldr w1, [sp]
    add sp, sp, #16
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_busquedaBinaria
    mov w1, w0
    mov w0, w1
    b L_func_exit_38
L_end_41:
    sub x16, x29, #16
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #32
    ldr w1, [x16]
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    str x1, [sp]
    sub x16, x29, #80
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    mov w2, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w2, [sp]
    sub sp, sp, #16
    str x1, [sp]
    sub x16, x29, #64
    ldr w1, [x16]
    mov w3, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w3, [sp]
    ldr w3, [sp]
    add sp, sp, #16
    ldr w2, [sp]
    add sp, sp, #16
    ldr w1, [sp]
    add sp, sp, #16
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_busquedaBinaria
    mov w1, w0
    mov w0, w1
    b L_func_exit_38
L_func_exit_38:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_sumarDigitos:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str w0, [x16]
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #0
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    cmp w1, #0
    beq L_end_43
L_then_43:
    movz w1, #0
    mov w0, w1
    b L_func_exit_42
L_end_43:
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #10
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w21, w19, w1
    msub w1, w21, w1, w19
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #10
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w1, w19, w1
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_sumarDigitos
    mov w1, w0
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    mov w0, w1
    b L_func_exit_42
L_func_exit_42:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_potencia:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str w0, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    str w1, [x16]
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #0
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    cmp w1, #0
    beq L_end_45
L_then_45:
    movz w1, #1
    mov w0, w1
    b L_func_exit_44
L_end_45:
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    cmp w1, #0
    beq L_end_46
L_then_46:
    sub x16, x29, #16
    ldr w1, [x16]
    mov w0, w1
    b L_func_exit_44
L_end_46:
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #16
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #1
    ldr w19, [sp]
    add sp, sp, #16
    sub w1, w19, w1
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    ldr w1, [sp]
    add sp, sp, #16
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_potencia
    mov w1, w0
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    mov w0, w1
    b L_func_exit_44
L_func_exit_44:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_esPalindromo:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str w0, [x16]
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #16
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    movz w1, #0
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    ldr w1, [sp]
    add sp, sp, #16
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_invertirNumero
    mov w1, w0
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    mov w0, w1
    b L_func_exit_47
L_func_exit_47:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_invertirNumero:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    sub sp, sp, #1024
    sub sp, sp, #16
    sub x16, x29, #16
    str w0, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    str w1, [x16]
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #0
    ldr w19, [sp]
    add sp, sp, #16
    cmp w19, w1
    cset w1, eq
    cmp w1, #0
    beq L_end_49
L_then_49:
    sub x16, x29, #32
    ldr w1, [x16]
    mov w0, w1
    b L_func_exit_48
L_end_49:
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #10
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w1, w19, w1
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #10
    ldr w19, [sp]
    add sp, sp, #16
    mul w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #16
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    movz w1, #10
    ldr w19, [sp]
    add sp, sp, #16
    sdiv w21, w19, w1
    msub w1, w21, w1, w19
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    ldr w1, [sp]
    add sp, sp, #16
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_invertirNumero
    mov w1, w0
    mov w0, w1
    b L_func_exit_48
L_func_exit_48:
    add sp, sp, #1024
    mov sp, x29
    ldp x29, x30, [sp], 16
    ret

fn_sumarCalificaciones:
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
    sub x16, x29, #16
    ldr x9, [x16]
    sub sp, sp, #16
    sub sp, sp, #16
    mov w20, #0
    sub x16, x29, #64
    str w20, [x16]
L_for_cond_51:
    // ForEach: recomputar base de datos y longitud
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
    sub x16, x29, #64
    ldr w20, [x16]
    cmp w20, w19
    b.ge L_break_51
    add x22, x21, x20, lsl #2
    ldr w1, [x22]
    sub x16, x29, #48
    str w1, [x16]
    sub x16, x29, #64
    str w20, [x16]
    sub x16, x29, #32
    ldr w19, [x16]
    sub x16, x29, #48
    ldr w1, [x16]
    add w1, w19, w1
    sub x16, x29, #32
    str w1, [x16]
L_continue_51:
    sub x16, x29, #64
    ldr w20, [x16]
    add w20, w20, #1
    sub x16, x29, #64
    str w20, [x16]
    b L_for_cond_51
L_break_51:
    sub x16, x29, #32
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #16
    ldr x0, [x16]
    // load sizes[0] from header: [x0+8]
    add x18, x0, #8
    ldr w1, [x18]
    scvtf d0, w1
    ldr w19, [sp]
    scvtf d8, w19
    fmov d9, d0
    fdiv d0, d8, d9
    add sp, sp, #16
    b L_func_exit_50
L_func_exit_50:
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
    ldr x1, =str_lit_18
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    bl fn_mostrarBienvenida
    mov w1, w0
    bl fn_mostrarMenuPrincipal
    mov w1, w0
    sub sp, sp, #16
    movz w1, #85
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    movz w1, #92
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    str x1, [sp]
    movz w1, #78
    mov w2, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w2, [sp]
    ldr w2, [sp]
    add sp, sp, #16
    ldr w1, [sp]
    add sp, sp, #16
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_calcularPromedio
    sub x16, x29, #16
    str d0, [x16]
    sub sp, sp, #16
    movz w1, #90
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    movz w1, #88
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    str x1, [sp]
    movz w1, #94
    mov w2, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w2, [sp]
    ldr w2, [sp]
    add sp, sp, #16
    ldr w1, [sp]
    add sp, sp, #16
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_calcularPromedio
    sub x16, x29, #32
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_19
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #16
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
    sub x16, x29, #32
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
    sub sp, sp, #16
    sub x16, x29, #16
    ldr d0, [x16]
    fmov d0, d0
    sub sp, sp, #16
    str d0, [sp]
    sub sp, sp, #16
    str d0, [sp]
    ldr x16, =dbl_lit_21
    ldr d0, [x16]
    fmov d1, d0
    ldr d0, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str d1, [sp]
    ldr d1, [sp]
    add sp, sp, #16
    ldr d0, [sp]
    add sp, sp, #16
    bl fn_verificarAprobacion
    mov w1, w0
    sub x16, x29, #48
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #32
    ldr d0, [x16]
    fmov d0, d0
    sub sp, sp, #16
    str d0, [sp]
    sub sp, sp, #16
    str d0, [sp]
    ldr x16, =dbl_lit_22
    ldr d0, [x16]
    fmov d1, d0
    ldr d0, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str d1, [sp]
    ldr d1, [sp]
    add sp, sp, #16
    ldr d0, [sp]
    add sp, sp, #16
    bl fn_verificarAprobacion
    mov w1, w0
    sub x16, x29, #64
    str w1, [x16]
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
    sub x16, x29, #48
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
    ldr x1, =str_lit_2
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
    sub x16, x29, #64
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
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_25
    mov x0, x1
    bl strdup
    mov x1, x0
    sub sp, sp, #16
    str x1, [sp]
    mov x0, sp
    movz w1, #95
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    ldr w1, [sp]
    add sp, sp, #16
    add x0, sp, #0
    bl fn_generarMensaje
    add sp, sp, #16
    mov x1, x0
    sub x16, x29, #80
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Identificador
    sub x16, x29, #80
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =str_lit_26
    csel x1, x16, x1, eq
    ldr x0, =fmt_string
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #85
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    movz w1, #90
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    str x1, [sp]
    movz w1, #88
    mov w2, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w2, [sp]
    ldr x16, =dbl_lit_27
    ldr d0, [x16]
    fmov d0, d0
    sub sp, sp, #16
    str d0, [sp]
    sub sp, sp, #16
    str d0, [sp]
    ldr x16, =dbl_lit_28
    ldr d0, [x16]
    fmov d1, d0
    ldr d0, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str d1, [sp]
    sub sp, sp, #16
    str d0, [sp]
    ldr x16, =dbl_lit_29
    ldr d0, [x16]
    fmov d2, d0
    ldr d0, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str d2, [sp]
    ldr d2, [sp]
    add sp, sp, #16
    ldr d1, [sp]
    add sp, sp, #16
    ldr d0, [sp]
    add sp, sp, #16
    ldr w2, [sp]
    add sp, sp, #16
    ldr w1, [sp]
    add sp, sp, #16
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_calcularNotaFinal
    sub x16, x29, #96
    str d0, [x16]
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
    sub x16, x29, #96
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_31
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #16
    mov w1, #10
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
    movz w1, #12
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #23
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #34
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    movz w1, #45
    str w1, [x22, x23, lsl #2]
    mov x23, #5
    movz w1, #56
    str w1, [x22, x23, lsl #2]
    mov x23, #6
    movz w1, #67
    str w1, [x22, x23, lsl #2]
    mov x23, #7
    movz w1, #78
    str w1, [x22, x23, lsl #2]
    mov x23, #8
    movz w1, #89
    str w1, [x22, x23, lsl #2]
    mov x23, #9
    movz w1, #90
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #112
    str x0, [x16]
    sub sp, sp, #16
    movz w1, #45
    sub x16, x29, #128
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #112
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #128
    ldr w1, [x16]
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    str x1, [sp]
    movz w1, #0
    mov w2, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w2, [sp]
    sub sp, sp, #16
    str x1, [sp]
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
    mov w3, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w3, [sp]
    ldr w3, [sp]
    add sp, sp, #16
    ldr w2, [sp]
    add sp, sp, #16
    ldr w1, [sp]
    add sp, sp, #16
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_busquedaBinaria
    mov w1, w0
    sub x16, x29, #144
    str w1, [x16]
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
    sub x16, x29, #128
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
    ldr x1, =str_lit_33
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #144
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
    movz w1, #23
    sub x16, x29, #128
    str w1, [x16]
    sub x16, x29, #112
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #128
    ldr w1, [x16]
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    str x1, [sp]
    movz w1, #0
    mov w2, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w2, [sp]
    sub sp, sp, #16
    str x1, [sp]
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
    mov w3, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w3, [sp]
    ldr w3, [sp]
    add sp, sp, #16
    ldr w2, [sp]
    add sp, sp, #16
    ldr w1, [sp]
    add sp, sp, #16
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_busquedaBinaria
    mov w1, w0
    sub x16, x29, #112
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    sub x16, x29, #128
    ldr w1, [x16]
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    sub sp, sp, #16
    str x1, [sp]
    movz w1, #0
    mov w2, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w2, [sp]
    sub sp, sp, #16
    str x1, [sp]
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
    mov w3, w1
    ldr x1, [sp]
    add sp, sp, #16
    sub sp, sp, #16
    str w3, [sp]
    ldr w3, [sp]
    add sp, sp, #16
    ldr w2, [sp]
    add sp, sp, #16
    ldr w1, [sp]
    add sp, sp, #16
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_busquedaBinaria
    mov w1, w0
    sub x16, x29, #144
    str w1, [x16]
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
    sub x16, x29, #128
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
    ldr x1, =str_lit_33
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #144
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
    movz w1, #12345
    sub x16, x29, #160
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #160
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_sumarDigitos
    mov w1, w0
    sub x16, x29, #176
    str w1, [x16]
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
    ldr x1, =str_lit_35
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
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    movz w1, #9876
    sub x16, x29, #160
    str w1, [x16]
    sub x16, x29, #160
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_sumarDigitos
    mov w1, w0
    sub x16, x29, #160
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_sumarDigitos
    mov w1, w0
    sub x16, x29, #176
    str w1, [x16]
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
    ldr x1, =str_lit_35
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
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #2
    sub x16, x29, #192
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #8
    sub x16, x29, #208
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #192
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    sub x16, x29, #208
    ldr w1, [x16]
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    ldr w1, [sp]
    add sp, sp, #16
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_potencia
    mov w1, w0
    sub x16, x29, #224
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
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
    ldr x1, =str_lit_36
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #208
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
    ldr x1, =str_lit_37
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
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    movz w1, #3
    sub x16, x29, #192
    str w1, [x16]
    movz w1, #4
    sub x16, x29, #208
    str w1, [x16]
    sub x16, x29, #192
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    sub x16, x29, #208
    ldr w1, [x16]
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    ldr w1, [sp]
    add sp, sp, #16
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_potencia
    mov w1, w0
    sub x16, x29, #192
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    sub x16, x29, #208
    ldr w1, [x16]
    mov w1, w1
    sub sp, sp, #16
    str w1, [sp]
    ldr w1, [sp]
    add sp, sp, #16
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_potencia
    mov w1, w0
    sub x16, x29, #224
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
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
    ldr x1, =str_lit_36
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #208
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
    ldr x1, =str_lit_37
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
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #121
    sub x16, x29, #240
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #240
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_esPalindromo
    mov w1, w0
    sub x16, x29, #256
    str w1, [x16]
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
    ldr x1, =str_lit_39
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #256
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
    ldr x1, =str_lit_2
    bl printf
    movz w1, #123
    sub x16, x29, #240
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #240
    ldr w1, [x16]
    mov w0, w1
    sub sp, sp, #16
    str w0, [sp]
    ldr w0, [sp]
    add sp, sp, #16
    bl fn_esPalindromo
    mov w1, w0
    sub x16, x29, #272
    str w1, [x16]
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
    ldr x1, =str_lit_39
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #272
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
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_40
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_41
    sub x16, x29, #288
    str x1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_42
    sub x16, x29, #304
    str x1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_43
    sub x16, x29, #320
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #288
    ldr x1, [x16]
    mov x0, x1
    mov x1, #0
    mov w2, #10
    bl strtol
    mov w1, w0
    sub x16, x29, #336
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #304
    ldr x1, [x16]
    mov x0, x1
    mov x1, #0
    mov w2, #10
    bl strtol
    mov w1, w0
    sub x16, x29, #352
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #320
    ldr x1, [x16]
    mov x0, x1
    mov x1, #0
    mov w2, #10
    bl strtol
    mov w1, w0
    sub x16, x29, #368
    str w1, [x16]
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
    sub x16, x29, #288
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_45
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
    sub x16, x29, #304
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_45
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #352
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
    ldr x1, =str_lit_44
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #320
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_45
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
    ldr x0, =fmt_string
    ldr x1, =tmpbuf
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub x16, x29, #336
    ldr w1, [x16]
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #352
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub sp, sp, #16
    str w1, [sp]
    sub x16, x29, #368
    ldr w1, [x16]
    ldr w19, [sp]
    add sp, sp, #16
    add w1, w19, w1
    sub x16, x29, #384
    str w1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_46
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #384
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
    ldr x1, =str_lit_47
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    ldr x1, =str_lit_48
    sub x16, x29, #400
    str x1, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_49
    sub x16, x29, #416
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #400
    ldr x1, [x16]
    mov x0, x1
    mov x1, #0
    bl strtod
    sub x16, x29, #432
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #416
    ldr x1, [x16]
    mov x0, x1
    mov x1, #0
    bl strtod
    sub x16, x29, #448
    str d0, [x16]
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
    sub x16, x29, #400
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_50
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #432
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
    sub x16, x29, #416
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_50
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #448
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
    sub sp, sp, #16
    sub x16, x29, #432
    ldr d0, [x16]
    sub sp, sp, #16
    str d0, [sp]
    sub x16, x29, #448
    ldr d0, [x16]
    ldr d8, [sp]
    fmov d9, d0
    fmul d0, d8, d9
    add sp, sp, #16
    sub x16, x29, #464
    str d0, [x16]
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
    sub x16, x29, #464
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
    sub sp, sp, #16
    ldr x1, =str_lit_52
    sub x16, x29, #480
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #480
    ldr x1, [x16]
    mov x0, x1
    mov x1, #0
    bl strtof
    fcvt d0, s0
    sub x16, x29, #496
    str d0, [x16]
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
    sub x16, x29, #480
    ldr x1, [x16]
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    ldr x1, =str_lit_53
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #496
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
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_54
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    movz w1, #42
    sub x16, x29, #512
    str w1, [x16]
    sub sp, sp, #16
    ldr x16, =dbl_lit_55
    ldr d0, [x16]
    sub x16, x29, #528
    str d0, [x16]
    sub sp, sp, #16
    mov w1, #1
    sub x16, x29, #544
    str w1, [x16]
    sub sp, sp, #16
    movz w1, #65
    sub x16, x29, #560
    str w1, [x16]
    sub sp, sp, #16
    sub x16, x29, #512
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
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #576
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #528
    ldr d0, [x16]
    sub sp, sp, #128
    mov x0, sp
    mov x1, #128
    bl java_format_double
    mov x0, sp
    bl strdup
    add sp, sp, #128
    mov x1, x0
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #592
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #544
    ldr w1, [x16]
    cmp w1, #0
    ldr x1, =false_str
    ldr x16, =true_str
    csel x1, x16, x1, ne
    mov x0, x1
    bl strdup
    mov x1, x0
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #608
    str x1, [x16]
    sub sp, sp, #16
    sub x16, x29, #560
    ldr w1, [x16]
    mov w21, w1
    mov w0, w21
    bl char_to_utf8
    mov x0, x0
    bl strdup
    mov x1, x0
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #624
    str x1, [x16]
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
    sub x16, x29, #512
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
    ldr x1, =str_lit_57
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #576
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
    sub x16, x29, #528
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
    ldr x1, =str_lit_57
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #592
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
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_59
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #544
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
    ldr x1, =str_lit_57
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #608
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
    sub x16, x29, #560
    ldr w1, [x16]
    mov w21, w1
    mov w0, w21
    bl char_to_utf8
    mov x0, x0
    bl strdup
    mov x1, x0
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
    sub x16, x29, #624
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
    ldr x1, =str_lit_62
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_63
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_64
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    // print int
    ldr x0, =fmt_int
    mov w1, #123
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    // print double
    ldr x0, =fmt_double
    ldr x16, =dbl_lit_65
    ldr d0, [x16]
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    // print boolean
    ldr x0, =fmt_string
    ldr x1, =true_str
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    // print char
    ldr x0, =fmt_char
    mov w1, #88
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_66
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
    ldr x1, =str_lit_67
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_68
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_69
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_70
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #640
    str x0, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_71
    mov x23, x1
    sub x16, x29, #640
    ldr x0, [x16]
    mov x1, x23
    bl join_array_strings
    bl strdup
    mov x1, x0
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #656
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_72
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
    ldr x1, =str_lit_73
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_74
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_75
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #672
    str x0, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_76
    mov x23, x1
    sub x16, x29, #672
    ldr x0, [x16]
    mov x1, x23
    bl join_array_strings
    bl strdup
    mov x1, x0
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #688
    str x1, [x16]
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
    sub x16, x29, #688
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
    ldr x1, =str_lit_78
    str x1, [x22, x23, lsl #3]
    mov x23, #1
    ldr x1, =str_lit_79
    str x1, [x22, x23, lsl #3]
    mov x23, #2
    ldr x1, =str_lit_80
    str x1, [x22, x23, lsl #3]
    mov x23, #3
    ldr x1, =str_lit_81
    str x1, [x22, x23, lsl #3]
    add sp, sp, #16
    sub x16, x29, #704
    str x0, [x16]
    sub sp, sp, #16
    ldr x1, =str_lit_82
    mov x23, x1
    sub x16, x29, #704
    ldr x0, [x16]
    mov x1, x23
    bl join_array_strings
    bl strdup
    mov x1, x0
    mov x0, x1
    bl strdup
    mov x1, x0
    sub x16, x29, #720
    str x1, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_83
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #720
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
    ldr x1, =str_lit_84
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
    movz w1, #85
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #90
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #88
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #92
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    movz w1, #87
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #736
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
    movz w1, #78
    str w1, [x22, x23, lsl #2]
    mov x23, #1
    movz w1, #82
    str w1, [x22, x23, lsl #2]
    mov x23, #2
    movz w1, #85
    str w1, [x22, x23, lsl #2]
    mov x23, #3
    movz w1, #80
    str w1, [x22, x23, lsl #2]
    mov x23, #4
    movz w1, #84
    str w1, [x22, x23, lsl #2]
    add sp, sp, #16
    sub x16, x29, #752
    str x0, [x16]
    sub sp, sp, #16
    sub x16, x29, #736
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_sumarCalificaciones
    sub x16, x29, #768
    str d0, [x16]
    sub sp, sp, #16
    sub x16, x29, #752
    ldr x1, [x16]
    mov x0, x1
    sub sp, sp, #16
    str x0, [sp]
    ldr x0, [sp]
    add sp, sp, #16
    bl fn_sumarCalificaciones
    sub x16, x29, #784
    str d0, [x16]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Suma
    // String concatenation to tmpbuf (print)
    ldr x0, =tmpbuf
    mov w2, #0
    strb w2, [x0]
    ldr x1, =str_lit_19
    cmp x1, #0
    ldr x16, =null_str
    csel x1, x16, x1, eq
    ldr x0, =tmpbuf
    bl strcat
    sub x16, x29, #768
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
    sub x16, x29, #784
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
    bl fn_generarReporteFinal
    mov w1, w0
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_85
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
L_func_exit_52:
    add sp, sp, #1024
    mov sp, x29

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "\n¡Bienvenido al Sistema de Gestión Académica!"
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "Versión 1.0 - Universidad San Carlos"
str_lit_4:    .asciz "\nOpciones disponibles:"
str_lit_5:    .asciz "1. Gestión de estudiantes"
str_lit_6:    .asciz "2. Cálculo de promedios"
str_lit_7:    .asciz "3. Reportes académicos"
str_lit_8:    .asciz "4. Análisis estadístico"
str_lit_9:    .asciz "\n--- REPORTE FINAL GENERADO ---"
str_lit_10:    .asciz "Todas las funciones han sido probadas exitosamente"
str_lit_11:    .asciz "Sistema verificado y operativo"
dbl_lit_12:    .double 3.0
str_lit_13:    .asciz "Estudiante: "
str_lit_14:    .asciz " - Calificación: "
str_lit_15:    .asciz " - EXCELENTE"
str_lit_16:    .asciz " - MUY BUENO"
str_lit_17:    .asciz " - REGULAR"
str_lit_18:    .asciz "=== SISTEMA DE GESTION ACADEMICA ==="
str_lit_19:    .asciz "Promedio estudiante 1: "
str_lit_20:    .asciz "Promedio estudiante 2: "
dbl_lit_21:    .double 80.0
dbl_lit_22:    .double 80.0
str_lit_23:    .asciz "Estudiante 1 aprobado: "
str_lit_24:    .asciz "Estudiante 2 aprobado: "
str_lit_25:    .asciz "Carlos Pérez"
str_lit_26:    .asciz "null"
dbl_lit_27:    .double 0.3
dbl_lit_28:    .double 0.4
dbl_lit_29:    .double 0.3
str_lit_30:    .asciz "Nota final ponderada: "
str_lit_31:    .asciz "\n--- FUNCIONES RECURSIVAS ---"
str_lit_32:    .asciz "Búsqueda binaria de "
str_lit_33:    .asciz ": posición "
str_lit_34:    .asciz "Suma de dígitos de "
str_lit_35:    .asciz ": "
str_lit_36:    .asciz " elevado a "
str_lit_37:    .asciz " = "
str_lit_38:    .asciz "El número "
str_lit_39:    .asciz " es palíndromo: "
str_lit_40:    .asciz "\n--- PARSEO DE ENTEROS ---"
str_lit_41:    .asciz "123"
str_lit_42:    .asciz "456"
str_lit_43:    .asciz "789"
str_lit_44:    .asciz "Parseando '"
str_lit_45:    .asciz "' a entero: "
str_lit_46:    .asciz "Suma de números parseados: "
str_lit_47:    .asciz "\n--- PARSEO DE FLOTANTES ---"
str_lit_48:    .asciz "3.14159"
str_lit_49:    .asciz "2.71828"
str_lit_50:    .asciz "' a double: "
str_lit_51:    .asciz "Producto PI * E: "
str_lit_52:    .asciz "45.67"
str_lit_53:    .asciz "' a float: "
str_lit_54:    .asciz "\n--- CONVERSIONES CON String.valueOf ---"
dbl_lit_55:    .double 3.14159
str_lit_56:    .asciz "int "
str_lit_57:    .asciz " como String: "
str_lit_58:    .asciz "double "
str_lit_59:    .asciz "boolean "
str_lit_60:    .asciz "char '"
str_lit_61:    .asciz "' como String: "
str_lit_62:    .asciz "\n--- DEMOSTRACION System.out.println ---"
str_lit_63:    .asciz "Esta función se ha usado extensivamente en todo el programa"
str_lit_64:    .asciz "Imprime diferentes tipos de datos:"
dbl_lit_65:    .double 45.67
str_lit_66:    .asciz "\n--- UNIR CADENAS CON Strings.join ---"
str_lit_67:    .asciz "Ana"
str_lit_68:    .asciz "Luis"
str_lit_69:    .asciz "Maria"
str_lit_70:    .asciz "Carlos"
str_lit_71:    .asciz ", "
str_lit_72:    .asciz "Lista de estudiantes: "
str_lit_73:    .asciz "Matematicas"
str_lit_74:    .asciz "Fisica"
str_lit_75:    .asciz "Quimica"
str_lit_76:    .asciz " | "
str_lit_77:    .asciz "Materias disponibles: "
str_lit_78:    .asciz "85"
str_lit_79:    .asciz "92"
str_lit_80:    .asciz "78"
str_lit_81:    .asciz "95"
str_lit_82:    .asciz " - "
str_lit_83:    .asciz "Reporte de calificaciones: "
str_lit_84:    .asciz "\n--- FUNCION: sumarCalificaciones ---"
str_lit_85:    .asciz "\n=== SISTEMA COMPLETADO ==="

// --- Variables globales ---
g_suma:    .quad 0
g_resultado:    .quad 0
g_notaPonderada:    .quad 0
g_medio:    .quad 0
g_promedio1:    .quad 0
g_promedio2:    .quad 0
g_esAprobado1:    .quad 0
g_esAprobado2:    .quad 0
g_mensaje:    .quad 0
g_notaFinal:    .quad 0
g_valorBuscado:    .quad 45
g_posicionEncontrada:    .quad 0
g_numero:    .quad 12345
g_sumaDigitos:    .quad 0
g_base:    .quad 2
g_exponente:    .quad 8
g_resultadoPotencia:    .quad 0
g_numeroPalindromo:    .quad 121
g_esPalindromo1:    .quad 0
g_esPalindromo2:    .quad 0
g_numeroTexto1:    .quad 0
g_numeroTexto2:    .quad 0
g_numeroTexto3:    .quad 0
g_num1:    .quad 0
g_num2:    .quad 0
g_num3:    .quad 0
g_decimal1:    .quad 0
g_decimal2:    .quad 0
g_pi:    .quad 0
g_e:    .quad 0
g_producto:    .quad 0
g_flotanteTexto:    .quad 0
g_numeroFloat:    .quad 0
g_entero:    .quad 42
g_decimal:    .quad 0
g_verdadero:    .quad 1
g_caracter:    .quad 65
g_strEntero:    .quad 0
g_strDecimal:    .quad 0
g_strBoolean:    .quad 0
g_strChar:    .quad 0
g_listaEstudiantes:    .quad 0
g_listaMaterias:    .quad 0
g_reporteCalificaciones:    .quad 0
g_promedioEst1:    .quad 0
g_promedioEst2:    .quad 0
.data
