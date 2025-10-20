#include "codegen/arm64_num.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_globals.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "ast/nodos/expresiones/aritmeticas/aritmeticas.h"
#include <string.h>
#include <stdlib.h>
#include "ast/nodos/instrucciones/instruccion/casteos.h"
#include "codegen/arm64_print.h"
#include "codegen/estructuras/arm64_arreglos.h"
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
        if (v) {
            if (v->tipo == DOUBLE || v->tipo == FLOAT) {
                char line[96]; snprintf(line, sizeof(line), "    sub x16, x29, #%d\n    ldr d0, [x16]", v->offset); emitln(ftext, line);
                return DOUBLE;
            } else { // INT/BOOLEAN/CHAR
                char line[96]; snprintf(line, sizeof(line), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset); emitln(ftext, line);
                return INT;
            }
        }
        // Fallback: global, intentar determinar tipo
        const GlobalInfo *gi = globals_lookup(id->nombre);
        if (gi && (gi->tipo == DOUBLE || gi->tipo == FLOAT)) {
            char sym[128]; snprintf(sym, sizeof(sym), "    ldr x16, =g_%s\n    ldr d0, [x16]", id->nombre); emitln(ftext, sym);
            return DOUBLE;
        } else {
            char sym[128]; snprintf(sym, sizeof(sym), "    ldr x16, =g_%s\n    ldr w1, [x16]", id->nombre); emitln(ftext, sym);
            return INT;
        }
    } else if (strcmp(t, "ArrayAccess") == 0) {
        // Evaluar acceso a arreglo como entero (int elements)
        // Recolectar profundidad e índices
        int depth = 0; AbstractExpresion *it = node;
        while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0) { depth++; it = it->hijos[0]; }
        if (!(it && it->node_type && strcmp(it->node_type, "Identificador") == 0)) {
            emitln(ftext, "    mov w1, #0");
            return INT;
        }
        IdentificadorExpresion *id = (IdentificadorExpresion *)it;
        VarEntry *v = buscar_variable(id->nombre);
        if (!v) { emitln(ftext, "    mov w1, #0"); return INT; }
        // Determinar tipo base del arreglo si se registró
        TipoDato base_t = arm64_array_elem_tipo_for_var(id->nombre);
        int bytes = ((depth * 4) + 15) & ~15;
        if (bytes > 0) { char sub[64]; snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes); emitln(ftext, sub); }
        it = node; for (int i = 0; i < depth; ++i) {
            AbstractExpresion *idx = it->hijos[1];
            TipoDato ty = emitir_eval_numerico(idx, ftext);
            if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
            char st[64]; snprintf(st, sizeof(st), "    str w1, [sp, #%d]", i * 4); emitln(ftext, st);
            it = it->hijos[0];
        }
        if (base_t == STRING) {
            // No es numérico; retornar 0 evitando usar helper de punteros aquí
            emitln(ftext, "    mov w1, #0");
        } else {
            // x0 = arr, x1 = indices, w2 = depth
            { char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", v->offset); emitln(ftext, ld); }
            emitln(ftext, "    mov x1, sp");
            { char mv[64]; snprintf(mv, sizeof(mv), "    mov w2, #%d", depth); emitln(ftext, mv); }
            emitln(ftext, "    bl array_element_addr");
            if (base_t == CHAR) emitln(ftext, "    ldrb w1, [x0]");
            else emitln(ftext, "    ldr w1, [x0]");
        }
        if (bytes > 0) { char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb); }
        return INT;
    } else if (strcmp(t, "Suma") == 0) {
        // Guardar lhs en stack para evitar clobber en evaluaciones anidadas
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE) emitln(ftext, "    str d0, [sp]"); else emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl == DOUBLE) emitln(ftext, "    ldr d8, [sp]"); else { emitln(ftext, "    ldr w19, [sp]"); emitln(ftext, "    scvtf d8, w19"); }
            if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fadd d0, d8, d9");
            emitln(ftext, "    add sp, sp, #16");
            return DOUBLE;
        } else {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    add w1, w19, w1");
            return INT;
        }
    } else if (strcmp(t, "Resta") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE) emitln(ftext, "    str d0, [sp]"); else emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl == DOUBLE) emitln(ftext, "    ldr d8, [sp]"); else { emitln(ftext, "    ldr w19, [sp]"); emitln(ftext, "    scvtf d8, w19"); }
            if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fsub d0, d8, d9");
            emitln(ftext, "    add sp, sp, #16");
            return DOUBLE;
        } else {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    sub w1, w19, w1");
            return INT;
        }
    } else if (strcmp(t, "Multiplicacion") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE) emitln(ftext, "    str d0, [sp]"); else emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl == DOUBLE) emitln(ftext, "    ldr d8, [sp]"); else { emitln(ftext, "    ldr w19, [sp]"); emitln(ftext, "    scvtf d8, w19"); }
            if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fmul d0, d8, d9");
            emitln(ftext, "    add sp, sp, #16");
            return DOUBLE;
        } else {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    mul w1, w19, w1");
            return INT;
        }
    } else if (strcmp(t, "Division") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE) emitln(ftext, "    str d0, [sp]"); else emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl == DOUBLE) emitln(ftext, "    ldr d8, [sp]"); else { emitln(ftext, "    ldr w19, [sp]"); emitln(ftext, "    scvtf d8, w19"); }
            if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fdiv d0, d8, d9");
            emitln(ftext, "    add sp, sp, #16");
            return DOUBLE;
        } else {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    sdiv w1, w19, w1");
            return INT;
        }
    } else if (strcmp(t, "Modulo") == 0) {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE) emitln(ftext, "    str d0, [sp]"); else emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE) {
            if (tl == DOUBLE) emitln(ftext, "    ldr d8, [sp]"); else { emitln(ftext, "    ldr w19, [sp]"); emitln(ftext, "    scvtf d8, w19"); }
            if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fmov d0, d8");
            emitln(ftext, "    fmov d1, d9");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    bl fmod");
            return DOUBLE;
        } else {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    sdiv w21, w19, w1");
            emitln(ftext, "    msub w1, w21, w1, w19");
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
        // Guardar lhs entero en stack para protegerlo
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE) { emitln(ftext, "    fcvtzs w19, d0"); emitln(ftext, "    str w19, [sp]"); }
        else { emitln(ftext, "    str w1, [sp]"); }
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tr == DOUBLE) { emitln(ftext, "    fcvtzs w20, d0"); }
        else { emitln(ftext, "    mov w20, w1"); }
        emitln(ftext, "    ldr w19, [sp]");
        emitln(ftext, "    add sp, sp, #16");
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
                if (v) {
                // Cargar valor actual y guardar como retorno
                if (v->tipo == DOUBLE || v->tipo == FLOAT) {
                    char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr d0, [x16]", v->offset); emitln(ftext, ld);
                    const char *one = core_add_double_literal("1.0");
                    char l1[96]; snprintf(l1, sizeof(l1), "    ldr x16, =%s\n    ldr d1, [x16]", one); emitln(ftext, l1);
                    if (op == TOKEN_INCREMENTO) emitln(ftext, "    fadd d1, d0, d1"); else emitln(ftext, "    fsub d1, d0, d1");
                    char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d1, [x16]", v->offset); emitln(ftext, st);
                    return DOUBLE;
                } else {
                    char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset); emitln(ftext, ld);
                    if (op == TOKEN_INCREMENTO) emitln(ftext, "    add w20, w1, #1"); else emitln(ftext, "    sub w20, w1, #1");
                    char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w20, [x16]", v->offset); emitln(ftext, st);
                    return INT;
                }
            } else {
                // Postfix sobre global
                const GlobalInfo *gi = globals_lookup(id->nombre);
                if (!gi) { emitln(ftext, "    mov w1, #0"); return INT; }
                // Dirección global
                char adr[128]; snprintf(adr, sizeof(adr), "    ldr x16, =g_%s", id->nombre); emitln(ftext, adr);
                if (gi->tipo == DOUBLE || gi->tipo == FLOAT) {
                    emitln(ftext, "    ldr d0, [x16]");
                    const char *one = core_add_double_literal("1.0");
                    char l1[96]; snprintf(l1, sizeof(l1), "    ldr x17, =%s\n    ldr d1, [x17]", one); emitln(ftext, l1);
                    if (op == TOKEN_INCREMENTO) emitln(ftext, "    fadd d1, d0, d1"); else emitln(ftext, "    fsub d1, d0, d1");
                    emitln(ftext, "    str d1, [x16]");
                    return DOUBLE;
                } else {
                    emitln(ftext, "    ldr w1, [x16]");
                    if (op == TOKEN_INCREMENTO) emitln(ftext, "    add w20, w1, #1"); else emitln(ftext, "    sub w20, w1, #1");
                    emitln(ftext, "    str w20, [x16]");
                    return INT;
                }
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
    } else if (strcmp(t, "ArrayLength") == 0) {
        // child should be an array identifier; load pointer and read sizes[0]
        AbstractExpresion *arr = node->hijos[0];
        if (arr && strcmp(arr->node_type ? arr->node_type : "", "Identificador") == 0) {
            IdentificadorExpresion *id = (IdentificadorExpresion *)arr;
            VarEntry *v = buscar_variable(id->nombre);
            if (v) {
                char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", v->offset); emitln(ftext, ld);
            } else {
                char lg[128]; snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x0, [x16]", id->nombre); emitln(ftext, lg);
            }
            emitln(ftext, "    // load sizes[0] from header: [x0+8]");
            emitln(ftext, "    add x18, x0, #8");
            emitln(ftext, "    ldr w1, [x18]");
            return INT;
        }
        // Fallback: not an identifier; return 0
        emitln(ftext, "    mov w1, #0");
        return INT;
    } else if (strcmp(t, "ArraysIndexof") == 0) {
        // Arrays.indexOf(arrExpr, valExpr)
        AbstractExpresion *arr = node->hijos[0];
        AbstractExpresion *val = node->hijos[1];
        if (!(arr && strcmp(arr->node_type ? arr->node_type : "", "Identificador") == 0)) {
            emitln(ftext, "    mov w1, #-1");
            return INT;
        }
        IdentificadorExpresion *id = (IdentificadorExpresion *)arr;
        VarEntry *v = buscar_variable(id->nombre);
        // Load array pointer in x9
        if (v) {
            char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x9, [x16]", v->offset); emitln(ftext, ld);
        } else {
            char lg[128]; snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x9, [x16]", id->nombre); emitln(ftext, lg);
        }
        // Compute header and length n in w19; data base in x21
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
        // Determine base type and branch
        TipoDato base_t = arm64_array_elem_tipo_for_var(id->nombre);
        if (base_t == STRING) {
            int lid = flujo_next_label_id();
            // Evaluate search string into x23 (may be NULL)
            if (!emitir_eval_string_ptr(val, ftext)) emitln(ftext, "    mov x1, #0");
            emitln(ftext, "    mov x23, x1");
            // Loop i en w20; mantener resultado en w24; al final mover a w1
            emitln(ftext, "    mov w20, #0");
            emitln(ftext, "    mov w24, #-1");
            {
                char l[64]; snprintf(l, sizeof(l), "L_idxof_loop_s_%d:", lid); emitln(ftext, l);
            }
            emitln(ftext, "    cmp w20, w19");
            {
                char b[64]; snprintf(b, sizeof(b), "    b.ge L_idxof_done_s_%d", lid); emitln(ftext, b);
            }
            emitln(ftext, "    add x22, x21, x20, lsl #3");
            emitln(ftext, "    ldr x0, [x22]");
            emitln(ftext, "    // Compare element vs search (handle NULL)");
            emitln(ftext, "    cmp x23, #0");
            {
                char b[64]; snprintf(b, sizeof(b), "    b.eq L_cmp_null_s_%d", lid); emitln(ftext, b);
            }
            emitln(ftext, "    // strcmp(elem, search) == 0?");
            emitln(ftext, "    mov x1, x23");
            emitln(ftext, "    bl strcmp");
            emitln(ftext, "    cmp w0, #0");
            {
                char b1[64]; snprintf(b1, sizeof(b1), "    b.eq L_idxof_found_s_%d", lid); emitln(ftext, b1);
                char b2[64]; snprintf(b2, sizeof(b2), "    b L_idxof_next_s_%d", lid); emitln(ftext, b2);
            }
            {
                char l[64]; snprintf(l, sizeof(l), "L_cmp_null_s_%d:", lid); emitln(ftext, l);
            }
            emitln(ftext, "    cmp x0, #0");
            {
                char b[64]; snprintf(b, sizeof(b), "    b.eq L_idxof_found_s_%d", lid); emitln(ftext, b);
            }
            {
                char l[64]; snprintf(l, sizeof(l), "L_idxof_next_s_%d:", lid); emitln(ftext, l);
            }
            emitln(ftext, "    add w20, w20, #1");
            {
                char b[64]; snprintf(b, sizeof(b), "    b L_idxof_loop_s_%d", lid); emitln(ftext, b);
            }
            {
                char l[64]; snprintf(l, sizeof(l), "L_idxof_found_s_%d:", lid); emitln(ftext, l);
            }
            emitln(ftext, "    mov w24, w20");
            {
                char l[64]; snprintf(l, sizeof(l), "L_idxof_done_s_%d:", lid); emitln(ftext, l);
            }
            // Mover resultado a w1 para el consumidor
            emitln(ftext, "    mov w1, w24");
            return INT;
        } else {
            int lid = flujo_next_label_id();
            // Treat as 4-byte ints (covers INT/BOOLEAN/CHAR by numeric compare)
            TipoDato vty = emitir_eval_numerico(val, ftext);
            if (vty == DOUBLE) emitln(ftext, "    fcvtzs w22, d0"); else emitln(ftext, "    mov w22, w1");
            emitln(ftext, "    mov w20, #0");
            emitln(ftext, "    mov w24, #-1");
            {
                char l[64]; snprintf(l, sizeof(l), "L_idxof_loop_i_%d:", lid); emitln(ftext, l);
            }
            emitln(ftext, "    cmp w20, w19");
            {
                char b[64]; snprintf(b, sizeof(b), "    b.ge L_idxof_done_i_%d", lid); emitln(ftext, b);
            }
            // Use x14 as the element address to avoid clobbering w22 (search value)
            emitln(ftext, "    add x14, x21, x20, lsl #2");
            emitln(ftext, "    ldr w0, [x14]");
            emitln(ftext, "    cmp w0, w22");
            {
                char b[64]; snprintf(b, sizeof(b), "    b.eq L_idxof_found_i_%d", lid); emitln(ftext, b);
            }
            emitln(ftext, "    add w20, w20, #1");
            {
                char b[64]; snprintf(b, sizeof(b), "    b L_idxof_loop_i_%d", lid); emitln(ftext, b);
            }
            {
                char l[64]; snprintf(l, sizeof(l), "L_idxof_found_i_%d:", lid); emitln(ftext, l);
            }
            emitln(ftext, "    mov w24, w20");
            {
                char l[64]; snprintf(l, sizeof(l), "L_idxof_done_i_%d:", lid); emitln(ftext, l);
            }
            // Mover resultado a w1 para el consumidor
            emitln(ftext, "    mov w1, w24");
            return INT;
        }
    }
    emitln(ftext, "    mov w1, #0");
    return INT;
}
