#include "codegen/arm64_print.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_globals.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "ast/nodos/instrucciones/instruccion/casteos.h"
#include <string.h>
#include <stdlib.h>

static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }
static const char *add_string_literal(const char *text) { return core_add_string_literal(text); }

int expresion_es_cadena(AbstractExpresion *node) {
    if (!node) return 0;
    const char *t = node->node_type ? node->node_type : "";
    if (strcmp(t, "Primitivo") == 0) {
        PrimitivoExpresion *p = (PrimitivoExpresion *)node;
        return p->tipo == STRING;
    }
    if (strcmp(t, "StringValueof") == 0) {
        return 1;
    }
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = buscar_variable(id->nombre);
        return v && v->tipo == STRING;
    }
    if (strcmp(t, "Suma") == 0) {
        return expresion_es_cadena(node->hijos[0]) || expresion_es_cadena(node->hijos[1]);
    }
    return 0;
}

// Helpers para funciones embebidas sencillas
// ParseInt/Float/Double aceptan un string; retornan en w1 (int) o d0 (double)
void emitir_parse_int(AbstractExpresion *arg, FILE *ftext) {
    if (!emitir_eval_string_ptr(arg, ftext)) {
        emitln(ftext, "    mov w1, #0");
        return;
    }
    // strtol(x1, x2=NULL, base=10) -> x0
    emitln(ftext, "    mov x0, x1");
    emitln(ftext, "    mov x1, #0");
    emitln(ftext, "    mov w2, #10");
    emitln(ftext, "    bl strtol");
    emitln(ftext, "    mov w1, w0");
}

void emitir_parse_float(AbstractExpresion *arg, FILE *ftext) {
    if (!emitir_eval_string_ptr(arg, ftext)) { emitln(ftext, "    fmov d0, xzr"); return; }
    emitln(ftext, "    mov x0, x1");
    emitln(ftext, "    mov x1, #0");
    emitln(ftext, "    bl strtof");
    // strtof returns float in s0; move to d0 preserving value
    emitln(ftext, "    fcvt d0, s0");
}

void emitir_parse_double(AbstractExpresion *arg, FILE *ftext) {
    if (!emitir_eval_string_ptr(arg, ftext)) { emitln(ftext, "    fmov d0, xzr"); return; }
    emitln(ftext, "    mov x0, x1");
    emitln(ftext, "    mov x1, #0");
    emitln(ftext, "    bl strtod");
    // strtod returns double in d0
}

// String.valueOf: para MVP retornamos un string nuevo usando printf a buffer simple con sprintf
// Sujeto a fugas controladas: asumimos que el caller sólo imprime o concatena de inmediato
static const char *alloc_fmt_label_for_tipo(TipoDato t) {
    switch (t) {
        case INT: return "fmt_int";
        case DOUBLE:
        case FLOAT: return "fmt_double";
        case BOOLEAN: return "fmt_string"; // true/false
        case CHAR: return "fmt_char";
        case STRING: return "fmt_string";
        default: return "fmt_string";
    }
}

// Emite en x1 el puntero a una cadena representando expr
void emitir_string_valueof(AbstractExpresion *arg, FILE *ftext) {
    // Para boolean, reutilizamos la lógica de impresión booleana para elegir true/false
    const char *t = arg->node_type ? arg->node_type : "";

    // 1) Si el resultado es booleano (expresión relacional/lógica), mapear a true/false
    if (nodo_es_resultado_booleano(arg)) {
        emitir_eval_booleano(arg, ftext);
        emitln(ftext, "    cmp w1, #0");
        emitln(ftext, "    ldr x1, =false_str");
        emitln(ftext, "    ldr x16, =true_str");
        emitln(ftext, "    csel x1, x16, x1, ne");
        return;
    }

    // 2.1) Identificador booleano (variable local/global)
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)arg;
        VarEntry *v = buscar_variable(id->nombre);
        if (v && v->tipo == BOOLEAN) {
            char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset); emitln(ftext, l1);
            emitln(ftext, "    cmp w1, #0");
            emitln(ftext, "    ldr x1, =false_str");
            emitln(ftext, "    ldr x16, =true_str");
            emitln(ftext, "    csel x1, x16, x1, ne");
            return;
        }
        // Fallback a global booleano
        const GlobalInfo *gi = globals_lookup(id->nombre);
        if (gi && gi->tipo == BOOLEAN) {
            char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr w1, [x16]", id->nombre); emitln(ftext, l1);
            emitln(ftext, "    cmp w1, #0");
            emitln(ftext, "    ldr x1, =false_str");
            emitln(ftext, "    ldr x16, =true_str");
            emitln(ftext, "    csel x1, x16, x1, ne");
            return;
        }
    }

    // 2) Literal booleano
    if (strcmp(t, "Primitivo") == 0 && ((PrimitivoExpresion*)arg)->tipo == BOOLEAN) {
        PrimitivoExpresion *p = (PrimitivoExpresion*)arg;
        int is_true = (p->valor && strcmp(p->valor, "true") == 0);
        emitln(ftext, is_true ? "    ldr x1, =true_str" : "    ldr x1, =false_str");
        return;
    }

    // 3) Si ya es cadena (literal, id string, concatenación), evalúalo como puntero a string
    if (expresion_es_cadena(arg)) {
        const char *null_lab = add_string_literal("null");
        if (!emitir_eval_string_ptr(arg, ftext)) {
            // Si no se pudo evaluar como string, retornar "null"
            char lz[64]; snprintf(lz, sizeof(lz), "    ldr x1, =%s", null_lab); emitln(ftext, lz);
            return;
        }
        // Si el puntero es NULL, sustituir por "null"
        emitln(ftext, "    cmp x1, #0");
        char l2[64]; snprintf(l2, sizeof(l2), "    ldr x16, =%s", null_lab); emitln(ftext, l2);
        emitln(ftext, "    csel x1, x16, x1, eq");
        return;
    }

    // 4) Resto: numérico o char (incluye identificadores no booleanos)
    int is_char = 0;
    if (strcmp(t, "Primitivo") == 0) {
        PrimitivoExpresion *p = (PrimitivoExpresion *)arg;
        is_char = (p->tipo == CHAR);
    } else if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)arg;
        VarEntry *v = buscar_variable(id->nombre);
        is_char = (v && v->tipo == CHAR);
    }

    TipoDato ty = emitir_eval_numerico(arg, ftext);
    if (is_char) {
        // char -> UTF-8
        if (ty == DOUBLE) {
            // convertir double->int para caracteres
            emitln(ftext, "    fcvtzs w21, d0");
        } else {
            emitln(ftext, "    mov w21, w1");
        }
        emitln(ftext, "    ldr x19, =tmpbuf");
        emitln(ftext, "    mov x0, x19");
        // Convertir code point a UTF-8 y devolver puntero en x1
        emitln(ftext, "    mov w0, w21");
        emitln(ftext, "    bl char_to_utf8");
        emitln(ftext, "    mov x1, x0");
    } else {
        if (ty == DOUBLE) {
            // Usar formateo Java-like para doubles: java_format_double(d0, tmpbuf, 1024)
            emitln(ftext, "    ldr x19, =tmpbuf");
            emitln(ftext, "    mov x0, x19");
            emitln(ftext, "    mov x1, #1024");
            emitln(ftext, "    bl java_format_double");
            emitln(ftext, "    mov x1, x19");
        } else {
            // Enteros: sprintf a tmpbuf con %d
            emitln(ftext, "    mov w21, w1");
            emitln(ftext, "    ldr x19, =tmpbuf");
            emitln(ftext, "    mov x0, x19");
            emitln(ftext, "    ldr x1, =fmt_int");
            emitln(ftext, "    mov w2, w21");
            emitln(ftext, "    bl sprintf");
            emitln(ftext, "    mov x1, x19");
        }
    }
}

void emitir_imprimir_cadena(AbstractExpresion *node, FILE *ftext) {
    const char *t = node->node_type ? node->node_type : "";
    if (strcmp(t, "Suma") == 0) {
        if (!expresion_es_cadena(node)) {
            TipoDato ty = emitir_eval_numerico(node, ftext);
            if (ty == DOUBLE) {
                // double -> formatear con java_format_double y luego imprimir como string
                emitln(ftext, "    ldr x19, =tmpbuf");
                emitln(ftext, "    mov x0, x19");
                emitln(ftext, "    mov x1, #1024");
                emitln(ftext, "    bl java_format_double");
                emitln(ftext, "    ldr x0, =fmt_string");
                emitln(ftext, "    mov x1, x19");
            } else {
                emitln(ftext, "    ldr x0, =fmt_int");
            }
            emitln(ftext, "    bl printf");
            return;
        }
        emitir_imprimir_cadena(node->hijos[0], ftext);
        emitir_imprimir_cadena(node->hijos[1], ftext);
        return;
    }
    if (strcmp(t, "StringValueof") == 0) {
        // Evaluar a puntero string y imprimir
        if (!emitir_eval_string_ptr(node, ftext)) {
            // no pudo evaluarse como string
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    ldr x1, =false_str");
        }
        emitln(ftext, "    ldr x0, =fmt_string");
        emitln(ftext, "    bl printf");
        return;
    }
    if (strcmp(t, "Primitivo") == 0) {
        PrimitivoExpresion *p = (PrimitivoExpresion *)node;
        if (p->tipo == STRING) {
            const char *lab = add_string_literal(p->valor ? p->valor : "");
            emitln(ftext, "    ldr x0, =fmt_string");
            char l2[64]; snprintf(l2, sizeof(l2), "    ldr x1, =%s", lab); emitln(ftext, l2);
            emitln(ftext, "    bl printf");
            return;
        } else if (p->tipo == CHAR) {
            // Imprimir caracter como UTF-8 usando helper
            (void)emitir_eval_numerico(node, ftext);
            emitln(ftext, "    mov w0, w1");
            emitln(ftext, "    bl char_to_utf8");
            emitln(ftext, "    mov x1, x0");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    bl printf");
            return;
        } else if (p->tipo == BOOLEAN) {
            // Mapear a true/false
            emitir_eval_booleano(node, ftext);
            emitln(ftext, "    cmp w1, #0");
            emitln(ftext, "    ldr x1, =false_str");
            emitln(ftext, "    ldr x16, =true_str");
            emitln(ftext, "    csel x1, x16, x1, ne");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    bl printf");
            return;
        } else if (p->tipo == INT) {
            (void)emitir_eval_numerico(node, ftext);
            emitln(ftext, "    ldr x0, =fmt_int");
            emitln(ftext, "    bl printf");
            return;
        } else {
            // DOUBLE/FLOAT -> usar java_format_double
            (void)emitir_eval_numerico(node, ftext);
            emitln(ftext, "    ldr x19, =tmpbuf");
            emitln(ftext, "    mov x0, x19");
            emitln(ftext, "    mov x1, #1024");
            emitln(ftext, "    bl java_format_double");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    mov x1, x19");
            emitln(ftext, "    bl printf");
            return;
        }
    }
    if (strcmp(t, "Casteo") == 0) {
        // Si el casteo es a CHAR/BOOLEAN, usar formateo correcto
        CasteoExpresion *c = (CasteoExpresion *)node;
        TipoDato dest = c->tipo_destino;
        TipoDato ty = emitir_eval_numerico(node, ftext);
        if (dest == CHAR) {
            // Convertir a UTF-8 y imprimir como cadena
            emitln(ftext, "    mov w0, w1");
            emitln(ftext, "    bl char_to_utf8");
            emitln(ftext, "    mov x1, x0");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    bl printf");
            return;
        } else if (dest == BOOLEAN) {
            emitln(ftext, "    cmp w1, #0");
            emitln(ftext, "    ldr x1, =false_str");
            emitln(ftext, "    ldr x16, =true_str");
            emitln(ftext, "    csel x1, x16, x1, ne");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    bl printf");
            return;
        } else {
            if (dest == DOUBLE || dest == FLOAT || ty == DOUBLE) emitln(ftext, "    ldr x0, =fmt_double");
            else emitln(ftext, "    ldr x0, =fmt_int");
            emitln(ftext, "    bl printf");
            return;
        }
    }
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = buscar_variable(id->nombre);
            if (v && v->tipo == STRING) {
            const char *null_lab = add_string_literal("null");
            char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr x1, [x16]", v->offset); emitln(ftext, l1);
            // Sustituir NULL por "null"
            emitln(ftext, "    cmp x1, #0");
            char lnull[64]; snprintf(lnull, sizeof(lnull), "    ldr x16, =%s", null_lab); emitln(ftext, lnull);
            emitln(ftext, "    csel x1, x16, x1, eq");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    bl printf");
        } else if (v) {
            if (v->tipo == DOUBLE || v->tipo == FLOAT) {
                char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr d0, [x16]", v->offset); emitln(ftext, l1);
                // Formatear double a string y luego imprimir
                emitln(ftext, "    ldr x19, =tmpbuf");
                emitln(ftext, "    mov x0, x19");
                emitln(ftext, "    mov x1, #1024");
                emitln(ftext, "    bl java_format_double");
                emitln(ftext, "    ldr x0, =fmt_string");
                emitln(ftext, "    mov x1, x19");
                emitln(ftext, "    bl printf");
            } else {
                char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset); emitln(ftext, l1);
                if (v->tipo == CHAR) {
                    // Imprimir como UTF-8
                    emitln(ftext, "    mov w0, w1");
                    emitln(ftext, "    bl char_to_utf8");
                    emitln(ftext, "    mov x1, x0");
                    emitln(ftext, "    ldr x0, =fmt_string");
                } else if (v->tipo == BOOLEAN) {
                    emitln(ftext, "    cmp w1, #0");
                    emitln(ftext, "    ldr x1, =false_str");
                    emitln(ftext, "    ldr x16, =true_str");
                    emitln(ftext, "    csel x1, x16, x1, ne");
                    emitln(ftext, "    ldr x0, =fmt_string");
                } else {
                    emitln(ftext, "    ldr x0, =fmt_int");
                }
                emitln(ftext, "    bl printf");
            }
        } else {
            // Fallback a global: si conocemos tipo DOUBLE/STRING/CHAR/BOOLEAN, imprimir acorde; si no, como int
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
                    // Sustituir NULL por "null"
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
        return;
    }
    if (nodo_es_resultado_booleano(node)) {
        emitir_eval_booleano(node, ftext);
        emitln(ftext, "    cmp w1, #0");
        emitln(ftext, "    ldr x1, =false_str");
        emitln(ftext, "    ldr x16, =true_str");
        emitln(ftext, "    csel x1, x16, x1, ne");
        emitln(ftext, "    ldr x0, =fmt_string");
        emitln(ftext, "    bl printf");
    } else {
        TipoDato ty = emitir_eval_numerico(node, ftext);
        if (ty == DOUBLE) {
            emitln(ftext, "    ldr x19, =tmpbuf");
            emitln(ftext, "    mov x0, x19");
            emitln(ftext, "    mov x1, #1024");
            emitln(ftext, "    bl java_format_double");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    mov x1, x19");
        } else {
            emitln(ftext, "    ldr x0, =fmt_int");
        }
        emitln(ftext, "    bl printf");
    }
}

int emitir_eval_string_ptr(AbstractExpresion *node, FILE *ftext) {
    const char *t = node->node_type ? node->node_type : "";
    if (strcmp(t, "Primitivo") == 0) {
        PrimitivoExpresion *p = (PrimitivoExpresion *)node;
        if (p->tipo == STRING) {
            const char *lab = add_string_literal(p->valor ? p->valor : "");
            char l2[64]; snprintf(l2, sizeof(l2), "    ldr x1, =%s", lab); emitln(ftext, l2);
            return 1;
        }
    }
    if (strcmp(t, "StringValueof") == 0) {
        emitir_string_valueof(node->hijos[0], ftext);
        return 1;
    }
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = buscar_variable(id->nombre);
        if (v && v->tipo == STRING) {
            char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr x1, [x16]", v->offset); emitln(ftext, l1);
            return 1;
        }
        // Fallback: intentar global string conocido
        const GlobalInfo *gi = globals_lookup(id->nombre);
        if (gi && gi->tipo == STRING) {
            char l1[128]; snprintf(l1, sizeof(l1), "    ldr x16, =g_%s\n    ldr x1, [x16]", id->nombre); emitln(ftext, l1);
            return 1;
        }
        // Si no, no es string evaluable
    }
    return 0;
}
