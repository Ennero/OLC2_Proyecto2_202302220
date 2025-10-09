#include "codegen/arm64_num.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "ast/nodos/expresiones/aritmeticas/aritmeticas.h"
#include <string.h>
#include <stdlib.h>
#include "ast/nodos/instrucciones/instruccion/casteos.h"
#include "codegen/arm64_print.h"
#include "ast/nodos/expresiones/postfix.h"
#include "parser.tab.h" // tokens for ++/--

// Shorthand to match arm64_codegen.c helpers
static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }

TipoDato emitir_eval_numerico(AbstractExpresion *node, FILE *ftext) {
    const char *t = node->node_type ? node->node_type : "";
    if (strcmp(t, "Primitivo") == 0) {
        PrimitivoExpresion *p = (PrimitivoExpresion *)node;
        if (p->tipo == INT || p->tipo == BOOLEAN || p->tipo == CHAR) {
            long v = 0;
            if (p->valor) {
                if (p->tipo == INT) {
                    if (strncmp(p->valor, "0x", 2) == 0 || strncmp(p->valor, "0X", 2) == 0)
                        v = strtol(p->valor, NULL, 16);
                    else v = strtol(p->valor, NULL, 10);
                } else if (p->tipo == BOOLEAN) {
                    v = (strcmp(p->valor, "true") == 0);
                } else { // CHAR con soporte de escapes y \u decimal
                    const char *s = p->valor;
                    size_t n = strlen(s);
                    int cp = 0;
                    if (n >= 2 && s[0] == '\\') {
                        switch (s[1]) {
                            case 'n': cp = '\n'; break;
                            case 't': cp = '\t'; break;
                            case 'r': cp = '\r'; break;
                            case '\\': cp = '\\'; break;
                            case '"': cp = '"'; break;
                            case '\'': cp = '\''; break;
                            case 'u': {
                                // Leer hasta 5 dígitos decimales después de \u
                                int val = 0; size_t i = 2; size_t cnt = 0;
                                while (i < n && cnt < 5 && s[i] >= '0' && s[i] <= '9') { val = val*10 + (s[i]-'0'); i++; cnt++; }
                                if (val < 0) val = 0; if (val > 0x10FFFF) val = 0x10FFFF;
                                cp = val; break;
                            }
                            default: cp = (unsigned char)s[1]; break;
                        }
                    } else {
                        cp = (unsigned char)s[0];
                    }
                    v = cp;
                }
            }
            char line[64]; snprintf(line, sizeof(line), "    mov w1, #%ld", v); emitln(ftext, line);
            return INT;
        } else if (p->tipo == DOUBLE || p->tipo == FLOAT) {
            const char *lab = core_add_double_literal(p->valor ? p->valor : "0");
            char ref[128]; snprintf(ref, sizeof(ref), "    ldr x16, =%s\n    ldr d0, [x16]", lab); emitln(ftext, ref);
            return DOUBLE;
        }
    } else if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = buscar_variable(id->nombre);
        if (!v) return INT;
        if (v->tipo == DOUBLE || v->tipo == FLOAT) {
            char line[64]; snprintf(line, sizeof(line), "    ldr d0, [x29, -%d]", v->offset); emitln(ftext, line);
            return DOUBLE;
        } else { // INT/BOOLEAN/CHAR
            char line[64]; snprintf(line, sizeof(line), "    ldr w1, [x29, -%d]", v->offset); emitln(ftext, line);
            return INT;
        }
    } else if (strcmp(t, "Suma") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        if (tl == DOUBLE) emitln(ftext, "    fmov d8, d0"); else emitln(ftext, "    mov w19, w1");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    mov w20, w1");
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl != DOUBLE) emitln(ftext, "    scvtf d8, w19");
            if (tr != DOUBLE) emitln(ftext, "    scvtf d9, w20");
            emitln(ftext, "    fadd d0, d8, d9");
            return DOUBLE;
        } else {
            emitln(ftext, "    add w1, w19, w20");
            return INT;
        }
    } else if (strcmp(t, "Resta") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        if (tl == DOUBLE) emitln(ftext, "    fmov d8, d0"); else emitln(ftext, "    mov w19, w1");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    mov w20, w1");
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl != DOUBLE) emitln(ftext, "    scvtf d8, w19");
            if (tr != DOUBLE) emitln(ftext, "    scvtf d9, w20");
            emitln(ftext, "    fsub d0, d8, d9");
            return DOUBLE;
        } else {
            emitln(ftext, "    sub w1, w19, w20");
            return INT;
        }
    } else if (strcmp(t, "Multiplicacion") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        if (tl == DOUBLE) emitln(ftext, "    fmov d8, d0"); else emitln(ftext, "    mov w19, w1");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    mov w20, w1");
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl != DOUBLE) emitln(ftext, "    scvtf d8, w19");
            if (tr != DOUBLE) emitln(ftext, "    scvtf d9, w20");
            emitln(ftext, "    fmul d0, d8, d9");
            return DOUBLE;
        } else {
            emitln(ftext, "    mul w1, w19, w20");
            return INT;
        }
    } else if (strcmp(t, "Division") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        if (tl == DOUBLE) emitln(ftext, "    fmov d8, d0"); else emitln(ftext, "    mov w19, w1");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    mov w20, w1");
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl != DOUBLE) emitln(ftext, "    scvtf d8, w19");
            if (tr != DOUBLE) emitln(ftext, "    scvtf d9, w20");
            emitln(ftext, "    fdiv d0, d8, d9");
            return DOUBLE;
        } else {
            emitln(ftext, "    sdiv w1, w19, w20");
            return INT;
        }
    } else if (strcmp(t, "Modulo") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        if (tl == DOUBLE) emitln(ftext, "    fmov d8, d0"); else emitln(ftext, "    mov w19, w1");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    mov w20, w1");
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl != DOUBLE) emitln(ftext, "    scvtf d8, w19");
            if (tr != DOUBLE) emitln(ftext, "    scvtf d9, w20");
            emitln(ftext, "    fmov d0, d8");
            emitln(ftext, "    fmov d1, d9");
            emitln(ftext, "    bl fmod");
            return DOUBLE;
        } else {
            emitln(ftext, "    sdiv w21, w19, w20");
            emitln(ftext, "    msub w1, w21, w20, w19");
            return INT;
        }
    } else if (strcmp(t, "NegacionUnaria") == 0) {
        TipoDato ty = emitir_eval_numerico(node->hijos[0], ftext);
        if (ty == DOUBLE) {
            emitln(ftext, "    fneg d0, d0");
            return DOUBLE;
        } else {
            emitln(ftext, "    neg w1, w1");
            return INT;
        }
    } else if (strcmp(t, "BitwiseAnd") == 0 || strcmp(t, "BitwiseOr") == 0 || strcmp(t, "BitwiseXor") == 0 ||
               strcmp(t, "LeftShift") == 0 || strcmp(t, "RightShift") == 0 || strcmp(t, "UnsignedRightShift") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        if (tl == DOUBLE) {
            emitln(ftext, "    fcvtzs w19, d0");
        } else {
            emitln(ftext, "    mov w19, w1");
        }
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tr == DOUBLE) {
            emitln(ftext, "    fcvtzs w20, d0");
        } else {
            emitln(ftext, "    mov w20, w1");
        }
        if (strcmp(t, "BitwiseAnd") == 0) emitln(ftext, "    and w1, w19, w20");
        else if (strcmp(t, "BitwiseOr") == 0) emitln(ftext, "    orr w1, w19, w20");
        else if (strcmp(t, "BitwiseXor") == 0) emitln(ftext, "    eor w1, w19, w20");
        else if (strcmp(t, "LeftShift") == 0) emitln(ftext, "    lsl w1, w19, w20");
        else if (strcmp(t, "RightShift") == 0) emitln(ftext, "    asr w1, w19, w20");
        else /* UnsignedRightShift */ emitln(ftext, "    lsr w1, w19, w20");
        return INT;
    } else if (strcmp(t, "BitwiseNot") == 0) {
        TipoDato ty = emitir_eval_numerico(node->hijos[0], ftext);
        if (ty == DOUBLE) {
            emitln(ftext, "    fcvtzs w1, d0");
        }
        emitln(ftext, "    mvn w1, w1");
        return INT;
    } else if (strcmp(t, "Casteo") == 0) {
        // Casteo explícito entre tipos numéricos
        CasteoExpresion *c = (CasteoExpresion *)node;
        TipoDato dest = c->tipo_destino;
        // Evaluar hijo
        TipoDato from = emitir_eval_numerico(node->hijos[0], ftext);
        // Normalizar conversiones
        if (dest == DOUBLE || dest == FLOAT) {
            // Producir d0
            if (from != DOUBLE) {
                // w1 -> d0
                emitln(ftext, "    scvtf d0, w1");
            }
            return DOUBLE;
        } else if (dest == INT || dest == CHAR) {
            // Producir w1
            if (from == DOUBLE) {
                emitln(ftext, "    fcvtzs w1, d0");
            }
            return INT;
        } else if (dest == BOOLEAN) {
            // booleano 0/1 en w1
            if (from == DOUBLE) {
                emitln(ftext, "    fcmp d0, #0.0");
                emitln(ftext, "    cset w1, ne");
            } else {
                emitln(ftext, "    cmp w1, #0");
                emitln(ftext, "    cset w1, ne");
            }
            return INT;
        }
        // Otros casteos (STRING) no soportados en codegen numérico; retornar 0
        emitln(ftext, "    mov w1, #0");
        return INT;
    } else if (strcmp(t, "Postfix") == 0) {
        // Postfix ++ / -- sobre identificadores (MVP). Devuelve valor antiguo y escribe el nuevo.
        AbstractExpresion *lvalue = node->hijos[0];
        int op = postfix_get_op(node);
        if (lvalue && strcmp(lvalue->node_type ? lvalue->node_type : "", "Identificador") == 0) {
            IdentificadorExpresion *id = (IdentificadorExpresion *)lvalue;
            VarEntry *v = buscar_variable(id->nombre);
            if (!v) { emitln(ftext, "    mov w1, #0"); return INT; }
            // Cargar valor actual y guardar como retorno
            if (v->tipo == DOUBLE || v->tipo == FLOAT) {
                char ld[64]; snprintf(ld, sizeof(ld), "    ldr d0, [x29, -%d]", v->offset); emitln(ftext, ld);
                // devolver antiguo en d0
                // calcular nuevo
                // cargar constante 1.0 en d1
                const char *one = core_add_double_literal("1.0");
                char l1[96]; snprintf(l1, sizeof(l1), "    ldr x16, =%s\n    ldr d1, [x16]", one); emitln(ftext, l1);
                if (op == TOKEN_INCREMENTO) emitln(ftext, "    fadd d1, d0, d1"); else emitln(ftext, "    fsub d1, d0, d1");
                char st[64]; snprintf(st, sizeof(st), "    str d1, [x29, -%d]", v->offset); emitln(ftext, st);
                return DOUBLE;
            } else {
                char ld[64]; snprintf(ld, sizeof(ld), "    ldr w1, [x29, -%d]", v->offset); emitln(ftext, ld);
                // w1 contiene antiguo (retorno)
                // calcular nuevo en w20
                if (op == TOKEN_INCREMENTO) emitln(ftext, "    add w20, w1, #1"); else emitln(ftext, "    sub w20, w1, #1");
                char st[64]; snprintf(st, sizeof(st), "    str w20, [x29, -%d]", v->offset); emitln(ftext, st);
                return INT;
            }
        } else {
            // TODO: soporte a ArrayAccess
            emitln(ftext, "    // TODO Postfix sobre arreglos no implementado");
            emitln(ftext, "    mov w1, #0");
            return INT;
        }
    } else if (strcmp(t, "ParseInt") == 0) {
        emitir_parse_int(node->hijos[0], ftext);
        return INT;
    } else if (strcmp(t, "ParseFloat") == 0) {
        emitir_parse_float(node->hijos[0], ftext);
        return DOUBLE; // usamos d0
    } else if (strcmp(t, "ParseDouble") == 0) {
        emitir_parse_double(node->hijos[0], ftext);
        return DOUBLE;
    }
    emitln(ftext, "    mov w1, #0");
    return INT;
}
