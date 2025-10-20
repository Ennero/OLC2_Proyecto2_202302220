#include "codegen/estructuras/arm64_arreglos.h"
#include <string.h>
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_num.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"

static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }

// Registro simple para variables arreglo -> tipo base
typedef struct ArrReg { const char *name; TipoDato base; struct ArrReg *next; } ArrReg;
static ArrReg *g_arrs = NULL;
void arm64_registrar_arreglo(const char *name, TipoDato base_tipo) {
    ArrReg *n = (ArrReg*)malloc(sizeof(ArrReg));
    n->name = name; n->base = base_tipo; n->next = g_arrs; g_arrs = n;
}
static TipoDato find_arr_base(const char *name) {
    for (ArrReg *p = g_arrs; p; p = p->next) if (strcmp(p->name, name) == 0) return p->base; return INT;
}
int arm64_array_elem_size_for_var(const char *name) {
    TipoDato t = find_arr_base(name);
    return (t == STRING) ? 8 : 4;
}
TipoDato arm64_array_elem_tipo_for_var(const char *name) { return find_arr_base(name); }

int arm64_emitir_asignacion_arreglo(AbstractExpresion *node, FILE *ftext) {
    if (!(node && node->node_type && strcmp(node->node_type, "ArrayAssignment") == 0)) return 0;
    AbstractExpresion *acceso = node->hijos[0];
    AbstractExpresion *rhs = node->hijos[1];
    int depth = 0; AbstractExpresion *it = acceso;
    while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0) { depth++; it = it->hijos[0]; }
    if (!(it && it->node_type && strcmp(it->node_type, "Identificador") == 0)) {
        emitln(ftext, "    // ArrayAssignment base no soportada en codegen");
        return 1;
    }
    IdentificadorExpresion *id = (IdentificadorExpresion *)it;
    VarEntry *v = buscar_variable(id->nombre);
    if (!v) return 1;
    int bytes = ((depth * 4) + 15) & ~15;
    if (bytes > 0) { char sub[64]; snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes); emitln(ftext, sub); }
    it = acceso; for (int i = 0; i < depth; ++i) {
        AbstractExpresion *idx = it->hijos[1];
        TipoDato ty = emitir_eval_numerico(idx, ftext);
        if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
        char st[64]; snprintf(st, sizeof(st), "    str w1, [sp, #%d]", i * 4); emitln(ftext, st);
        it = it->hijos[0];
    }
    {
        char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", v->offset); emitln(ftext, ld);
    }
    emitln(ftext, "    mov x1, sp");
    { char mv[64]; snprintf(mv, sizeof(mv), "    mov w2, #%d", depth); emitln(ftext, mv); }
    // Elegir helper según tipo base del arreglo
    TipoDato base_t = arm64_array_elem_tipo_for_var(id->nombre);
    if (base_t == STRING) emitln(ftext, "    bl array_element_addr_ptr");
    else emitln(ftext, "    bl array_element_addr");
    // Guardar la dirección destino (x0) en la pila para no perderla durante la evaluación del RHS
    emitln(ftext, "    sub sp, sp, #16");
    emitln(ftext, "    str x0, [sp]");
    TipoDato rty = emitir_eval_numerico(rhs, ftext);
    if (base_t == STRING) {
        if (!emitir_eval_string_ptr(rhs, ftext)) emitln(ftext, "    mov x1, #0");
        // Restaurar dirección y almacenar
        emitln(ftext, "    ldr x9, [sp]");
        emitln(ftext, "    add sp, sp, #16");
        emitln(ftext, "    str x1, [x9]");
    } else {
        if (rty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
        // Restaurar dirección y almacenar
        emitln(ftext, "    ldr x9, [sp]");
        emitln(ftext, "    add sp, sp, #16");
        emitln(ftext, "    str w1, [x9]");
    }
    if (bytes > 0) { char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb); }
    return 1;
}

void arm64_emit_runtime_arreglo_helpers(FILE *ftext) {
    // Extracted from arm64_codegen.c emit_array_helpers
    emitln(ftext, "// --- Runtime helpers para arreglos ---");
    emitln(ftext, "// x0 = dims (w0), x1 = ptr a sizes[int32] -> retorna x0 puntero a arreglo de elementos de 4 bytes");
    emitln(ftext, "new_array_flat:");
    emitln(ftext, "    stp x29, x30, [sp, -16]!");
    emitln(ftext, "    mov x29, sp");
    emitln(ftext, "    sub sp, sp, #80");
    emitln(ftext, "    stp x19, x20, [sp, #0]");
    emitln(ftext, "    stp x21, x22, [sp, #16]");
    emitln(ftext, "    stp x23, x24, [sp, #32]");
    emitln(ftext, "    stp x25, x26, [sp, #48]");
    emitln(ftext, "    stp x27, x28, [sp, #64]");
    emitln(ftext, "    mov w19, w0");
    emitln(ftext, "    mov x20, x1");
    emitln(ftext, "    mov x21, #1");
    emitln(ftext, "    mov w12, #0");
    emitln(ftext, "L_arr_prod_loop:");
    emitln(ftext, "    cmp w12, w19");
    emitln(ftext, "    b.ge L_arr_prod_done");
    emitln(ftext, "    add x14, x20, x12, uxtw #2");
    emitln(ftext, "    ldr w13, [x14]");
    emitln(ftext, "    uxtw x13, w13");
    emitln(ftext, "    mul x21, x21, x13");
    emitln(ftext, "    add w12, w12, #1");
    emitln(ftext, "    b L_arr_prod_loop");
    emitln(ftext, "L_arr_prod_done:");
    emitln(ftext, "    mov x15, #8");
    emitln(ftext, "    uxtw x16, w19");
    emitln(ftext, "    lsl x16, x16, #2");
    emitln(ftext, "    add x15, x15, x16");
    emitln(ftext, "    add x17, x15, #7");
    emitln(ftext, "    and x17, x17, #-8");
    emitln(ftext, "    mov x27, x17");
    emitln(ftext, "    lsl x18, x21, #2");
    emitln(ftext, "    add x22, x17, x18");
    emitln(ftext, "    mov x0, x22");
    emitln(ftext, "    bl malloc");
    emitln(ftext, "    mov x23, x0");
    emitln(ftext, "    str w19, [x23]");
    emitln(ftext, "    add x24, x23, #8");
    emitln(ftext, "    mov w12, #0");
    emitln(ftext, "L_arr_store_sizes:");
    emitln(ftext, "    cmp w12, w19");
    emitln(ftext, "    b.ge L_arr_sizes_done");
    emitln(ftext, "    add x14, x20, x12, uxtw #2");
    emitln(ftext, "    ldr w13, [x14]");
    emitln(ftext, "    add x25, x24, x12, uxtw #2");
    emitln(ftext, "    str w13, [x25]");
    emitln(ftext, "    add w12, w12, #1");
    emitln(ftext, "    b L_arr_store_sizes");
    emitln(ftext, "L_arr_sizes_done:");
    emitln(ftext, "    add x26, x23, x27");
    emitln(ftext, "    mov x25, #0");
    emitln(ftext, "L_arr_zero_loop:");
    emitln(ftext, "    cmp x25, x21");
    emitln(ftext, "    b.ge L_arr_zero_done");
    emitln(ftext, "    add x28, x26, x25, lsl #2");
    emitln(ftext, "    mov w14, #0");
    emitln(ftext, "    str w14, [x28]");
    emitln(ftext, "    add x25, x25, #1");
    emitln(ftext, "    b L_arr_zero_loop");
    emitln(ftext, "L_arr_zero_done:");
    emitln(ftext, "    mov x0, x23");
    emitln(ftext, "    ldp x19, x20, [sp, #0]");
    emitln(ftext, "    ldp x21, x22, [sp, #16]");
    emitln(ftext, "    ldp x23, x24, [sp, #32]");
    emitln(ftext, "    ldp x25, x26, [sp, #48]");
    emitln(ftext, "    ldp x27, x28, [sp, #64]");
    emitln(ftext, "    add sp, sp, #80");
    emitln(ftext, "    ldp x29, x30, [sp], 16");
    emitln(ftext, "    ret\n");

    // Variante para elementos de 8 bytes (punteros/long/double)
    emitln(ftext, "// x0 = dims (w0), x1 = ptr a sizes[int32] -> retorna x0 puntero a arreglo de elementos de 8 bytes");
    emitln(ftext, "new_array_flat_ptr:");
    emitln(ftext, "    stp x29, x30, [sp, -16]!");
    emitln(ftext, "    mov x29, sp");
    emitln(ftext, "    sub sp, sp, #80");
    emitln(ftext, "    stp x19, x20, [sp, #0]");
    emitln(ftext, "    stp x21, x22, [sp, #16]");
    emitln(ftext, "    stp x23, x24, [sp, #32]");
    emitln(ftext, "    stp x25, x26, [sp, #48]");
    emitln(ftext, "    stp x27, x28, [sp, #64]");
    emitln(ftext, "    mov w19, w0");
    emitln(ftext, "    mov x20, x1");
    emitln(ftext, "    mov x21, #1");
    emitln(ftext, "    mov w12, #0");
    emitln(ftext, "L_arrp_prod_loop:");
    emitln(ftext, "    cmp w12, w19");
    emitln(ftext, "    b.ge L_arrp_prod_done");
    emitln(ftext, "    add x14, x20, x12, uxtw #2");
    emitln(ftext, "    ldr w13, [x14]");
    emitln(ftext, "    uxtw x13, w13");
    emitln(ftext, "    mul x21, x21, x13");
    emitln(ftext, "    add w12, w12, #1");
    emitln(ftext, "    b L_arrp_prod_loop");
    emitln(ftext, "L_arrp_prod_done:");
    emitln(ftext, "    mov x15, #8");
    emitln(ftext, "    uxtw x16, w19");
    emitln(ftext, "    lsl x16, x16, #2");
    emitln(ftext, "    add x15, x15, x16");
    emitln(ftext, "    add x17, x15, #7");
    emitln(ftext, "    and x17, x17, #-8");
    emitln(ftext, "    mov x27, x17");
    emitln(ftext, "    lsl x18, x21, #3");
    emitln(ftext, "    add x22, x17, x18");
    emitln(ftext, "    mov x0, x22");
    emitln(ftext, "    bl malloc");
    emitln(ftext, "    mov x23, x0");
    emitln(ftext, "    str w19, [x23]");
    emitln(ftext, "    add x24, x23, #8");
    emitln(ftext, "    mov w12, #0");
    emitln(ftext, "L_arrp_store_sizes:");
    emitln(ftext, "    cmp w12, w19");
    emitln(ftext, "    b.ge L_arrp_sizes_done");
    emitln(ftext, "    add x14, x20, x12, uxtw #2");
    emitln(ftext, "    ldr w13, [x14]");
    emitln(ftext, "    add x25, x24, x12, uxtw #2");
    emitln(ftext, "    str w13, [x25]");
    emitln(ftext, "    add w12, w12, #1");
    emitln(ftext, "    b L_arrp_store_sizes");
    emitln(ftext, "L_arrp_sizes_done:");
    emitln(ftext, "    add x26, x23, x27");
    emitln(ftext, "    mov x25, #0");
    emitln(ftext, "L_arrp_zero_loop:");
    emitln(ftext, "    cmp x25, x21");
    emitln(ftext, "    b.ge L_arrp_zero_done");
    emitln(ftext, "    add x28, x26, x25, lsl #3");
    emitln(ftext, "    mov x14, xzr");
    emitln(ftext, "    str x14, [x28]");
    emitln(ftext, "    add x25, x25, #1");
    emitln(ftext, "    b L_arrp_zero_loop");
    emitln(ftext, "L_arrp_zero_done:");
    emitln(ftext, "    mov x0, x23");
    emitln(ftext, "    ldp x19, x20, [sp, #0]");
    emitln(ftext, "    ldp x21, x22, [sp, #16]");
    emitln(ftext, "    ldp x23, x24, [sp, #32]");
    emitln(ftext, "    ldp x25, x26, [sp, #48]");
    emitln(ftext, "    ldp x27, x28, [sp, #64]");
    emitln(ftext, "    add sp, sp, #80");
    emitln(ftext, "    ldp x29, x30, [sp], 16");
    emitln(ftext, "    ret\n");

    emitln(ftext, "// x0 = arr_ptr, x1 = indices ptr, w2 = num_indices -> x0 = puntero a elemento int");
    emitln(ftext, "array_element_addr:");
    emitln(ftext, "    stp x29, x30, [sp, -16]!");
    emitln(ftext, "    mov x29, sp");
    emitln(ftext, "    sub sp, sp, #80");
    emitln(ftext, "    stp x19, x20, [sp, #0]");
    emitln(ftext, "    stp x21, x22, [sp, #16]");
    emitln(ftext, "    stp x23, x24, [sp, #32]");
    emitln(ftext, "    stp x25, x26, [sp, #48]");
    emitln(ftext, "    stp x27, x28, [sp, #64]");
    emitln(ftext, "    mov x9, x0");
    emitln(ftext, "    mov x10, x1");
    emitln(ftext, "    mov w11, w2");
    emitln(ftext, "    ldr w12, [x9]");
    emitln(ftext, "    mov x15, #8");
    emitln(ftext, "    uxtw x16, w12");
    emitln(ftext, "    lsl x16, x16, #2");
    emitln(ftext, "    add x15, x15, x16");
    emitln(ftext, "    add x17, x15, #7");
    emitln(ftext, "    and x17, x17, #-8");
    emitln(ftext, "    add x18, x9, #8");
    emitln(ftext, "    mov x19, #0");
    emitln(ftext, "    mov w20, #0");
    emitln(ftext, "L_lin_outer:");
    emitln(ftext, "    cmp w20, w11");
    emitln(ftext, "    b.ge L_lin_done");
    emitln(ftext, "    add x21, x10, x20, uxtw #2");
    emitln(ftext, "    ldr w22, [x21]");
    emitln(ftext, "    uxtw x22, w22");
    emitln(ftext, "    mov x23, #1");
    emitln(ftext, "    add w24, w20, #1");
    emitln(ftext, "L_lin_stride:");
    emitln(ftext, "    cmp w24, w12");
    emitln(ftext, "    b.ge L_lin_stride_done");
    emitln(ftext, "    add x25, x18, x24, uxtw #2");
    emitln(ftext, "    ldr w26, [x25]");
    emitln(ftext, "    uxtw x26, w26");
    emitln(ftext, "    mul x23, x23, x26");
    emitln(ftext, "    add w24, w24, #1");
    emitln(ftext, "    b L_lin_stride");
    emitln(ftext, "L_lin_stride_done:");
    emitln(ftext, "    madd x19, x22, x23, x19");
    emitln(ftext, "    add w20, w20, #1");
    emitln(ftext, "    b L_lin_outer");
    emitln(ftext, "L_lin_done:");
    emitln(ftext, "    add x0, x9, x17");
    emitln(ftext, "    add x0, x0, x19, lsl #2");
    emitln(ftext, "    ldp x19, x20, [sp, #0]");
    emitln(ftext, "    ldp x21, x22, [sp, #16]");
    emitln(ftext, "    ldp x23, x24, [sp, #32]");
    emitln(ftext, "    ldp x25, x26, [sp, #48]");
    emitln(ftext, "    ldp x27, x28, [sp, #64]");
    emitln(ftext, "    add sp, sp, #80");
    emitln(ftext, "    ldp x29, x30, [sp], 16");
    emitln(ftext, "    ret\n");

    // Variante para elementos de 8 bytes (punteros/long/double): devuelve la dirección del elemento
    emitln(ftext, "// x0 = arr_ptr, x1 = indices ptr, w2 = num_indices -> x0 = puntero a elemento de 8 bytes");
    emitln(ftext, "array_element_addr_ptr:");
    emitln(ftext, "    stp x29, x30, [sp, -16]!");
    emitln(ftext, "    mov x29, sp");
    emitln(ftext, "    sub sp, sp, #80");
    emitln(ftext, "    stp x19, x20, [sp, #0]");
    emitln(ftext, "    stp x21, x22, [sp, #16]");
    emitln(ftext, "    stp x23, x24, [sp, #32]");
    emitln(ftext, "    stp x25, x26, [sp, #48]");
    emitln(ftext, "    stp x27, x28, [sp, #64]");
    emitln(ftext, "    mov x9, x0");
    emitln(ftext, "    mov x10, x1");
    emitln(ftext, "    mov w11, w2");
    emitln(ftext, "    ldr w12, [x9]");
    emitln(ftext, "    mov x15, #8");
    emitln(ftext, "    uxtw x16, w12");
    emitln(ftext, "    lsl x16, x16, #2");
    emitln(ftext, "    add x15, x15, x16");
    emitln(ftext, "    add x17, x15, #7");
    emitln(ftext, "    and x17, x17, #-8");
    emitln(ftext, "    add x18, x9, #8");
    emitln(ftext, "    mov x19, #0");
    emitln(ftext, "    mov w20, #0");
    emitln(ftext, "L_lin_outer_p:");
    emitln(ftext, "    cmp w20, w11");
    emitln(ftext, "    b.ge L_lin_done_p");
    emitln(ftext, "    add x21, x10, x20, uxtw #2");
    emitln(ftext, "    ldr w22, [x21]");
    emitln(ftext, "    uxtw x22, w22");
    emitln(ftext, "    mov x23, #1");
    emitln(ftext, "    add w24, w20, #1");
    emitln(ftext, "L_lin_stride_p:");
    emitln(ftext, "    cmp w24, w12");
    emitln(ftext, "    b.ge L_lin_stride_done_p");
    emitln(ftext, "    add x25, x18, x24, uxtw #2");
    emitln(ftext, "    ldr w26, [x25]");
    emitln(ftext, "    uxtw x26, w26");
    emitln(ftext, "    mul x23, x23, x26");
    emitln(ftext, "    add w24, w24, #1");
    emitln(ftext, "    b L_lin_stride_p");
    emitln(ftext, "L_lin_stride_done_p:");
    emitln(ftext, "    madd x19, x22, x23, x19");
    emitln(ftext, "    add w20, w20, #1");
    emitln(ftext, "    b L_lin_outer_p");
    emitln(ftext, "L_lin_done_p:");
    emitln(ftext, "    add x0, x9, x17");
    emitln(ftext, "    add x0, x0, x19, lsl #3");
    emitln(ftext, "    ldp x19, x20, [sp, #0]");
    emitln(ftext, "    ldp x21, x22, [sp, #16]");
    emitln(ftext, "    ldp x23, x24, [sp, #32]");
    emitln(ftext, "    ldp x25, x26, [sp, #48]");
    emitln(ftext, "    ldp x27, x28, [sp, #64]");
    emitln(ftext, "    add sp, sp, #80");
    emitln(ftext, "    ldp x29, x30, [sp], 16");
    emitln(ftext, "    ret\n");
}
