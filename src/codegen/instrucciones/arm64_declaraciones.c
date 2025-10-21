#include "codegen/instrucciones/arm64_declaraciones.h"
#include <string.h>
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_print.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_globals.h"
#include "ast/nodos/instrucciones/instruccion/declaracion.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"

static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }
static const char *add_string_literal(const char *text) { return core_add_string_literal(text); }

// Emite código para construir un arreglo desde un ArrayInitializer de forma recursiva.
// Deja en x0 el puntero al arreglo construido.
static void emitir_array_init_rec(AbstractExpresion *init_node, TipoDato base_tipo, int depth, FILE *ftext) {
    if (!init_node || strcmp(init_node->node_type ? init_node->node_type : "", "ArrayInitializer") != 0) {
        // Caso degenerado: crear arreglo 1D de tamaño 1 con el valor evaluado
        emitln(ftext, "    sub sp, sp, #16");
        emitln(ftext, "    mov w1, #1");
        emitln(ftext, "    str w1, [sp]");
        emitln(ftext, "    mov w0, #1");
        emitln(ftext, "    mov x1, sp");
        if (base_tipo == STRING || base_tipo == DOUBLE || base_tipo == FLOAT) emitln(ftext, "    bl new_array_flat_ptr");
        else emitln(ftext, "    bl new_array_flat");
        emitln(ftext, "    add sp, sp, #16");
        // base de datos en x22
        emitln(ftext, "    mov x22, x0");
        emitln(ftext, "    ldr w12, [x22]");
        emitln(ftext, "    mov x15, #8");
        emitln(ftext, "    uxtw x16, w12");
        emitln(ftext, "    lsl x16, x16, #2");
        emitln(ftext, "    add x15, x15, x16");
        emitln(ftext, "    add x17, x15, #7");
        emitln(ftext, "    and x17, x17, #-8");
        emitln(ftext, "    add x22, x22, x17");
        // almacenar único elemento en índice 0
        emitln(ftext, "    mov x23, #0");
        if (base_tipo == STRING) {
            if (!emitir_eval_string_ptr(init_node, ftext)) emitln(ftext, "    mov x1, #0");
            emitln(ftext, "    str x1, [x22, x23, lsl #3]");
        } else if (base_tipo == DOUBLE || base_tipo == FLOAT) {
            TipoDato ety = emitir_eval_numerico(init_node, ftext);
            if (ety != DOUBLE) emitln(ftext, "    scvtf d0, w1");
            emitln(ftext, "    str d0, [x22, x23, lsl #3]");
        } else if (base_tipo == CHAR) {
            TipoDato ety = emitir_eval_numerico(init_node, ftext);
            if (ety == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
            // Los elementos se disponen en celdas de 4 bytes para tipos int-like, incluidos CHAR
            emitln(ftext, "    str w1, [x22, x23, lsl #2]");
        } else {
            TipoDato ety = emitir_eval_numerico(init_node, ftext);
            if (ety == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
            emitln(ftext, "    str w1, [x22, x23, lsl #2]");
        }
        return;
    }

    AbstractExpresion *lista = (init_node->numHijos > 0) ? init_node->hijos[0] : NULL;
    int m = (int)(lista ? lista->numHijos : 0);
    if (depth <= 1) {
        // Construir arreglo 1D de elementos base
        emitln(ftext, "    sub sp, sp, #16");
        { char mvm[64]; snprintf(mvm, sizeof(mvm), "    mov w1, #%d", m); emitln(ftext, mvm); }
        emitln(ftext, "    str w1, [sp]");
        emitln(ftext, "    mov w0, #1");
        emitln(ftext, "    mov x1, sp");
        if (base_tipo == STRING || base_tipo == DOUBLE || base_tipo == FLOAT) emitln(ftext, "    bl new_array_flat_ptr");
        else emitln(ftext, "    bl new_array_flat");
        // x0 = puntero al arreglo; calcular base de datos en x22
        emitln(ftext, "    mov x22, x0");
        emitln(ftext, "    ldr w12, [x22]");
        emitln(ftext, "    mov x15, #8");
        emitln(ftext, "    uxtw x16, w12");
        emitln(ftext, "    lsl x16, x16, #2");
        emitln(ftext, "    add x15, x15, x16");
        emitln(ftext, "    add x17, x15, #7");
        emitln(ftext, "    and x17, x17, #-8");
        emitln(ftext, "    add x22, x22, x17");
        for (int j = 0; j < m; ++j) {
            { char movj[64]; snprintf(movj, sizeof(movj), "    mov x23, #%d", j); emitln(ftext, movj); }
            if (base_tipo == STRING) {
                if (!emitir_eval_string_ptr(lista->hijos[j], ftext)) emitln(ftext, "    mov x1, #0");
                emitln(ftext, "    str x1, [x22, x23, lsl #3]");
            } else if (base_tipo == DOUBLE || base_tipo == FLOAT) {
                TipoDato ety = emitir_eval_numerico(lista->hijos[j], ftext);
                if (ety != DOUBLE) emitln(ftext, "    scvtf d0, w1");
                emitln(ftext, "    str d0, [x22, x23, lsl #3]");
            } else if (base_tipo == CHAR) {
                TipoDato ety = emitir_eval_numerico(lista->hijos[j], ftext);
                if (ety == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                // Los elementos se disponen en celdas de 4 bytes para tipos int-like, incluidos CHAR
                emitln(ftext, "    str w1, [x22, x23, lsl #2]");
            } else {
                TipoDato ety = emitir_eval_numerico(lista->hijos[j], ftext);
                if (ety == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                emitln(ftext, "    str w1, [x22, x23, lsl #2]");
            }
        }
        emitln(ftext, "    add sp, sp, #16");
        return;
    }

    // depth > 1: construir arreglo de punteros (8 bytes) y rellenar con subarreglos
    emitln(ftext, "    sub sp, sp, #16");
    { char mvm[64]; snprintf(mvm, sizeof(mvm), "    mov w1, #%d", m); emitln(ftext, mvm); }
    emitln(ftext, "    str w1, [sp]");
    emitln(ftext, "    mov w0, #1");
    emitln(ftext, "    mov x1, sp");
    emitln(ftext, "    bl new_array_flat_ptr");
    // x0 = puntero al arreglo exterior (de punteros); preservar en x20
    emitln(ftext, "    mov x20, x0");
    // calcular base de datos en x21
    emitln(ftext, "    mov x21, x0");
    emitln(ftext, "    ldr w12, [x21]");
    emitln(ftext, "    mov x15, #8");
    emitln(ftext, "    uxtw x16, w12");
    emitln(ftext, "    lsl x16, x16, #2");
    emitln(ftext, "    add x15, x15, x16");
    emitln(ftext, "    add x17, x15, #7");
    emitln(ftext, "    and x17, x17, #-8");
    emitln(ftext, "    add x21, x21, x17");
    for (int j = 0; j < m; ++j) {
        // Construir subarreglo y almacenar su puntero
        // Guardar puntero del arreglo exterior (x20) y la base de datos (x21) en la pila, ya que la recursión puede clobberlos
        emitln(ftext, "    sub sp, sp, #32");
        emitln(ftext, "    stp x20, x21, [sp]");
        emitir_array_init_rec(lista->hijos[j], base_tipo, depth - 1, ftext);
        // Restaurar puntero del arreglo exterior (x20) y la base de datos (x21)
        emitln(ftext, "    ldp x20, x21, [sp]");
        emitln(ftext, "    add sp, sp, #32");
        { char movj[64]; snprintf(movj, sizeof(movj), "    mov x23, #%d", j); emitln(ftext, movj); }
        emitln(ftext, "    str x0, [x21, x23, lsl #3]");
    }
    // Devolver el puntero al arreglo exterior en x0
    emitln(ftext, "    mov x0, x20");
    emitln(ftext, "    add sp, sp, #16");
}

int arm64_emitir_declaracion(AbstractExpresion *node, FILE *ftext) {
    if (!(node && node->node_type && strcmp(node->node_type, "Declaracion") == 0)) return 0;
    DeclaracionVariable *decl = (DeclaracionVariable *)node;
    if (decl->dimensiones > 0) {
        VarEntry *v = vars_agregar_ext(decl->nombre, ARRAY, 8, decl->es_constante ? 1 : 0, ftext);
        // Registrar tipo base del arreglo para codegen
        arm64_registrar_arreglo(decl->nombre, decl->tipo);
    if (node->numHijos > 0 && node->hijos[0] && strcmp(node->hijos[0]->node_type ? node->hijos[0]->node_type : "", "ArrayCreation") == 0) {
            AbstractExpresion *arr_create = node->hijos[0];
            AbstractExpresion *lista = arr_create->hijos[1];
            int dims = (int)(lista ? lista->numHijos : 0);
            int bytes = ((dims * 4) + 15) & ~15;
            if (bytes > 0) {
                char sub[64]; snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes); emitln(ftext, sub);
                for (int i = 0; i < dims; ++i) {
                    TipoDato ty = emitir_eval_numerico(lista->hijos[i], ftext);
                    if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                    char st[64]; snprintf(st, sizeof(st), "    str w1, [sp, #%d]", i * 4); emitln(ftext, st);
                }
                char mv0[64]; snprintf(mv0, sizeof(mv0), "    mov w0, #%d", dims); emitln(ftext, mv0);
                emitln(ftext, "    mov x1, sp");
                // Elementos de 8 bytes para STRING/DOUBLE/FLOAT, de 4 bytes para INT/CHAR/BOOLEAN
                if (decl->tipo == STRING || decl->tipo == DOUBLE || decl->tipo == FLOAT) emitln(ftext, "    bl new_array_flat_ptr");
                else emitln(ftext, "    bl new_array_flat");
                char stp[96]; snprintf(stp, sizeof(stp), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stp);
                char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb);
            } else {
                char stp[128]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, stp);
            }
    } else if (node->numHijos > 0 && node->hijos[0] && strcmp(node->hijos[0]->node_type ? node->hijos[0]->node_type : "", "ArrayInitializer") == 0) {
            // Construcción recursiva de inicializadores multidimensionales
            emitir_array_init_rec(node->hijos[0], decl->tipo, decl->dimensiones, ftext);
            // Guardar el puntero resultante en la variable destino
            { char stp[96]; snprintf(stp, sizeof(stp), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stp); }
            return 1;
        } else if (node->numHijos > 0 && node->hijos[0] && strcmp(node->hijos[0]->node_type ? node->hijos[0]->node_type : "", "ArrayAccess") == 0) {
            // Inicialización de arreglo desde acceso a otro arreglo (ej. int[] a = b[i];)
            // Evaluar la dirección del elemento (puntero almacenado) y cargar el puntero para almacenarlo en la variable
            AbstractExpresion *acc = node->hijos[0];
            // Calcular profundidad de índices
            int depth = 0; AbstractExpresion *it = acc;
            while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0) { depth++; it = it->hijos[0]; }
            if (!(it && it->node_type && strcmp(it->node_type, "Identificador") == 0)) {
                // No soportado: asignar NULL
                char stp[128]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, stp);
                return 1;
            }
            IdentificadorExpresion *root_id = (IdentificadorExpresion *)it;
            VarEntry *rv = buscar_variable(root_id->nombre);
            if (!rv) {
                // Intentar global
                const GlobalInfo *gi = globals_lookup(root_id->nombre);
                if (gi) {
                    // Reservar stack para índices y empujarlos en orden
                    int bytes = ((depth * 4) + 15) & ~15;
                    if (bytes > 0) { char sub[64]; snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes); emitln(ftext, sub); }
                    // Construir arreglo temporal de nodos de índices en orden izquierda->derecha
                    AbstractExpresion **idx_nodes = NULL;
                    if (depth > 0) idx_nodes = (AbstractExpresion**)malloc(sizeof(AbstractExpresion*) * (size_t)depth);
                    int pos = depth - 1; it = acc;
                    for (int i = 0; i < depth; ++i) { idx_nodes[pos--] = it->hijos[1]; it = it->hijos[0]; }
                    for (int k = 0; k < depth; ++k) {
                        TipoDato ty = emitir_eval_numerico(idx_nodes[k], ftext);
                        if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                        char st[64]; snprintf(st, sizeof(st), "    str w1, [sp, #%d]", k * 4); emitln(ftext, st);
                    }
                    // Cargar puntero base del arreglo global
                    { char lg[128]; snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x0, [x16]", root_id->nombre); emitln(ftext, lg); }
                    emitln(ftext, "    mov x1, sp");
                    { char mv[64]; snprintf(mv, sizeof(mv), "    mov w2, #%d", depth); emitln(ftext, mv); }
                    emitln(ftext, "    bl array_element_addr_ptr");
                    emitln(ftext, "    ldr x0, [x0]");
                    if (bytes > 0) { char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb); }
                    if (idx_nodes) free(idx_nodes);
                    // Guardar puntero en variable
                    { char stp2[96]; snprintf(stp2, sizeof(stp2), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stp2); }
                    return 1;
                }
                // No local ni global
                char stpn[128]; snprintf(stpn, sizeof(stpn), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, stpn);
                return 1;
            }
            // Local: reservar espacio para índices y evaluar en orden
            {
                int bytes = ((depth * 4) + 15) & ~15;
                if (bytes > 0) { char sub[64]; snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes); emitln(ftext, sub); }
                AbstractExpresion **idx_nodes = NULL;
                if (depth > 0) idx_nodes = (AbstractExpresion**)malloc(sizeof(AbstractExpresion*) * (size_t)depth);
                int pos = depth - 1; it = acc;
                for (int i = 0; i < depth; ++i) { idx_nodes[pos--] = it->hijos[1]; it = it->hijos[0]; }
                for (int k = 0; k < depth; ++k) {
                    TipoDato ty = emitir_eval_numerico(idx_nodes[k], ftext);
                    if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                    char st[64]; snprintf(st, sizeof(st), "    str w1, [sp, #%d]", k * 4); emitln(ftext, st);
                }
                // Cargar puntero base del arreglo local y obtener dirección del elemento (puntero almacenado)
                { char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", rv->offset); emitln(ftext, ld); }
                emitln(ftext, "    mov x1, sp");
                { char mv[64]; snprintf(mv, sizeof(mv), "    mov w2, #%d", depth); emitln(ftext, mv); }
                emitln(ftext, "    bl array_element_addr_ptr");
                emitln(ftext, "    ldr x0, [x0]");
                if (bytes > 0) { char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb); }
                if (idx_nodes) free(idx_nodes);
                // Guardar el puntero de subarreglo en la variable declarada
                { char stp2[96]; snprintf(stp2, sizeof(stp2), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stp2); }
                return 1;
            }
        } else if (node->numHijos > 0 && node->hijos[0] && strcmp(node->hijos[0]->node_type ? node->hijos[0]->node_type : "", "ArrayAdd") == 0) {
            // Inicialización mediante numeros = numeros.add(elem);
            AbstractExpresion *rhs = node->hijos[0];
            AbstractExpresion *base_arr = rhs->hijos[0];
            if (!(base_arr && base_arr->node_type && strcmp(base_arr->node_type, "Identificador") == 0)) {
                emitln(ftext, "    // ArrayAdd en declaración: base no soportada (solo identificador)\n    // asignar NULL");
                char stp[128]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, stp);
                return 1;
            }
            IdentificadorExpresion *bid = (IdentificadorExpresion *)base_arr;
            VarEntry *bv = buscar_variable(bid->nombre);
            if (bv) {
                char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x9, [x16]", bv->offset); emitln(ftext, ld);
            } else {
                const GlobalInfo *gi = globals_lookup(bid->nombre);
                if (gi) { char lg[128]; snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x9, [x16]", bid->nombre); emitln(ftext, lg); }
                else { emitln(ftext, "    mov x9, #0"); }
            }
            // x9 = puntero al arreglo original
            // Calcular base de datos y longitud actual
            emitln(ftext, "    // header align y longitud actual (ArrayAdd decl)");
            emitln(ftext, "    ldr w12, [x9]");
            emitln(ftext, "    mov x15, #8");
            emitln(ftext, "    uxtw x16, w12");
            emitln(ftext, "    lsl x16, x16, #2");
            emitln(ftext, "    add x15, x15, x16");
            emitln(ftext, "    add x17, x15, #7");
            emitln(ftext, "    and x17, x17, #-8");
            emitln(ftext, "    add x18, x9, #8");
            emitln(ftext, "    ldr w19, [x18]");
            emitln(ftext, "    add x21, x9, x17");
            // Reservar nuevo arreglo 1D de tamaño n+1
            emitln(ftext, "    sub sp, sp, #16");
            emitln(ftext, "    add w1, w19, #1");
            emitln(ftext, "    str w1, [sp]");
            emitln(ftext, "    mov w0, #1");
            emitln(ftext, "    mov x1, sp");
            // Elegir helper según tipo base del arreglo declarado
            TipoDato base_t = arm64_array_elem_tipo_for_var(decl->nombre);
            if (base_t == STRING || base_t == DOUBLE || base_t == FLOAT) emitln(ftext, "    bl new_array_flat_ptr");
            else emitln(ftext, "    bl new_array_flat");
            // x0 = nuevo arreglo; calcular base de datos nueva en x22
            emitln(ftext, "    mov x20, x0");
            emitln(ftext, "    ldr w12, [x20]");
            emitln(ftext, "    mov x15, #8");
            emitln(ftext, "    uxtw x16, w12");
            emitln(ftext, "    lsl x16, x16, #2");
            emitln(ftext, "    add x15, x15, x16");
            emitln(ftext, "    add x17, x15, #7");
            emitln(ftext, "    and x17, x17, #-8");
            emitln(ftext, "    add x22, x20, x17");
            // Copiar elementos existentes
            emitln(ftext, "    mov w10, #0");
            { int lid = flujo_next_label_id();
              char l[64]; snprintf(l, sizeof(l), "L_copy_decl_%d:", lid); emitln(ftext, l);
              emitln(ftext, "    cmp w10, w19");
              char bge[64]; snprintf(bge, sizeof(bge), "    b.ge L_copy_done_decl_%d", lid); emitln(ftext, bge);
              if (base_t == STRING || base_t == DOUBLE || base_t == FLOAT) {
                  emitln(ftext, "    add x14, x21, x10, lsl #3");
                  emitln(ftext, "    ldr x0, [x14]");
                  emitln(ftext, "    add x15, x22, x10, lsl #3");
                  emitln(ftext, "    str x0, [x15]");
              } else {
                  emitln(ftext, "    add x14, x21, x10, lsl #2");
                  emitln(ftext, "    ldr w0, [x14]");
                  emitln(ftext, "    add x15, x22, x10, lsl #2");
                  emitln(ftext, "    str w0, [x15]");
              }
              emitln(ftext, "    add w10, w10, #1");
              char blp[64]; snprintf(blp, sizeof(blp), "    b L_copy_decl_%d", lid); emitln(ftext, blp);
              char ldone[64]; snprintf(ldone, sizeof(ldone), "L_copy_done_decl_%d:", lid); emitln(ftext, ldone);
            }
            // Añadir nuevo elemento al final
            AbstractExpresion *elem_expr = rhs->hijos[1];
            if (base_t == STRING) {
                if (!emitir_eval_string_ptr(elem_expr, ftext)) emitln(ftext, "    mov x1, #0");
                emitln(ftext, "    mov x0, x1");
                emitln(ftext, "    bl strdup");
                emitln(ftext, "    mov x1, x0");
                emitln(ftext, "    add x15, x22, x19, lsl #3");
                emitln(ftext, "    str x1, [x15]");
            } else if (base_t == DOUBLE || base_t == FLOAT) {
                TipoDato ety = emitir_eval_numerico(elem_expr, ftext);
                if (ety != DOUBLE) emitln(ftext, "    scvtf d0, w1");
                emitln(ftext, "    add x15, x22, x19, lsl #3");
                emitln(ftext, "    str d0, [x15]");
            } else {
                TipoDato ety = emitir_eval_numerico(elem_expr, ftext);
                if (ety == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                emitln(ftext, "    add x15, x22, x19, lsl #2");
                emitln(ftext, "    str w1, [x15]");
            }
            emitln(ftext, "    add sp, sp, #16");
            // Guardar nuevo puntero en la variable declarada
            { char stp[96]; snprintf(stp, sizeof(stp), "    sub x16, x29, #%d\n    str x20, [x16]", v->offset); emitln(ftext, stp); }
            return 1;
        } else if (node->numHijos > 0 && node->hijos[0] && strcmp(node->hijos[0]->node_type ? node->hijos[0]->node_type : "", "FunctionCall") == 0) {
            // Inicialización de arreglo desde retorno de función: se espera puntero en x0
            TipoDato rty = arm64_emitir_llamada_funcion(node->hijos[0], ftext);
            (void)rty; // ignoramos, asumimos contrato x0
            char stp[96]; snprintf(stp, sizeof(stp), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stp);
        } else {
            // Sin inicializador conocido -> NULL
            char stp[128]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, stp);
        }
        return 1;
    }

    int size = (decl->tipo == DOUBLE) ? 8 : 8;
    VarEntry *v = NULL;
    int is_const = decl->es_constante ? 1 : 0;
    v = vars_agregar_ext(decl->nombre, decl->tipo, size, is_const, ftext);
    if (node->numHijos > 0) {
        AbstractExpresion *init = node->hijos[0];
        if (init && init->node_type && strcmp(init->node_type, "FunctionCall") == 0) {
            // Emite la llamada como tal y mueve el retorno según el tipo declarado
            TipoDato call_ret = arm64_emitir_llamada_funcion(init, ftext);
            if (decl->tipo == DOUBLE || decl->tipo == FLOAT) {
                if (call_ret != DOUBLE) emitln(ftext, "    scvtf d0, w1");
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d0, [x16]", v->offset); emitln(ftext, st);
            } else if (decl->tipo == STRING) {
                // Si la función retornó STRING, arm64_emitir_llamada_funcion refleja x0->x1
                if (call_ret == STRING) {
                    char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
                } else {
                    // Otros tipos no son asignables directamente a STRING aquí: inicializar a null
                    emitln(ftext, "    mov x1, #0");
                    char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
                }
            } else if (decl->tipo == ARRAY) {
                // Se espera que funciones que retornan arreglos pongan puntero en x0; guardarlo
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, st);
            } else {
                if (call_ret == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w1, [x16]", v->offset); emitln(ftext, st);
            }
        } else if (decl->tipo == DOUBLE || decl->tipo == FLOAT) {
            TipoDato ty = emitir_eval_numerico(init, ftext);
            if (ty != DOUBLE) emitln(ftext, "    scvtf d0, w1");
            char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d0, [x16]", v->offset); emitln(ftext, st);
        } else if (decl->tipo == BOOLEAN) {
            emitir_eval_booleano(init, ftext);
            char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w1, [x16]", v->offset); emitln(ftext, st);
        } else if (decl->tipo == STRING) {
            if (strcmp(init->node_type, "Primitivo") == 0) {
                PrimitivoExpresion *p = (PrimitivoExpresion *)init;
                if (p->tipo == STRING) {
                    const char *lab = add_string_literal(p->valor ? p->valor : "");
                    char l1[64]; snprintf(l1, sizeof(l1), "    ldr x1, =%s", lab); emitln(ftext, l1);
                    char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
                } else if (p->tipo == NULO) {
                    char st[128]; snprintf(st, sizeof(st), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
                }
            } else if (strcmp(init->node_type ? init->node_type : "", "Identificador") == 0) {
                IdentificadorExpresion *rid = (IdentificadorExpresion *)init;
                VarEntry *rv = buscar_variable(rid->nombre);
                if (rv && rv->tipo == STRING) {
                    char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr x1, [x16]", rv->offset); emitln(ftext, l1);
                    char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
                } else {
                    const GlobalInfo *gi = globals_lookup(rid->nombre);
                    if (gi && gi->tipo == STRING) {
                        char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr x1, [x16]", rid->nombre); emitln(ftext, l1);
                        char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
                    } else {
                        char st[128]; snprintf(st, sizeof(st), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
                    }
                }
            } else if (expresion_es_cadena(init)) {
                // Evaluar a puntero de string y duplicar para evitar alias con tmpbuf
                if (!emitir_eval_string_ptr(init, ftext)) emitln(ftext, "    mov x1, #0");
                // x1 puede apuntar a tmpbuf (concatenación) -> duplicar
                emitln(ftext, "    mov x0, x1");
                emitln(ftext, "    bl strdup");
                emitln(ftext, "    mov x1, x0");
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
            } else {
                char st[128]; snprintf(st, sizeof(st), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
            }
        } else {
            TipoDato ty = emitir_eval_numerico(init, ftext);
            if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
            char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w1, [x16]", v->offset); emitln(ftext, st);
        }
    } else {
        if (decl->tipo == STRING) {
            char st[128]; snprintf(st, sizeof(st), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
        } else if (decl->tipo == DOUBLE || decl->tipo == FLOAT) {
            emitln(ftext, "    fmov d0, xzr");
            char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d0, [x16]", v->offset); emitln(ftext, st);
        } else {
            char st[128]; snprintf(st, sizeof(st), "    mov w1, #0\n    sub x16, x29, #%d\n    str w1, [x16]", v->offset); emitln(ftext, st);
        }
    }
    return 1;
}
