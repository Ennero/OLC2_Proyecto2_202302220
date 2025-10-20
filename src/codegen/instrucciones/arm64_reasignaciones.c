#include "codegen/instrucciones/arm64_reasignaciones.h"
#include <string.h>
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_print.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_globals.h"
#include "codegen/estructuras/arm64_arreglos.h"
#include "ast/nodos/instrucciones/instruccion/reasignacion.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"

static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }
static const char *add_string_literal(const char *text) { return core_add_string_literal(text); }

int arm64_emitir_reasignacion(AbstractExpresion *node, FILE *ftext) {
    if (!(node && node->node_type && strcmp(node->node_type, "Reasignacion") == 0)) return 0;
    ReasignacionExpresion *rea = (ReasignacionExpresion *)node;
    VarEntry *v = buscar_variable(rea->nombre);
    if (!v) {
        const GlobalInfo *gi = globals_lookup(rea->nombre);
        if (!gi) return 1; // nada que hacer
        if (gi->is_const) { emitln(ftext, "    // reasignación a global constante ignorada"); return 1; }
        AbstractExpresion *rhs = node->hijos[0];
        char adr[128]; snprintf(adr, sizeof(adr), "    ldr x16, =g_%s", rea->nombre); emitln(ftext, adr);
        if (gi->tipo == STRING) {
            if (!emitir_eval_string_ptr(rhs, ftext)) emitln(ftext, "    mov x1, #0");
            emitln(ftext, "    str x1, [x16]");
        } else if (gi->tipo == BOOLEAN) {
            emitir_eval_booleano(rhs, ftext);
            emitln(ftext, "    str w1, [x16]");
        } else if (gi->tipo == DOUBLE || gi->tipo == FLOAT) {
            TipoDato ty = emitir_eval_numerico(rhs, ftext);
            if (ty != DOUBLE) emitln(ftext, "    scvtf d0, w1");
            emitln(ftext, "    str d0, [x16]");
        } else {
            TipoDato ty = emitir_eval_numerico(rhs, ftext);
            if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
            emitln(ftext, "    str w1, [x16]");
        }
        return 1;
    }
    if (v->is_const) { emitln(ftext, "    // reasignación a constante ignorada en codegen"); return 1; }
    AbstractExpresion *rhs = node->hijos[0];
    // Soporte para reasignación de arreglos
    if (v->tipo == ARRAY) {
        const char *rtype = rhs->node_type ? rhs->node_type : "";
        if (strcmp(rtype, "ArrayCreation") == 0) {
            // rhs->hijos[1] es la lista de dimensiones
            AbstractExpresion *lista = rhs->hijos[1];
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
                // Elegir helper según tipo base del arreglo registrado
                TipoDato base_t = arm64_array_elem_tipo_for_var(rea->nombre);
                if (base_t == STRING) emitln(ftext, "    bl new_array_flat_ptr");
                else emitln(ftext, "    bl new_array_flat");
                char stp[96]; snprintf(stp, sizeof(stp), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stp);
                char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb);
            } else {
                // dims == 0: asignar NULL
                char stp[128]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, stp);
            }
            return 1;
        } else if (strcmp(rtype, "Primitivo") == 0) {
            PrimitivoExpresion *p = (PrimitivoExpresion *)rhs;
            if (p->tipo == NULO) {
                char stp[128]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, stp);
                return 1;
            }
        }
        // Otros tipos de asignación a arreglo no soportados aquí
        emitln(ftext, "    // reasignación a arreglo: tipo RHS no soportado, ignorado");
        return 1;
    }
    if (v->tipo == STRING) {
        if (rhs->node_type && strcmp(rhs->node_type, "Primitivo") == 0) {
            PrimitivoExpresion *p = (PrimitivoExpresion *)rhs;
            if (p->tipo == STRING) {
                const char *lab = add_string_literal(p->valor ? p->valor : "");
                char l1[64]; snprintf(l1, sizeof(l1), "    ldr x1, =%s", lab); emitln(ftext, l1);
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
            } else if (p->tipo == NULO) {
                char st[128]; snprintf(st, sizeof(st), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
            }
        } else if (rhs->node_type && strcmp(rhs->node_type, "Identificador") == 0) {
            IdentificadorExpresion *rid = (IdentificadorExpresion *)rhs;
            VarEntry *rv = buscar_variable(rid->nombre);
            if (rv) {
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
        }
    } else if (v->tipo == BOOLEAN) {
        emitir_eval_booleano(rhs, ftext);
        char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w1, [x16]", v->offset); emitln(ftext, st);
    } else if (v->tipo == DOUBLE || v->tipo == FLOAT) {
        TipoDato ty = emitir_eval_numerico(rhs, ftext);
        if (ty != DOUBLE) emitln(ftext, "    scvtf d0, w1");
        char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d0, [x16]", v->offset); emitln(ftext, st);
    } else {
        TipoDato ty = emitir_eval_numerico(rhs, ftext);
        if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
        char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w1, [x16]", v->offset); emitln(ftext, st);
    }
    return 1;
}
