#include "codegen/instrucciones/arm64_asignacion_compuesta.h"
#include <string.h>
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_globals.h"
#include "codegen/arm64_print.h"
#include "ast/nodos/instrucciones/instruccion/asignacion_compuesta.h"
#include "parser.tab.h"

static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }

int arm64_emitir_asignacion_compuesta(AbstractExpresion *node, FILE *ftext) {
    if (!(node && node->node_type && strcmp(node->node_type, "AsignacionCompuesta") == 0)) return 0;
    AsignacionCompuestaExpresion *ac = (AsignacionCompuestaExpresion *)node;
    VarEntry *v = buscar_variable(ac->nombre);
    if (!v) {
        const GlobalInfo *gi = globals_lookup(ac->nombre);
        if (!gi) return 1;
        if (gi->is_const) { emitln(ftext, "    // asignación compuesta sobre global constante ignorada"); return 1; }
        AbstractExpresion *rhs = node->hijos[0];
        int op = ac->op_type;
        char adr[128]; snprintf(adr, sizeof(adr), "    ldr x16, =g_%s", ac->nombre); emitln(ftext, adr);
        if (op == '&' || op == '|' || op == '^' || op == TOKEN_LSHIFT || op == TOKEN_RSHIFT || op == TOKEN_URSHIFT) {
            emitln(ftext, "    ldr w19, [x16]");
            TipoDato tr = emitir_eval_numerico(rhs, ftext);
            if (tr == DOUBLE) emitln(ftext, "    fcvtzs w20, d0"); else emitln(ftext, "    mov w20, w1");
            if (op == '&') emitln(ftext, "    and w1, w19, w20");
            else if (op == '|') emitln(ftext, "    orr w1, w19, w20");
            else if (op == '^') emitln(ftext, "    eor w1, w19, w20");
            else if (op == TOKEN_LSHIFT) emitln(ftext, "    lsl w1, w19, w20");
            else if (op == TOKEN_RSHIFT) emitln(ftext, "    asr w1, w19, w20");
            else /* TOKEN_URSHIFT */ emitln(ftext, "    lsr w1, w19, w20");
            emitln(ftext, "    str w1, [x16]");
        } else if (op == '+' || op == '-' || op == '*' || op == '/' || op == '%') {
            // Concatenación de strings para globales: g += rhs
            if (op == '+' && gi->tipo == STRING) {
                // Construir en tmpbuf: primero el valor actual del global ("null" si es NULL)
                emitln(ftext, "    // string += (global)\n    ldr x0, =tmpbuf\n    mov w2, #0\n    strb w2, [x0]");
                // x16 ya tiene &g_name
                emitln(ftext, "    ldr x1, [x16]");
                emitln(ftext, "    cmp x1, #0");
                emitln(ftext, "    ldr x17, =null_str");
                emitln(ftext, "    csel x1, x17, x1, eq");
                emitln(ftext, "    ldr x0, =tmpbuf");
                emitln(ftext, "    bl strcat");
                // Evaluar RHS a puntero de cadena en x1; si no es cadena, usar valueOf
                int ok = emitir_eval_string_ptr(rhs, ftext);
                if (!ok) {
                    emitir_string_valueof(rhs, ftext);
                }
                // Copiar RHS a joinbuf para evitar alias si vino de tmpbuf
                emitln(ftext, "    ldr x0, =joinbuf");
                emitln(ftext, "    bl strcpy");
                // Append de joinbuf a tmpbuf
                emitln(ftext, "    ldr x0, =tmpbuf");
                emitln(ftext, "    ldr x1, =joinbuf");
                emitln(ftext, "    bl strcat");
                // Duplicar y almacenar en global
                emitln(ftext, "    ldr x0, =tmpbuf");
                emitln(ftext, "    bl strdup");
                emitln(ftext, "    str x0, [x16]");
                return 1;
            }
            int gi_is_double = (gi->tipo == DOUBLE || gi->tipo == FLOAT);
            if (gi_is_double) emitln(ftext, "    ldr d8, [x16]"); else emitln(ftext, "    ldr w19, [x16]");
            TipoDato tr = emitir_eval_numerico(rhs, ftext);
            int use_fp = gi_is_double || (tr == DOUBLE);
            if (use_fp) {
                if (!gi_is_double) emitln(ftext, "    scvtf d8, w19");
                if (tr != DOUBLE) emitln(ftext, "    scvtf d9, w1"); else emitln(ftext, "    fmov d9, d0");
                if (op == '+') emitln(ftext, "    fadd d0, d8, d9");
                else if (op == '-') emitln(ftext, "    fsub d0, d8, d9");
                else if (op == '*') emitln(ftext, "    fmul d0, d8, d9");
                else if (op == '/') emitln(ftext, "    fdiv d0, d8, d9");
                else { emitln(ftext, "    fmov d0, d8"); emitln(ftext, "    fmov d1, d9"); emitln(ftext, "    bl fmod"); }
                emitln(ftext, "    str d0, [x16]");
            } else {
                if (op == '+') emitln(ftext, "    add w1, w19, w1");
                else if (op == '-') emitln(ftext, "    sub w1, w19, w1");
                else if (op == '*') emitln(ftext, "    mul w1, w19, w1");
                else if (op == '/') emitln(ftext, "    sdiv w1, w19, w1");
                else { emitln(ftext, "    sdiv w21, w19, w1"); emitln(ftext, "    msub w1, w21, w1, w19"); }
                emitln(ftext, "    str w1, [x16]");
            }
        }
        return 1;
    }
    if (v->is_const) { emitln(ftext, "    // asignación compuesta sobre constante ignorada"); return 1; }
    AbstractExpresion *rhs = node->hijos[0];
    int op = ac->op_type;
    if (op == '&' || op == '|' || op == '^' || op == TOKEN_LSHIFT || op == TOKEN_RSHIFT || op == TOKEN_URSHIFT) {
        char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w19, [x16]", v->offset); emitln(ftext, l1);
        TipoDato tr = emitir_eval_numerico(rhs, ftext);
        if (tr == DOUBLE) emitln(ftext, "    fcvtzs w20, d0"); else emitln(ftext, "    mov w20, w1");
        if (op == '&') emitln(ftext, "    and w1, w19, w20");
        else if (op == '|') emitln(ftext, "    orr w1, w19, w20");
        else if (op == '^') emitln(ftext, "    eor w1, w19, w20");
        else if (op == TOKEN_LSHIFT) emitln(ftext, "    lsl w1, w19, w20");
        else if (op == TOKEN_RSHIFT) emitln(ftext, "    asr w1, w19, w20");
        else /* TOKEN_URSHIFT */ emitln(ftext, "    lsr w1, w19, w20");
        char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w1, [x16]", v->offset); emitln(ftext, st);
    } else if (op == '+' || op == '-' || op == '*' || op == '/' || op == '%') {
        // Soporte para string += expr en variables locales
        if (op == '+' && v->tipo == STRING) {
            // Inicializar tmpbuf vacío
            emitln(ftext, "    // string += (local)\n    ldr x0, =tmpbuf\n    mov w2, #0\n    strb w2, [x0]");
            // Cargar puntero actual de la variable (respetando referencias)
            if (v->is_ref) {
                char lref[128]; snprintf(lref, sizeof(lref), "    sub x16, x29, #%d\n    ldr x17, [x16]\n    ldr x1, [x17]", v->offset); emitln(ftext, lref);
            } else {
                char l1s[96]; snprintf(l1s, sizeof(l1s), "    sub x16, x29, #%d\n    ldr x1, [x16]", v->offset); emitln(ftext, l1s);
            }
            // Sustituir NULL por "null" para concatenación estilo Java
            emitln(ftext, "    cmp x1, #0");
            emitln(ftext, "    ldr x17, =null_str");
            emitln(ftext, "    csel x1, x17, x1, eq");
            emitln(ftext, "    ldr x0, =tmpbuf");
            emitln(ftext, "    bl strcat");
            // Evaluar RHS como string: preferir puntero si ya es cadena; si no, usar valueOf (dup)
            int ok2 = emitir_eval_string_ptr(rhs, ftext);
            if (!ok2) {
                emitir_string_valueof(rhs, ftext);
            }
            // Copiar RHS a joinbuf para evitar alias si proviene de tmpbuf
            emitln(ftext, "    ldr x0, =joinbuf");
            emitln(ftext, "    bl strcpy");
            // Append de joinbuf a tmpbuf
            emitln(ftext, "    ldr x0, =tmpbuf");
            emitln(ftext, "    ldr x1, =joinbuf");
            emitln(ftext, "    bl strcat");
            // Duplicar resultado y almacenarlo en variable (respetando referencias)
            emitln(ftext, "    ldr x0, =tmpbuf");
            emitln(ftext, "    bl strdup");
            if (v->is_ref) {
                char stref[128]; snprintf(stref, sizeof(stref), "    sub x16, x29, #%d\n    ldr x17, [x16]\n    str x0, [x17]", v->offset); emitln(ftext, stref);
            } else {
                char stl[96]; snprintf(stl, sizeof(stl), "    sub x16, x29, #%d\n    str x0, [x16]", v->offset); emitln(ftext, stl);
            }
            return 1;
        }
        if (v->tipo == DOUBLE || v->tipo == FLOAT) {
            char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr d8, [x16]", v->offset); emitln(ftext, l1);
        } else {
            char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w19, [x16]", v->offset); emitln(ftext, l1);
        }
        TipoDato tr = emitir_eval_numerico(rhs, ftext);
        int use_fp = (v->tipo == DOUBLE || v->tipo == FLOAT || tr == DOUBLE);
        if (use_fp) {
            if (!(v->tipo == DOUBLE || v->tipo == FLOAT)) emitln(ftext, "    scvtf d8, w19");
            if (tr != DOUBLE) emitln(ftext, "    scvtf d9, w1"); else emitln(ftext, "    fmov d9, d0");
            if (op == '+') emitln(ftext, "    fadd d0, d8, d9");
            else if (op == '-') emitln(ftext, "    fsub d0, d8, d9");
            else if (op == '*') emitln(ftext, "    fmul d0, d8, d9");
            else if (op == '/') emitln(ftext, "    fdiv d0, d8, d9");
            else { emitln(ftext, "    fmov d0, d8"); emitln(ftext, "    fmov d1, d9"); emitln(ftext, "    bl fmod"); }
            char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d0, [x16]", v->offset); emitln(ftext, st);
        } else {
            if (op == '+') emitln(ftext, "    add w1, w19, w1");
            else if (op == '-') emitln(ftext, "    sub w1, w19, w1");
            else if (op == '*') emitln(ftext, "    mul w1, w19, w1");
            else if (op == '/') emitln(ftext, "    sdiv w1, w19, w1");
            else { emitln(ftext, "    sdiv w21, w19, w1"); emitln(ftext, "    msub w1, w21, w1, w19"); }
            char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w1, [x16]", v->offset); emitln(ftext, st);
        }
    }
    return 1;
}
