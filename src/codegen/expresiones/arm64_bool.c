#include "codegen/arm64_bool.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_print.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_globals.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "ast/nodos/expresiones/relacionales/relacionales.h"
#include "ast/nodos/expresiones/logicas/logicas.h"
#include <string.h>
#include <stdlib.h>

static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }

int nodo_es_resultado_booleano(AbstractExpresion *node) {
    if (!node || !node->node_type) return 0;
    const char *t = node->node_type;
    return strcmp(t, "IgualIgual") == 0 || strcmp(t, "Diferente") == 0 ||
           strcmp(t, "MayorQue") == 0 || strcmp(t, "MenorQue") == 0 ||
           strcmp(t, "MayorIgual") == 0 || strcmp(t, "MenorIgual") == 0 ||
           strcmp(t, "And") == 0 || strcmp(t, "Or") == 0 || strcmp(t, "Not") == 0 ||
           strcmp(t, "EqualsMethod") == 0;
}

void emitir_eval_booleano(AbstractExpresion *node, FILE *ftext) {
    const char *t = node->node_type ? node->node_type : "";
    if (strcmp(t, "Primitivo") == 0) {
        PrimitivoExpresion *p = (PrimitivoExpresion *)node;
        if (p->tipo == BOOLEAN) {
            int is_true = (p->valor && strcmp(p->valor, "true") == 0);
            char line[64]; snprintf(line, sizeof(line), "    mov w1, #%d", is_true ? 1 : 0); emitln(ftext, line);
            return;
        }
        TipoDato ty = emitir_eval_numerico(node, ftext);
        if (ty == DOUBLE) {
            emitln(ftext, "    fcmp d0, #0.0");
            emitln(ftext, "    cset w1, ne");
        } else {
            emitln(ftext, "    cmp w1, #0");
            emitln(ftext, "    cset w1, ne");
        }
        return;
    }
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = buscar_variable(id->nombre);
        if (v && v->tipo == BOOLEAN) {
            char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset); emitln(ftext, l1);
            return;
        }
        TipoDato ty = emitir_eval_numerico(node, ftext);
        if (ty == DOUBLE) { emitln(ftext, "    fcmp d0, #0.0"); emitln(ftext, "    cset w1, ne"); }
        else { emitln(ftext, "    cmp w1, #0"); emitln(ftext, "    cset w1, ne"); }
        return;
    }
    if (strcmp(t, "EqualsMethod") == 0) {
        // .equals entre strings: igualdad por contenido usando strcmp
        // Si cualquiera no es string, resultado false (y evitar strcmp(NULL,...))
        emitln(ftext, "    // EqualsMethod: evaluar punteros de string");
        emitln(ftext, "    // lhs");
        if (!emitir_eval_string_ptr(node->hijos[0], ftext)) {
            emitln(ftext, "    mov w1, #0");
            return;
        }
        emitln(ftext, "    mov x19, x1");
        emitln(ftext, "    // rhs");
        if (!emitir_eval_string_ptr(node->hijos[1], ftext)) {
            emitln(ftext, "    mov w1, #0");
            return;
        }
        emitln(ftext, "    mov x20, x1");
        emitln(ftext, "    mov x0, x19");
        emitln(ftext, "    mov x1, x20");
        emitln(ftext, "    bl strcmp");
        emitln(ftext, "    cmp w0, #0");
        emitln(ftext, "    cset w1, eq");
        return;
    }

    if (strcmp(t, "IgualIgual") == 0 || strcmp(t, "Diferente") == 0 ||
        strcmp(t, "MayorQue") == 0 || strcmp(t, "MenorQue") == 0 ||
        strcmp(t, "MayorIgual") == 0 || strcmp(t, "MenorIgual") == 0) {
        // Casos especiales: comparaciones con null
        // Si uno de los lados es NULL y el otro es string (literal/identificador), comparar puntero con 0
        const char *lt = node->hijos[0]->node_type ? node->hijos[0]->node_type : "";
        const char *rt = node->hijos[1]->node_type ? node->hijos[1]->node_type : "";
        int left_is_null = (strcmp(lt, "Primitivo") == 0 && ((PrimitivoExpresion*)node->hijos[0])->tipo == NULO);
        int right_is_null = (strcmp(rt, "Primitivo") == 0 && ((PrimitivoExpresion*)node->hijos[1])->tipo == NULO);
        if (left_is_null || right_is_null) {
            // Evaluar el otro lado como puntero y comparar con 0
            int comparing_eq = (strcmp(t, "IgualIgual") == 0);
            AbstractExpresion *other = left_is_null ? node->hijos[1] : node->hijos[0];
            int got_ptr = 0;
            // 1) Camino normal: si podemos evaluarlo como string ptr
            if (emitir_eval_string_ptr(other, ftext)) {
                got_ptr = 1;
            } else {
                const char *ot = other->node_type ? other->node_type : "";
                // 2) Identificador: cargar como puntero desde local o global
                if (strcmp(ot, "Identificador") == 0) {
                    IdentificadorExpresion *oid = (IdentificadorExpresion *)other;
                    VarEntry *ov = buscar_variable(oid->nombre);
                    if (ov) {
                        char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr x1, [x16]", ov->offset); emitln(ftext, l1);
                        got_ptr = 1;
                    } else {
                        const GlobalInfo *gi = globals_lookup(oid->nombre);
                        if (gi && gi->tipo == STRING) {
                            char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr x1, [x16]", oid->nombre); emitln(ftext, l1);
                            got_ptr = 1;
                        }
                    }
                } else if (strcmp(ot, "Primitivo") == 0) {
                    // Literal cadena
                    PrimitivoExpresion *pp = (PrimitivoExpresion *)other;
                    if (pp->tipo == STRING) {
                        const char *lab = core_add_string_literal(pp->valor ? pp->valor : "");
                        char l2[64]; snprintf(l2, sizeof(l2), "    ldr x1, =%s", lab); emitln(ftext, l2);
                        got_ptr = 1;
                    }
                } else if (strcmp(ot, "StringValueof") == 0) {
                    // valueOf siempre produce cadena en x1
                    emitir_string_valueof(other->hijos[0], ftext);
                    got_ptr = 1;
                }
            }
            if (!got_ptr) {
                // No pudimos evaluarlo como cadena: comparar no es válido -> false para == null
                emitln(ftext, comparing_eq ? "    mov w1, #0" : "    mov w1, #1");
                return;
            }
            // x1 contiene puntero; comparar con 0
            emitln(ftext, "    cmp x1, #0");
            emitln(ftext, comparing_eq ? "    cset w1, eq" : "    cset w1, ne");
            return;
        }
        // Comparación entre strings: sólo aplicar comparación por contenido para == y !=
        if (strcmp(t, "IgualIgual") == 0 || strcmp(t, "Diferente") == 0) {
            int lhs_is_str = 0;
            int rhs_is_str = 0;
            if (emitir_eval_string_ptr(node->hijos[0], ftext)) { emitln(ftext, "    mov x19, x1"); lhs_is_str = 1; }
            if (lhs_is_str && emitir_eval_string_ptr(node->hijos[1], ftext)) { emitln(ftext, "    mov x20, x1"); rhs_is_str = 1; }
            if (lhs_is_str && rhs_is_str) {
                // Si cualquiera es NULL, comparar por puntero directamente
                emitln(ftext, "    cmp x19, #0");
                emitln(ftext, "    beq 1f");
                emitln(ftext, "    cmp x20, #0");
                emitln(ftext, "    beq 1f");
                // Ambos no NULL: strcmp
                emitln(ftext, "    mov x0, x19");
                emitln(ftext, "    mov x1, x20");
                emitln(ftext, "    bl strcmp");
                emitln(ftext, "    cmp w0, #0");
                if (strcmp(t, "IgualIgual") == 0) emitln(ftext, "    cset w1, eq");
                else emitln(ftext, "    cset w1, ne");
                emitln(ftext, "    b 2f");
                // Etiqueta: comparar por puntero (maneja NULLs)
                emitln(ftext, "1:");
                emitln(ftext, "    cmp x19, x20");
                if (strcmp(t, "IgualIgual") == 0) emitln(ftext, "    cset w1, eq");
                else emitln(ftext, "    cset w1, ne");
                emitln(ftext, "2:");
                return;
            }
        }
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        // Preservar lhs en stack para evitar clobber durante evaluación de rhs
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE) emitln(ftext, "    str d0, [sp]"); else emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        int use_fp = (tl == DOUBLE || tr == DOUBLE);
        if (use_fp) {
            if (tl == DOUBLE) emitln(ftext, "    ldr d8, [sp]"); else { emitln(ftext, "    ldr w19, [sp]"); emitln(ftext, "    scvtf d8, w19"); }
            if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    fcmp d8, d9");
        } else {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    cmp w19, w1");
        }
        if (strcmp(t, "IgualIgual") == 0) emitln(ftext, "    cset w1, eq");
        else if (strcmp(t, "Diferente") == 0) emitln(ftext, "    cset w1, ne");
        else if (strcmp(t, "MayorQue") == 0) emitln(ftext, "    cset w1, gt");
        else if (strcmp(t, "MenorQue") == 0) emitln(ftext, "    cset w1, lt");
        else if (strcmp(t, "MayorIgual") == 0) emitln(ftext, "    cset w1, ge");
        else if (strcmp(t, "MenorIgual") == 0) emitln(ftext, "    cset w1, le");
        return;
    }
    if (strcmp(t, "And") == 0) {
        // Usar registros temporales dedicados para evitar ser pisados por sub-llamadas
        emitir_eval_booleano(node->hijos[0], ftext); emitln(ftext, "    mov w9, w1");
        emitir_eval_booleano(node->hijos[1], ftext); emitln(ftext, "    mov w10, w1");
        emitln(ftext, "    and w1, w9, w10");
        return;
    }
    if (strcmp(t, "Or") == 0) {
        emitir_eval_booleano(node->hijos[0], ftext); emitln(ftext, "    mov w9, w1");
        emitir_eval_booleano(node->hijos[1], ftext); emitln(ftext, "    mov w10, w1");
        emitln(ftext, "    orr w1, w9, w10");
        return;
    }
    if (strcmp(t, "Not") == 0) {
        emitir_eval_booleano(node->hijos[0], ftext);
        emitln(ftext, "    eor w1, w1, #1");
        return;
    }
    emitln(ftext, "    mov w1, #0");
}
