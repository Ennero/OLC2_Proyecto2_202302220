#include "codegen/instrucciones/arm64_print_stmt.h"
#include <string.h>
#include <stdlib.h>
#include "codegen/arm64_core.h"
#include "codegen/arm64_print.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_globals.h"
#include "ast/nodos/instrucciones/instruccion/print.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "ast/nodos/instrucciones/instruccion/casteos.h"

static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry; static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }
static const char *add_string_literal(const char *text) { return core_add_string_literal(text); }

int arm64_emitir_print_stmt(AbstractExpresion *node, FILE *ftext) {
    if (!(node && node->node_type && strcmp(node->node_type, "Print") == 0)) return 0;
    AbstractExpresion *lista = node->hijos[0];
    {
        char cm[256];
        snprintf(cm, sizeof(cm), "    // Print lista node_type: %s, numHijos=%zu", lista && lista->node_type ? lista->node_type : "<null>", lista ? lista->numHijos : 0);
        emitln(ftext, cm);
    }
    for (size_t i = 0; i < (lista ? lista->numHijos : 0); i++) {
        AbstractExpresion *expr = lista->hijos[i];
        {
            char cm[256];
            snprintf(cm, sizeof(cm), "    // print expr node_type: %s", expr && expr->node_type ? expr->node_type : "<null>");
            emitln(ftext, cm);
        }
        if (expr->node_type && strcmp(expr->node_type, "StringValueof") == 0) {
            emitir_imprimir_cadena(expr, ftext);
        } else if (expresion_es_cadena(expr)) {
            emitir_imprimir_cadena(expr, ftext);
        } else if (expr->node_type && strcmp(expr->node_type, "Primitivo") == 0) {
            PrimitivoExpresion *p = (PrimitivoExpresion *)expr;
            switch (p->tipo) {
                case INT: {
                    emitln(ftext, "    // print int");
                    emitln(ftext, "    ldr x0, =fmt_int");
                    long v = 0; if (p->valor) { if (strncmp(p->valor, "0x", 2) == 0 || strncmp(p->valor, "0X", 2) == 0) v = strtol(p->valor, NULL, 16); else v = strtol(p->valor, NULL, 10); }
                    char line[64]; snprintf(line, sizeof(line), "    mov w1, #%ld", v); emitln(ftext, line);
                    emitln(ftext, "    bl printf");
                    break; }
                case FLOAT:
                case DOUBLE: {
                    emitln(ftext, "    // print double");
                    emitln(ftext, "    ldr x0, =fmt_double");
                    const char *lab = core_add_double_literal(p->valor ? p->valor : "0");
                    char ref[128]; snprintf(ref, sizeof(ref), "    ldr x16, =%s\n    ldr d0, [x16]", lab); emitln(ftext, ref);
                    emitln(ftext, "    bl printf");
                    break; }
                case BOOLEAN: {
                    emitln(ftext, "    // print boolean");
                    emitln(ftext, "    ldr x0, =fmt_string");
                    int is_true = (p->valor && strcmp(p->valor, "true") == 0);
                    emitln(ftext, is_true ? "    ldr x1, =true_str" : "    ldr x1, =false_str");
                    emitln(ftext, "    bl printf");
                    break; }
                case CHAR: {
                    emitln(ftext, "    // print char");
                    emitln(ftext, "    ldr x0, =fmt_char");
                    int v = 0; if (p->valor && p->valor[0] == '\\' && p->valor[1]) { if (p->valor[1] == 'u') { const char *s = p->valor; size_t n = strlen(s); int val = 0; size_t i = 2, cnt = 0; while (i < n && cnt < 5 && s[i] >= '0' && s[i] <= '9') { val = val*10 + (s[i]-'0'); i++; cnt++; } if (val < 0) val = 0; if (val > 0x10FFFF) val = 0x10FFFF; v = val; } else { switch (p->valor[1]) { case 'n': v = '\n'; break; case 't': v = '\t'; break; case 'r': v = '\r'; break; case '\\': v = '\\'; break; case '\'': v = '\''; break; case '"': v = '"'; break; default: v = (unsigned char)p->valor[1]; break; } } } else { v = p->valor && p->valor[0] ? (unsigned char)p->valor[0] : 0; }
                    char line[64]; snprintf(line, sizeof(line), "    mov w1, #%d", v); emitln(ftext, line);
                    emitln(ftext, "    bl printf");
                    break; }
                case STRING:
                default: {
                    emitln(ftext, "    // print string");
                    emitln(ftext, "    ldr x0, =fmt_string");
                    const char *label = add_string_literal(p->valor ? p->valor : "");
                    char line[64]; snprintf(line, sizeof(line), "    ldr x1, =%s", label); emitln(ftext, line);
                    emitln(ftext, "    bl printf");
                    break; }
            }
        } else if (expr->node_type && strcmp(expr->node_type, "Identificador") == 0) {
            IdentificadorExpresion *id = (IdentificadorExpresion *)expr;
            VarEntry *v = buscar_variable(id->nombre);
            if (v) {
                if (v->tipo == DOUBLE || v->tipo == FLOAT) {
                    char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr d0, [x16]", v->offset); emitln(ftext, l1);
                    emitln(ftext, "    ldr x19, =tmpbuf");
                    emitln(ftext, "    mov x0, x19");
                    emitln(ftext, "    mov x1, #1024");
                    emitln(ftext, "    bl java_format_double");
                    emitln(ftext, "    ldr x0, =fmt_string");
                    emitln(ftext, "    mov x1, x19");
                    emitln(ftext, "    bl printf");
                } else if (v->tipo == STRING) {
                    const char *null_lab = add_string_literal("null");
                    char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr x1, [x16]", v->offset); emitln(ftext, l1);
                    emitln(ftext, "    cmp x1, #0");
                    char lnull[64]; snprintf(lnull, sizeof(lnull), "    ldr x16, =%s", null_lab); emitln(ftext, lnull);
                    emitln(ftext, "    csel x1, x16, x1, eq");
                    emitln(ftext, "    ldr x0, =fmt_string");
                    emitln(ftext, "    bl printf");
                } else if (v->tipo == CHAR) {
                    char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset); emitln(ftext, l1);
                    emitln(ftext, "    mov w0, w1");
                    emitln(ftext, "    bl char_to_utf8");
                    emitln(ftext, "    mov x1, x0");
                    emitln(ftext, "    ldr x0, =fmt_string");
                    emitln(ftext, "    bl printf");
                } else if (v->tipo == BOOLEAN) {
                    char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset); emitln(ftext, l1);
                    emitln(ftext, "    cmp w1, #0");
                    emitln(ftext, "    ldr x1, =false_str");
                    emitln(ftext, "    ldr x16, =true_str");
                    emitln(ftext, "    csel x1, x16, x1, ne");
                    emitln(ftext, "    ldr x0, =fmt_string");
                    emitln(ftext, "    bl printf");
                } else {
                    char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset); emitln(ftext, l1);
                    emitln(ftext, "    ldr x0, =fmt_int");
                    emitln(ftext, "    bl printf");
                }
            } else {
                const GlobalInfo *gi = globals_lookup(id->nombre);
                if (gi) {
                    if (gi->tipo == DOUBLE || gi->tipo == FLOAT) {
                        char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr d0, [x16]", id->nombre); emitln(ftext, l1);
                        emitln(ftext, "    ldr x19, =tmpbuf");
                        emitln(ftext, "    mov x0, x19");
                        emitln(ftext, "    mov x1, #1024");
                        emitln(ftext, "    bl java_format_double");
                        emitln(ftext, "    ldr x0, =fmt_string");
                        emitln(ftext, "    mov x1, x19");
                        emitln(ftext, "    bl printf");
                    } else if (gi->tipo == STRING) {
                        const char *null_lab = add_string_literal("null");
                        char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr x1, [x16]", id->nombre); emitln(ftext, l1);
                        emitln(ftext, "    cmp x1, #0");
                        char lnull[64]; snprintf(lnull, sizeof(lnull), "    ldr x16, =%s", null_lab); emitln(ftext, lnull);
                        emitln(ftext, "    csel x1, x16, x1, eq");
                        emitln(ftext, "    ldr x0, =fmt_string");
                        emitln(ftext, "    bl printf");
                    } else if (gi->tipo == CHAR) {
                        char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr w1, [x16]", id->nombre); emitln(ftext, l1);
                        emitln(ftext, "    mov w0, w1");
                        emitln(ftext, "    bl char_to_utf8");
                        emitln(ftext, "    mov x1, x0");
                        emitln(ftext, "    ldr x0, =fmt_string");
                        emitln(ftext, "    bl printf");
                    } else if (gi->tipo == BOOLEAN) {
                        char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr w1, [x16]", id->nombre); emitln(ftext, l1);
                        emitln(ftext, "    cmp w1, #0");
                        emitln(ftext, "    ldr x1, =false_str");
                        emitln(ftext, "    ldr x17, =true_str");
                        emitln(ftext, "    csel x1, x17, x1, ne");
                        emitln(ftext, "    ldr x0, =fmt_string");
                        emitln(ftext, "    bl printf");
                    } else {
                        char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr w1, [x16]", id->nombre); emitln(ftext, l1);
                        emitln(ftext, "    ldr x0, =fmt_int");
                        emitln(ftext, "    bl printf");
                    }
                } else {
                    char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr w1, [x16]", id->nombre); emitln(ftext, l1);
                    emitln(ftext, "    ldr x0, =fmt_int");
                    emitln(ftext, "    bl printf");
                }
            }
        } else if (expr->node_type && (strcmp(expr->node_type, "Suma") == 0 || strcmp(expr->node_type, "Resta") == 0 || strcmp(expr->node_type, "Multiplicacion") == 0 || strcmp(expr->node_type, "Division") == 0 || strcmp(expr->node_type, "Modulo") == 0 || strcmp(expr->node_type, "NegacionUnaria") == 0)) {
            TipoDato ty = emitir_eval_numerico(expr, ftext);
            if (ty == DOUBLE) emitln(ftext, "    ldr x0, =fmt_double"); else emitln(ftext, "    ldr x0, =fmt_int");
            emitln(ftext, "    bl printf");
        } else if (expr->node_type && strcmp(expr->node_type, "Casteo") == 0) {
            CasteoExpresion *c = (CasteoExpresion *)expr;
            TipoDato ty = emitir_eval_numerico(expr, ftext);
            if (c->tipo_destino == CHAR) {
                emitln(ftext, "    mov w0, w1");
                emitln(ftext, "    bl char_to_utf8");
                emitln(ftext, "    mov x1, x0");
                emitln(ftext, "    ldr x0, =fmt_string");
            } else if (c->tipo_destino == BOOLEAN) {
                emitln(ftext, "    cmp w1, #0");
                emitln(ftext, "    ldr x1, =false_str");
                emitln(ftext, "    ldr x16, =true_str");
                emitln(ftext, "    csel x1, x16, x1, ne");
                emitln(ftext, "    ldr x0, =fmt_string");
            } else {
                if (ty == DOUBLE || c->tipo_destino == DOUBLE || c->tipo_destino == FLOAT) emitln(ftext, "    ldr x0, =fmt_double"); else emitln(ftext, "    ldr x0, =fmt_int");
            }
            emitln(ftext, "    bl printf");
        } else if (expr->node_type && nodo_es_resultado_booleano(expr)) {
            emitir_eval_booleano(expr, ftext);
            emitln(ftext, "    cmp w1, #0");
            emitln(ftext, "    ldr x1, =false_str");
            emitln(ftext, "    ldr x16, =true_str");
            emitln(ftext, "    csel x1, x16, x1, ne");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    bl printf");
        } else {
            TipoDato ty = emitir_eval_numerico(expr, ftext);
            if (ty == DOUBLE) emitln(ftext, "    ldr x0, =fmt_double"); else emitln(ftext, "    ldr x0, =fmt_int");
            emitln(ftext, "    bl printf");
        }
        if (i + 1 < (lista ? lista->numHijos : 0)) {
            const char *lab = add_string_literal(" ");
            emitln(ftext, "    ldr x0, =fmt_string");
            char l2[64]; snprintf(l2, sizeof(l2), "    ldr x1, =%s", lab); emitln(ftext, l2);
            emitln(ftext, "    bl printf");
        }
    }
    const char *nl = add_string_literal("\n");
    emitln(ftext, "    ldr x0, =fmt_string");
    { char l2[64]; snprintf(l2, sizeof(l2), "    ldr x1, =%s", nl); emitln(ftext, l2); }
    emitln(ftext, "    bl printf");
    return 1;
}
