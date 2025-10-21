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
                // Para ahora, usamos elementos de 4 bytes para INT/CHAR y 8 bytes para STRING
                if (decl->tipo == STRING) emitln(ftext, "    bl new_array_flat_ptr");
                else emitln(ftext, "    bl new_array_flat");
                char stp[96]; snprintf(stp, sizeof(stp), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stp);
                char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb);
            } else {
                char stp[128]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, stp);
            }
    } else if (node->numHijos > 0 && node->hijos[0] && strcmp(node->hijos[0]->node_type ? node->hijos[0]->node_type : "", "ArrayInitializer") == 0) {
            // Soportar inicializador 1D y 2D (p. ej. String[][]): { {..}, {..} }
            AbstractExpresion *arr_init = node->hijos[0];
            AbstractExpresion *lista = (arr_init->numHijos > 0) ? arr_init->hijos[0] : NULL;
            int n = (int)(lista ? lista->numHijos : 0);
            // Crear el arreglo exterior de tamaño n
            emitln(ftext, "    sub sp, sp, #16");
            { char mvn[64]; snprintf(mvn, sizeof(mvn), "    mov w1, #%d", n); emitln(ftext, mvn); }
            emitln(ftext, "    str w1, [sp]");
            emitln(ftext, "    mov w0, #1");
            emitln(ftext, "    mov x1, sp");
            // Elementos del arreglo exterior: si es arreglo de punteros (STRING[][], DOUBLE[][]) usar new_array_flat_ptr
            if (decl->tipo == STRING || decl->dimensiones > 1) emitln(ftext, "    bl new_array_flat_ptr");
            else emitln(ftext, "    bl new_array_flat");
            // Guardar el puntero del arreglo exterior en la variable
            { char stp[96]; snprintf(stp, sizeof(stp), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stp); }
            emitln(ftext, "    add sp, sp, #16");
            // Calcular base de datos (después de header alineado) en x19 cuando se necesite
            for (int i = 0; i < n; ++i) {
                // Cargar puntero a arreglo exterior en x19
                { char ldrp[96]; snprintf(ldrp, sizeof(ldrp), "    sub x16, x29, #%d\n    ldr x19, [x16]", v->offset); emitln(ftext, ldrp); }
                // base de datos: x19 += align_up(8 + dims*4, 8) con dims = [x19]
                emitln(ftext, "    ldr w12, [x19]");
                emitln(ftext, "    mov x15, #8");
                emitln(ftext, "    uxtw x16, w12");
                emitln(ftext, "    lsl x16, x16, #2");
                emitln(ftext, "    add x15, x15, x16");
                emitln(ftext, "    add x17, x15, #7");
                emitln(ftext, "    and x17, x17, #-8");
                emitln(ftext, "    add x19, x19, x17");
                // Dirección del elemento i del arreglo exterior en x20
                { char movi[64]; snprintf(movi, sizeof(movi), "    mov x21, #%d", i); emitln(ftext, movi); }
                // Arreglos (tipo base STRING o dimensiones>1) almacenan punteros (8 bytes)
                emitln(ftext, "    add x20, x19, x21, lsl #3");

                AbstractExpresion *elem_i = lista ? lista->hijos[i] : NULL;
                // Si el elemento es otro inicializador, construir un arreglo interno 1D y asignarlo
                if (elem_i && strcmp(elem_i->node_type ? elem_i->node_type : "", "ArrayInitializer") == 0) {
                    AbstractExpresion *inner_list = (elem_i->numHijos > 0) ? elem_i->hijos[0] : NULL;
                    int m = (int)(inner_list ? inner_list->numHijos : 0);
                    // Crear arreglo interno 1D de tamaño m (punteros si base STRING)
                    emitln(ftext, "    sub sp, sp, #16");
                    { char mvm[64]; snprintf(mvm, sizeof(mvm), "    mov w1, #%d", m); emitln(ftext, mvm); }
                    emitln(ftext, "    str w1, [sp]");
                    emitln(ftext, "    mov w0, #1");
                    emitln(ftext, "    mov x1, sp");
                    // En este caso, el arreglo interno es de elementos base 'decl->tipo'
                    if (decl->tipo == STRING) emitln(ftext, "    bl new_array_flat_ptr");
                    else emitln(ftext, "    bl new_array_flat");
                    // Guardar puntero del arreglo interno en el slot del arreglo exterior
                    emitln(ftext, "    str x0, [x20]");
                    // Base de datos del arreglo interno en x22
                    emitln(ftext, "    mov x22, x0");
                    emitln(ftext, "    ldr w12, [x22]");
                    emitln(ftext, "    mov x15, #8");
                    emitln(ftext, "    uxtw x16, w12");
                    emitln(ftext, "    lsl x16, x16, #2");
                    emitln(ftext, "    add x15, x15, x16");
                    emitln(ftext, "    add x17, x15, #7");
                    emitln(ftext, "    and x17, x17, #-8");
                    emitln(ftext, "    add x22, x22, x17");
                    // Rellenar elementos del arreglo interno
                    for (int j = 0; j < m; ++j) {
                        { char movj[64]; snprintf(movj, sizeof(movj), "    mov x23, #%d", j); emitln(ftext, movj); }
                        if (decl->tipo == STRING) {
                            // Evaluar string y almacenar en arreglo interno
                            if (!emitir_eval_string_ptr(inner_list->hijos[j], ftext)) emitln(ftext, "    mov x1, #0");
                            emitln(ftext, "    str x1, [x22, x23, lsl #3]");
                        } else {
                            TipoDato ety = emitir_eval_numerico(inner_list->hijos[j], ftext);
                            if (ety == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                            emitln(ftext, "    str w1, [x22, x23, lsl #2]");
                        }
                    }
                    emitln(ftext, "    add sp, sp, #16");
                } else {
                    // Caso 1D original: evaluar y almacenar directamente
                    if (decl->tipo == STRING) {
                        if (!emitir_eval_string_ptr(elem_i, ftext)) emitln(ftext, "    mov x1, #0");
                        emitln(ftext, "    str x1, [x20]");
                    } else {
                        TipoDato ety = emitir_eval_numerico(elem_i, ftext);
                        if (ety == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                        emitln(ftext, "    // elemento 1D en arreglo base de 4 bytes");
                        emitln(ftext, "    str w1, [x19, x21, lsl #2]");
                    }
                }
            }
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
                // Para STRING, el contrato de arm64_emitir_llamada_funcion no garantiza x1, así que evaluamos explícitamente si es STRING
                if (call_ret == DOUBLE) {
                    // No aplicable; forzar NULL
                    emitln(ftext, "    mov x1, #0");
                } else {
                    // Si la función devolvió int-like en w1, usar valueOf o NULL; como inicialización directa de string desde fn no estándar, usar 0
                    emitln(ftext, "    mov x1, #0");
                }
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
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
                if (!emitir_eval_string_ptr(init, ftext)) emitln(ftext, "    mov x1, #0");
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
