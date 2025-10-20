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
                emitln(ftext, "    bl new_array_flat");
                char stp[96]; snprintf(stp, sizeof(stp), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stp);
                char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb);
            } else {
                char stp[128]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, stp);
            }
        } else {
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
            TipoDato rty = emitir_eval_numerico(init, ftext); // se revalúa abajo por tipo
            // Mejor usar funciones: pero mantenemos compatibilidad
            // Para coherencia, volvemos a emitir llamada con arm64_emitir_llamada_funcion en el caller
            // Aquí mantenemos lógica previa: mover valores según tipo
            if (decl->tipo == DOUBLE || decl->tipo == FLOAT) {
                if (rty != DOUBLE) emitln(ftext, "    scvtf d0, w1");
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d0, [x16]", v->offset); emitln(ftext, st);
            } else if (decl->tipo == STRING) {
                if (!emitir_eval_string_ptr(init, ftext)) emitln(ftext, "    mov x1, #0");
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", v->offset); emitln(ftext, st);
            } else {
                if (rty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
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
