.data

// Cadenas de formato para printf (sin salto de línea) 
fmt_int:        .asciz "%d"
fmt_double:     .asciz "%f"
fmt_string:     .asciz "%s"
fmt_char:       .asciz "%c"

true_str:       .asciz "true"
false_str:      .asciz "false"

tmpbuf:         .skip 1024

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

main:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_1
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_2
    bl printf
    sub sp, sp, #16
    sub sp, sp, #48
    mov w1, #1
    str w1, [sp, #0]
    mov w1, #1
    str w1, [sp, #4]
    mov w1, #1
    str w1, [sp, #8]
    mov w1, #1
    str w1, [sp, #12]
    mov w1, #1
    str w1, [sp, #16]
    mov w1, #1
    str w1, [sp, #20]
    mov w1, #1
    str w1, [sp, #24]
    mov w1, #1
    str w1, [sp, #28]
    mov w1, #1
    str w1, [sp, #32]
    mov w1, #1
    str w1, [sp, #36]
    mov w0, #10
    mov x1, sp
    bl new_array_flat
    str x0, [x29, -16]
    add sp, sp, #48
    sub sp, sp, #48
    mov w1, #0
    str w1, [sp, #0]
    mov w1, #0
    str w1, [sp, #4]
    mov w1, #0
    str w1, [sp, #8]
    mov w1, #0
    str w1, [sp, #12]
    mov w1, #0
    str w1, [sp, #16]
    mov w1, #0
    str w1, [sp, #20]
    mov w1, #0
    str w1, [sp, #24]
    mov w1, #0
    str w1, [sp, #28]
    mov w1, #0
    str w1, [sp, #32]
    mov w1, #0
    str w1, [sp, #36]
    ldr x0, [x29, -16]
    mov x1, sp
    mov w2, #10
    bl array_element_addr
    mov w1, #10
    str w1, [x0]
    add sp, sp, #48
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: ArrayAccess
    sub sp, sp, #48
    mov w1, #0
    str w1, [sp, #0]
    mov w1, #0
    str w1, [sp, #4]
    mov w1, #0
    str w1, [sp, #8]
    mov w1, #0
    str w1, [sp, #12]
    mov w1, #0
    str w1, [sp, #16]
    mov w1, #0
    str w1, [sp, #20]
    mov w1, #0
    str w1, [sp, #24]
    mov w1, #0
    str w1, [sp, #28]
    mov w1, #0
    str w1, [sp, #32]
    mov w1, #0
    str w1, [sp, #36]
    ldr x0, [x29, -16]
    mov x1, sp
    mov w2, #10
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #48
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_3
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_4
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_5
    bl printf
    sub sp, sp, #16
    sub sp, sp, #80
    mov w1, #1
    str w1, [sp, #0]
    mov w1, #1
    str w1, [sp, #4]
    mov w1, #1
    str w1, [sp, #8]
    mov w1, #1
    str w1, [sp, #12]
    mov w1, #1
    str w1, [sp, #16]
    mov w1, #1
    str w1, [sp, #20]
    mov w1, #1
    str w1, [sp, #24]
    mov w1, #1
    str w1, [sp, #28]
    mov w1, #1
    str w1, [sp, #32]
    mov w1, #1
    str w1, [sp, #36]
    mov w1, #1
    str w1, [sp, #40]
    mov w1, #1
    str w1, [sp, #44]
    mov w1, #1
    str w1, [sp, #48]
    mov w1, #1
    str w1, [sp, #52]
    mov w1, #1
    str w1, [sp, #56]
    mov w1, #1
    str w1, [sp, #60]
    mov w1, #1
    str w1, [sp, #64]
    mov w1, #1
    str w1, [sp, #68]
    mov w1, #1
    str w1, [sp, #72]
    mov w1, #1
    str w1, [sp, #76]
    mov w0, #20
    mov x1, sp
    bl new_array_flat
    str x0, [x29, -32]
    add sp, sp, #80
    sub sp, sp, #80
    mov w1, #0
    str w1, [sp, #0]
    mov w1, #0
    str w1, [sp, #4]
    mov w1, #0
    str w1, [sp, #8]
    mov w1, #0
    str w1, [sp, #12]
    mov w1, #0
    str w1, [sp, #16]
    mov w1, #0
    str w1, [sp, #20]
    mov w1, #0
    str w1, [sp, #24]
    mov w1, #0
    str w1, [sp, #28]
    mov w1, #0
    str w1, [sp, #32]
    mov w1, #0
    str w1, [sp, #36]
    mov w1, #0
    str w1, [sp, #40]
    mov w1, #0
    str w1, [sp, #44]
    mov w1, #0
    str w1, [sp, #48]
    mov w1, #0
    str w1, [sp, #52]
    mov w1, #0
    str w1, [sp, #56]
    mov w1, #0
    str w1, [sp, #60]
    mov w1, #0
    str w1, [sp, #64]
    mov w1, #0
    str w1, [sp, #68]
    mov w1, #0
    str w1, [sp, #72]
    mov w1, #0
    str w1, [sp, #76]
    ldr x0, [x29, -32]
    mov x1, sp
    mov w2, #20
    bl array_element_addr
    mov w1, #20
    str w1, [x0]
    add sp, sp, #80
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: ArrayAccess
    sub sp, sp, #80
    mov w1, #0
    str w1, [sp, #0]
    mov w1, #0
    str w1, [sp, #4]
    mov w1, #0
    str w1, [sp, #8]
    mov w1, #0
    str w1, [sp, #12]
    mov w1, #0
    str w1, [sp, #16]
    mov w1, #0
    str w1, [sp, #20]
    mov w1, #0
    str w1, [sp, #24]
    mov w1, #0
    str w1, [sp, #28]
    mov w1, #0
    str w1, [sp, #32]
    mov w1, #0
    str w1, [sp, #36]
    mov w1, #0
    str w1, [sp, #40]
    mov w1, #0
    str w1, [sp, #44]
    mov w1, #0
    str w1, [sp, #48]
    mov w1, #0
    str w1, [sp, #52]
    mov w1, #0
    str w1, [sp, #56]
    mov w1, #0
    str w1, [sp, #60]
    mov w1, #0
    str w1, [sp, #64]
    mov w1, #0
    str w1, [sp, #68]
    mov w1, #0
    str w1, [sp, #72]
    mov w1, #0
    str w1, [sp, #76]
    ldr x0, [x29, -32]
    mov x1, sp
    mov w2, #20
    bl array_element_addr
    ldr w1, [x0]
    add sp, sp, #80
    ldr x0, =fmt_int
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_6
    bl printf
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_7
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_8
    bl printf
    sub sp, sp, #16
    mov x1, #0
    str x1, [x29, -48]
    // Print lista node_type: ListaExpresiones, numHijos=1
    // print expr node_type: Primitivo
    ldr x0, =fmt_string
    ldr x1, =str_lit_9
    bl printf
    ldr x0, =fmt_string
    ldr x1, =str_lit_10
    bl printf
    add sp, sp, #48
L_func_exit_1:

    mov w0, #0
    ldp x29, x30, [sp], 16
    ret

// --- Literales recolectados ---
.data
str_lit_1:    .asciz "--- Prueba de Arreglo de 10 Dimensiones ---"
str_lit_2:    .asciz "\n"
str_lit_3:    .asciz "\n"
str_lit_4:    .asciz "\n--- Prueba de Arreglo de 20 Dimensiones ---"
str_lit_5:    .asciz "\n"
str_lit_6:    .asciz "\n"
str_lit_7:    .asciz "\n--- Prueba de Declaración de 101 Dimensiones ---"
str_lit_8:    .asciz "\n"
str_lit_9:    .asciz "Declaracion de arreglo de 101 dimensiones exitosa."
str_lit_10:    .asciz "\n"
