#include "codegen/arm64_bool.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_print.h"
#include "codegen/arm64_vars.h"
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
        // Rechazar comparaciones entre strings: deberían ser con .equals()
        const char *lt = node->hijos[0]->node_type ? node->hijos[0]->node_type : "";
        const char *rt = node->hijos[1]->node_type ? node->hijos[1]->node_type : "";
        if ((strcmp(lt, "Primitivo") == 0 && ((PrimitivoExpresion*)node->hijos[0])->tipo == STRING) ||
            (strcmp(rt, "Primitivo") == 0 && ((PrimitivoExpresion*)node->hijos[1])->tipo == STRING) ||
            (strcmp(lt, "Identificador") == 0 && vars_buscar(((IdentificadorExpresion*)node->hijos[0])->nombre) && vars_buscar(((IdentificadorExpresion*)node->hijos[0])->nombre)->tipo == STRING) ||
            (strcmp(rt, "Identificador") == 0 && vars_buscar(((IdentificadorExpresion*)node->hijos[1])->nombre) && vars_buscar(((IdentificadorExpresion*)node->hijos[1])->nombre)->tipo == STRING)) {
            // Forzar false y dejar que el intérprete reporte semántico; en codegen no tenemos error_reporter.
            emitln(ftext, "    mov w1, #0");
            return;
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
        emitir_eval_booleano(node->hijos[0], ftext); emitln(ftext, "    mov w19, w1");
        emitir_eval_booleano(node->hijos[1], ftext); emitln(ftext, "    mov w20, w1");
        emitln(ftext, "    and w1, w19, w20");
        return;
    }
    if (strcmp(t, "Or") == 0) {
        emitir_eval_booleano(node->hijos[0], ftext); emitln(ftext, "    mov w19, w1");
        emitir_eval_booleano(node->hijos[1], ftext); emitln(ftext, "    mov w20, w1");
        emitln(ftext, "    orr w1, w19, w20");
        return;
    }
    if (strcmp(t, "Not") == 0) {
        emitir_eval_booleano(node->hijos[0], ftext);
        emitln(ftext, "    eor w1, w1, #1");
        return;
    }
    emitln(ftext, "    mov w1, #0");
}
