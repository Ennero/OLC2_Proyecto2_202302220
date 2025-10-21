#include "codegen/arm64_print.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_globals.h"
#include "codegen/estructuras/arm64_arreglos.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "ast/nodos/instrucciones/instruccion/casteos.h"
#include <string.h>
#include <stdlib.h>

static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }
static const char *add_string_literal(const char *text) { return core_add_string_literal(text); }

// Helper: append the string form of an expression to tmpbuf
static void append_expr_to_tmpbuf(AbstractExpresion *arg, FILE *ftext) {
    const char *t = arg->node_type ? arg->node_type : "";
    // If it's a concatenation (Suma) that yields string, recurse without resetting tmpbuf
    if (strcmp(t, "Suma") == 0 && (expresion_es_cadena(arg->hijos[0]) || expresion_es_cadena(arg->hijos[1]))) {
        append_expr_to_tmpbuf(arg->hijos[0], ftext);
        append_expr_to_tmpbuf(arg->hijos[1], ftext);
        return;
    }
    if (expresion_es_cadena(arg)) {
        if (!emitir_eval_string_ptr(arg, ftext)) {
            emitln(ftext, "    ldr x1, =null_str");
        } else {
            emitln(ftext, "    cmp x1, #0");
            emitln(ftext, "    ldr x16, =null_str");
            emitln(ftext, "    csel x1, x16, x1, eq");
        }
        emitln(ftext, "    ldr x0, =tmpbuf");
        emitln(ftext, "    bl strcat");
        return;
    }
    // If it's an array identifier used in a concatenation, append "null" when pointer is NULL
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)arg;
        VarEntry *v = buscar_variable(id->nombre);
        if (v && v->tipo == ARRAY) {
            // load array pointer and check null
            if (v->is_ref) {
                char l1a[128]; snprintf(l1a, sizeof(l1a), "    sub x16, x29, #%d\n    ldr x1, [x16]\n    ldr x1, [x1]", v->offset); emitln(ftext, l1a);
            } else {
                char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr x1, [x16]", v->offset); emitln(ftext, l1);
            }
            emitln(ftext, "    cmp x1, #0");
            emitln(ftext, "    ldr x16, =null_str");
            emitln(ftext, "    csel x1, x16, x1, eq");
            emitln(ftext, "    ldr x0, =tmpbuf");
            emitln(ftext, "    bl strcat");
            return;
        }
    }
    if (nodo_es_resultado_booleano(arg)) {
        emitir_eval_booleano(arg, ftext);
        emitln(ftext, "    cmp w1, #0");
        emitln(ftext, "    ldr x1, =false_str");
        emitln(ftext, "    ldr x16, =true_str");
        emitln(ftext, "    csel x1, x16, x1, ne");
        emitln(ftext, "    ldr x0, =tmpbuf");
        emitln(ftext, "    bl strcat");
        return;
    }
    // Boolean desde acceso a arreglo: mapear a true/false
    if (strcmp(t, "ArrayAccess") == 0) {
        int depthb = 0; AbstractExpresion *itb = arg;
        while (itb && itb->node_type && strcmp(itb->node_type, "ArrayAccess") == 0) { depthb++; itb = itb->hijos[0]; }
        if (itb && itb->node_type && strcmp(itb->node_type, "Identificador") == 0) {
            IdentificadorExpresion *idb = (IdentificadorExpresion *)itb;
            if (arm64_array_elem_tipo_for_var(idb->nombre) == BOOLEAN) {
                (void)emitir_eval_numerico(arg, ftext);
                emitln(ftext, "    cmp w1, #0");
                emitln(ftext, "    ldr x1, =false_str");
                emitln(ftext, "    ldr x16, =true_str");
                emitln(ftext, "    csel x1, x16, x1, ne");
                emitln(ftext, "    ldr x0, =tmpbuf");
                emitln(ftext, "    bl strcat");
                return;
            }
        }
    }
    // Numeric/char
    TipoDato ty = emitir_eval_numerico(arg, ftext);
    int is_char_local = 0;
    if (strcmp(t, "Primitivo") == 0) {
        PrimitivoExpresion *p = (PrimitivoExpresion *)arg;
        is_char_local = (p->tipo == CHAR);
        if (p->tipo == BOOLEAN) {
            int is_true = (p->valor && strcmp(p->valor, "true") == 0);
            emitln(ftext, is_true ? "    ldr x1, =true_str" : "    ldr x1, =false_str");
            emitln(ftext, "    ldr x0, =tmpbuf");
            emitln(ftext, "    bl strcat");
            return;
        }
    } else if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)arg;
        VarEntry *v = buscar_variable(id->nombre);
        if (v) {
            if (v->tipo == CHAR) is_char_local = 1;
            if (v->tipo == BOOLEAN) {
                char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset); emitln(ftext, l1);
                emitln(ftext, "    cmp w1, #0");
                emitln(ftext, "    ldr x1, =false_str");
                emitln(ftext, "    ldr x16, =true_str");
                emitln(ftext, "    csel x1, x16, x1, ne");
                emitln(ftext, "    ldr x0, =tmpbuf");
                emitln(ftext, "    bl strcat");
                return;
            }
        }
    } else if (strcmp(t, "ArrayAccess") == 0) {
        // Si es acceso a arreglo de CHAR, tratarlo como caracter (UTF-8)
        int depth = 0; AbstractExpresion *it = arg;
        while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0) { depth++; it = it->hijos[0]; }
        if (it && it->node_type && strcmp(it->node_type, "Identificador") == 0) {
            IdentificadorExpresion *id = (IdentificadorExpresion *)it;
            if (arm64_array_elem_tipo_for_var(id->nombre) == CHAR) {
                is_char_local = 1;
            }
        }
    }
    if (is_char_local) {
        if (ty == DOUBLE) emitln(ftext, "    fcvtzs w0, d0"); else emitln(ftext, "    mov w0, w1");
        emitln(ftext, "    bl char_to_utf8");
        emitln(ftext, "    mov x1, x0");
        emitln(ftext, "    ldr x0, =tmpbuf");
        emitln(ftext, "    bl strcat");
    } else {
        if (ty == DOUBLE) {
            // Reserve scratch space on stack to safely use it as a temporary buffer
            emitln(ftext, "    sub sp, sp, #128");
            emitln(ftext, "    mov x0, sp");
            emitln(ftext, "    mov x1, #128");
            emitln(ftext, "    bl java_format_double");
            emitln(ftext, "    mov x1, sp");
            emitln(ftext, "    ldr x0, =tmpbuf");
            emitln(ftext, "    bl strcat");
            emitln(ftext, "    add sp, sp, #128");
        } else {
            // Reserve scratch space on stack for sprintf into [sp]
            emitln(ftext, "    sub sp, sp, #128");
            emitln(ftext, "    mov x0, sp");
            emitln(ftext, "    mov w2, w1");
            emitln(ftext, "    ldr x1, =fmt_int");
            emitln(ftext, "    bl sprintf");
            emitln(ftext, "    mov x1, sp");
            emitln(ftext, "    ldr x0, =tmpbuf");
            emitln(ftext, "    bl strcat");
            emitln(ftext, "    add sp, sp, #128");
        }
    }
}

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
    if (strcmp(t, "StringJoin") == 0) {
        return 1;
    }
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = buscar_variable(id->nombre);
        if (v && v->tipo == STRING) return 1;
        // También aceptar globales string
        const GlobalInfo *gi = globals_lookup(id->nombre);
        if (gi && gi->tipo == STRING) return 1;
        return 0;
    }
    if (strcmp(t, "ArrayAccess") == 0) {
        // Si es acceso a arreglo de strings, considerarlo cadena
        int depth = 0; AbstractExpresion *it = node;
        while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0) { depth++; it = it->hijos[0]; }
        if (it && it->node_type && strcmp(it->node_type, "Identificador") == 0) {
            IdentificadorExpresion *id = (IdentificadorExpresion *)it;
            return arm64_array_elem_tipo_for_var(id->nombre) == STRING;
        }
        return 0;
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
        // Duplicate to return an independent heap string
        emitln(ftext, "    mov x0, x1");
        emitln(ftext, "    bl strdup");
        emitln(ftext, "    mov x1, x0");
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
            emitln(ftext, "    mov x0, x1");
            emitln(ftext, "    bl strdup");
            emitln(ftext, "    mov x1, x0");
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
        emitln(ftext, "    mov x0, x1");
        emitln(ftext, "    bl strdup");
        emitln(ftext, "    mov x1, x0");
        return;
    }

    // 2.2) ArrayAccess booleano -> true/false
    if (strcmp(t, "ArrayAccess") == 0) {
        // Detectar tipo base del arreglo
        int depth2 = 0; AbstractExpresion *it2 = arg;
        while (it2 && it2->node_type && strcmp(it2->node_type, "ArrayAccess") == 0) { depth2++; it2 = it2->hijos[0]; }
        if (it2 && it2->node_type && strcmp(it2->node_type, "Identificador") == 0) {
            IdentificadorExpresion *id2 = (IdentificadorExpresion *)it2;
            TipoDato base_t2 = arm64_array_elem_tipo_for_var(id2->nombre);
            if (base_t2 == BOOLEAN) {
                (void)emitir_eval_numerico(arg, ftext); // deja w1
                emitln(ftext, "    cmp w1, #0");
                emitln(ftext, "    ldr x1, =false_str");
                emitln(ftext, "    ldr x16, =true_str");
                emitln(ftext, "    csel x1, x16, x1, ne");
                // strdup
                emitln(ftext, "    mov x0, x1");
                emitln(ftext, "    bl strdup");
                emitln(ftext, "    mov x1, x0");
                return;
            } else if (base_t2 == CHAR) {
                // ArrayAccess de char -> convertir a UTF-8 y duplicar
                TipoDato tyc = emitir_eval_numerico(arg, ftext);
                if (tyc == DOUBLE) emitln(ftext, "    fcvtzs w0, d0"); else emitln(ftext, "    mov w0, w1");
                emitln(ftext, "    bl char_to_utf8");
                emitln(ftext, "    mov x0, x0");
                emitln(ftext, "    bl strdup");
                emitln(ftext, "    mov x1, x0");
                return;
            }
        }
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
    } else if (strcmp(t, "ArrayAccess") == 0) {
        // Tratar acceso a arreglo de CHAR como char
        int depth3 = 0; AbstractExpresion *it3 = arg;
        while (it3 && it3->node_type && strcmp(it3->node_type, "ArrayAccess") == 0) { depth3++; it3 = it3->hijos[0]; }
        if (it3 && it3->node_type && strcmp(it3->node_type, "Identificador") == 0) {
            IdentificadorExpresion *id3 = (IdentificadorExpresion *)it3;
            if (arm64_array_elem_tipo_for_var(id3->nombre) == CHAR) is_char = 1;
        }
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
        // Convertir code point a UTF-8 y duplicar resultado
        emitln(ftext, "    mov w0, w21");
        emitln(ftext, "    bl char_to_utf8");
        emitln(ftext, "    mov x0, x0");
        emitln(ftext, "    bl strdup");
        emitln(ftext, "    mov x1, x0");
    } else {
        if (ty == DOUBLE) {
            // Formatear a buffer temporal en stack para evitar colisión con tmpbuf de concatenación
            emitln(ftext, "    sub sp, sp, #128");
            emitln(ftext, "    mov x0, sp");
            emitln(ftext, "    mov x1, #128");
            emitln(ftext, "    bl java_format_double");
            // strdup(sp)
            emitln(ftext, "    mov x0, sp");
            emitln(ftext, "    bl strdup");
            emitln(ftext, "    add sp, sp, #128");
            emitln(ftext, "    mov x1, x0");
        } else {
            // Enteros: sprintf a buffer temporal en stack con %d para evitar usar tmpbuf
            emitln(ftext, "    sub sp, sp, #128");
            emitln(ftext, "    mov w21, w1");
            emitln(ftext, "    mov x0, sp");
            emitln(ftext, "    ldr x1, =fmt_int");
            emitln(ftext, "    mov w2, w21");
            emitln(ftext, "    bl sprintf");
            // strdup(sp)
            emitln(ftext, "    mov x0, sp");
            emitln(ftext, "    bl strdup");
            emitln(ftext, "    add sp, sp, #128");
            emitln(ftext, "    mov x1, x0");
        }
    }
}

void emitir_imprimir_cadena(AbstractExpresion *node, FILE *ftext) {
    const char *t = node->node_type ? node->node_type : "";
    if (strcmp(t, "ArrayAccess") == 0) {
        // Imprimir elementos de arreglo según su tipo base
        int depth = 0; AbstractExpresion *it = node;
        while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0) { depth++; it = it->hijos[0]; }
        if (it && it->node_type && strcmp(it->node_type, "Identificador") == 0) {
            IdentificadorExpresion *id = (IdentificadorExpresion *)it;
            TipoDato base_t = arm64_array_elem_tipo_for_var(id->nombre);
            if (base_t == STRING) {
                const char *null_lab = add_string_literal("null");
                if (!emitir_eval_string_ptr(node, ftext)) {
                    char lz[64]; snprintf(lz, sizeof(lz), "    ldr x1, =%s", null_lab); emitln(ftext, lz);
                }
                // Sustituir NULL por "null"
                emitln(ftext, "    cmp x1, #0");
                char lnull[64]; snprintf(lnull, sizeof(lnull), "    ldr x16, =%s", null_lab); emitln(ftext, lnull);
                emitln(ftext, "    csel x1, x16, x1, eq");
                emitln(ftext, "    ldr x0, =fmt_string");
                emitln(ftext, "    bl printf");
                return;
            } else if (base_t == CHAR) {
                (void)emitir_eval_numerico(node, ftext);
                emitln(ftext, "    mov w0, w1");
                emitln(ftext, "    bl char_to_utf8");
                emitln(ftext, "    mov x1, x0");
                emitln(ftext, "    ldr x0, =fmt_string");
                emitln(ftext, "    bl printf");
                return;
            } else if (base_t == DOUBLE || base_t == FLOAT) {
                // Evaluar como double y formatear antes de imprimir
                (void)emitir_eval_numerico(node, ftext);
                // Formatear double a tmpbuf y luego imprimir como string
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
        // Fallback: evaluar y decidir por tipo en tiempo de ejecución (numérico)
        TipoDato ty = emitir_eval_numerico(node, ftext);
        if (ty == DOUBLE) {
            emitln(ftext, "    ldr x19, =tmpbuf");
            emitln(ftext, "    mov x0, x19");
            emitln(ftext, "    mov x1, #1024");
            emitln(ftext, "    bl java_format_double");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    mov x1, x19");
            emitln(ftext, "    bl printf");
        } else {
            emitln(ftext, "    ldr x0, =fmt_int");
            emitln(ftext, "    bl printf");
        }
        return;
    }
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
        // Concatenación de strings: construir en tmpbuf para respetar formateos numéricos
        emitln(ftext, "    // String concatenation to tmpbuf (print)");
        emitln(ftext, "    ldr x0, =tmpbuf");
        emitln(ftext, "    mov w2, #0");
        emitln(ftext, "    strb w2, [x0]");
        append_expr_to_tmpbuf(node->hijos[0], ftext);
        append_expr_to_tmpbuf(node->hijos[1], ftext);
        emitln(ftext, "    ldr x0, =fmt_string");
        emitln(ftext, "    ldr x1, =tmpbuf");
        emitln(ftext, "    bl printf");
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
    if (strcmp(t, "StringJoin") == 0) {
        if (!emitir_eval_string_ptr(node, ftext)) {
            emitln(ftext, "    ldr x1, =null_str");
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
            if (v->is_ref) {
                char l1a[128]; snprintf(l1a, sizeof(l1a), "    sub x16, x29, #%d\n    ldr x1, [x16]\n    ldr x1, [x1]", v->offset); emitln(ftext, l1a);
            } else {
                char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr x1, [x16]", v->offset); emitln(ftext, l1);
            }
            // Sustituir NULL por "null"
            emitln(ftext, "    cmp x1, #0");
            char lnull[64]; snprintf(lnull, sizeof(lnull), "    ldr x16, =%s", null_lab); emitln(ftext, lnull);
            emitln(ftext, "    csel x1, x16, x1, eq");
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    bl printf");
        } else if (v && v->tipo == ARRAY) {
            // Print array identifiers: if NULL print "null"; otherwise print pointer as string? For now match requested: show null when not initialized
            const char *null_lab = add_string_literal("null");
            char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr x1, [x16]", v->offset); emitln(ftext, l1);
            emitln(ftext, "    cmp x1, #0");
            char lnull2[64]; snprintf(lnull2, sizeof(lnull2), "    ldr x16, =%s", null_lab); emitln(ftext, lnull2);
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
                } else if (gi->tipo == ARRAY) {
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
    if (strcmp(t, "Suma") == 0 && (expresion_es_cadena(node->hijos[0]) || expresion_es_cadena(node->hijos[1]))) {
    // Build concatenation into tmpbuf: clear buffer once
    emitln(ftext, "    // String concatenation to tmpbuf");
    emitln(ftext, "    ldr x0, =tmpbuf");
        emitln(ftext, "    mov w2, #0");
        emitln(ftext, "    strb w2, [x0]");
        append_expr_to_tmpbuf(node->hijos[0], ftext);
        append_expr_to_tmpbuf(node->hijos[1], ftext);
        emitln(ftext, "    ldr x1, =tmpbuf");
        return 1;
    }
    if (strcmp(t, "ArrayAccess") == 0) {
        // Soportar obtener puntero a elemento de arreglo de strings: usa array_element_addr_ptr
        int depth = 0; AbstractExpresion *it = node;
        while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0) { depth++; it = it->hijos[0]; }
        if (!(it && it->node_type && strcmp(it->node_type, "Identificador") == 0)) return 0;
        IdentificadorExpresion *id = (IdentificadorExpresion *)it;
        // Sólo procede si el arreglo es de strings; de lo contrario no es una expresión de cadena
        if (arm64_array_elem_tipo_for_var(id->nombre) != STRING) {
            return 0;
        }
        VarEntry *v = buscar_variable(id->nombre);
        if (!v) return 0;
        // Reservar stack para indices y empujarlos en orden i0..iN-1 (izq->der)
        int bytes = ((depth * 4) + 15) & ~15;
        if (bytes > 0) { char sub[64]; snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes); emitln(ftext, sub); }
        // Reservar arreglo dinámico para soportar profundidades altas
        AbstractExpresion **idx_nodes = NULL;
        if (depth > 0) idx_nodes = (AbstractExpresion**)malloc(sizeof(AbstractExpresion*) * (size_t)depth);
        int pos = depth - 1; it = node;
        for (int i = 0; i < depth; ++i) { idx_nodes[pos--] = it->hijos[1]; it = it->hijos[0]; }
        for (int k = 0; k < depth; ++k) {
            TipoDato ty = emitir_eval_numerico(idx_nodes[k], ftext);
            if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
            char st[64]; snprintf(st, sizeof(st), "    str w1, [sp, #%d]", k * 4); emitln(ftext, st);
        }
        // Cargar puntero base del arreglo
        { char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", v->offset); emitln(ftext, ld); }
        emitln(ftext, "    mov x1, sp");
        { char mv[64]; snprintf(mv, sizeof(mv), "    mov w2, #%d", depth); emitln(ftext, mv); }
        emitln(ftext, "    bl array_element_addr_ptr");
        emitln(ftext, "    ldr x1, [x0]");
        if (bytes > 0) { char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb); }
        if (idx_nodes) free(idx_nodes);
        return 1;
    }
    if (strcmp(t, "StringValueof") == 0) {
        // Produce en x1 el string generado por valueOf(arg)
        emitir_string_valueof(node->hijos[0], ftext);
        return 1;
    }
    if (strcmp(t, "StringJoin") == 0) {
        // Evaluar delimitador a puntero string en x23 (callee-saved, preservado por libc)
        if (!emitir_eval_string_ptr(node->hijos[0], ftext)) {
            return 0;
        }
        emitln(ftext, "    mov x23, x1");
        AbstractExpresion *lista = node->hijos[1];
        // Caso A: un solo argumento y es identificador de arreglo conocido
        if (lista && lista->numHijos == 1 && lista->hijos[0] && strcmp(lista->hijos[0]->node_type, "Identificador") == 0) {
            IdentificadorExpresion *id = (IdentificadorExpresion *)lista->hijos[0];
            VarEntry *v = buscar_variable(id->nombre);
            // Detectar si el identificador corresponde a un arreglo registrado
            TipoDato bt = arm64_array_elem_tipo_for_var(id->nombre);
            if (bt != NULO && v) {
                // Cargar puntero al arreglo en x0 y llamar al helper según tipo base
                char ld[96]; snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", v->offset); emitln(ftext, ld);
                // x1 = delimitador
                emitln(ftext, "    mov x1, x23");
                if (bt == STRING) emitln(ftext, "    bl join_array_strings");
                else if (bt == INT) emitln(ftext, "    bl join_array_ints");
                else {
                    // Tipos no soportados aún: retornar cadena vacía
                    emitln(ftext, "    ldr x0, =tmpbuf");
                    emitln(ftext, "    mov w2, #0");
                    emitln(ftext, "    strb w2, [x0]");
                }
                // Duplicar resultado (tmpbuf u output del helper) para evitar alias
                emitln(ftext, "    bl strdup");
                // Helpers retornan x0=tmpbuf; mover a x1 como contrato de esta función
                emitln(ftext, "    mov x1, x0");
                return 1;
            }
        }
        // Caso B: varargs: concatenar cada elemento convertido a string en joinbuf
        // Inicializar joinbuf como cadena vacía y reservar scratch en stack para formateo
        emitln(ftext, "    ldr x0, =joinbuf");
        emitln(ftext, "    mov w2, #0");
        emitln(ftext, "    strb w2, [x0]");
        emitln(ftext, "    sub sp, sp, #128");
        for (size_t i = 0; i < lista->numHijos; ++i) {
            if (i > 0) {
                emitln(ftext, "    ldr x0, =joinbuf");
                emitln(ftext, "    mov x1, x23");
                emitln(ftext, "    bl strcat");
            }
            AbstractExpresion *arg = lista->hijos[i];
            if (expresion_es_cadena(arg)) {
                if (!emitir_eval_string_ptr(arg, ftext)) {
                    emitln(ftext, "    ldr x1, =null_str");
                } else {
                    emitln(ftext, "    cmp x1, #0");
                    emitln(ftext, "    ldr x16, =null_str");
                    emitln(ftext, "    csel x1, x16, x1, eq");
                }
                emitln(ftext, "    ldr x0, =joinbuf");
                emitln(ftext, "    bl strcat");
            } else if (nodo_es_resultado_booleano(arg)) {
                emitir_eval_booleano(arg, ftext);
                emitln(ftext, "    cmp w1, #0");
                emitln(ftext, "    ldr x1, =false_str");
                emitln(ftext, "    ldr x16, =true_str");
                emitln(ftext, "    csel x1, x16, x1, ne");
                emitln(ftext, "    ldr x0, =joinbuf");
                emitln(ftext, "    bl strcat");
            } else {
                // Evaluar numérico/char y formatear en [sp]
                TipoDato ty = emitir_eval_numerico(arg, ftext);
                if (ty == DOUBLE) {
                    emitln(ftext, "    mov x0, sp");
                    emitln(ftext, "    mov x1, #128");
                    emitln(ftext, "    bl java_format_double");
                    emitln(ftext, "    mov x1, sp");
                    emitln(ftext, "    ldr x0, =joinbuf");
                    emitln(ftext, "    bl strcat");
                } else {
                    // INT/CHAR: si CHAR convertir a UTF-8 en charbuf
                    // Detectar si el arg original es CHAR aproximando por su tipo estático cuando sea identificador/primitivo
                    int is_char_local = 0;
                    const char *at = arg->node_type ? arg->node_type : "";
                    if (strcmp(at, "Primitivo") == 0) {
                        PrimitivoExpresion *p = (PrimitivoExpresion *)arg;
                        is_char_local = (p->tipo == CHAR);
                        // Mapear booleano literal a "true"/"false"
                        if (p->tipo == BOOLEAN) {
                            int is_true = (p->valor && strcmp(p->valor, "true") == 0);
                            emitln(ftext, is_true ? "    ldr x1, =true_str" : "    ldr x1, =false_str");
                            emitln(ftext, "    ldr x0, =joinbuf");
                            emitln(ftext, "    bl strcat");
                            continue;
                        }
                    } else if (strcmp(at, "Identificador") == 0) {
                        IdentificadorExpresion *aid = (IdentificadorExpresion *)arg;
                        VarEntry *vv = buscar_variable(aid->nombre);
                        is_char_local = (vv && vv->tipo == CHAR);
                        // Identificador booleano -> true/false
                        if (vv && vv->tipo == BOOLEAN) {
                            char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr w1, [x16]", vv->offset); emitln(ftext, l1);
                            emitln(ftext, "    cmp w1, #0");
                            emitln(ftext, "    ldr x1, =false_str");
                            emitln(ftext, "    ldr x16, =true_str");
                            emitln(ftext, "    csel x1, x16, x1, ne");
                            emitln(ftext, "    ldr x0, =joinbuf");
                            emitln(ftext, "    bl strcat");
                            continue;
                        }
                    }
                    if (is_char_local) {
                        emitln(ftext, "    mov w0, w1");
                        emitln(ftext, "    bl char_to_utf8");
                        emitln(ftext, "    mov x1, x0");
                        emitln(ftext, "    ldr x0, =joinbuf");
                        emitln(ftext, "    bl strcat");
                    } else {
                        emitln(ftext, "    mov x0, sp");
                        // Mover primero el valor a w2 antes de cargar el formato (x1)
                        emitln(ftext, "    mov w2, w1");
                        emitln(ftext, "    ldr x1, =fmt_int");
                        emitln(ftext, "    bl sprintf");
                        emitln(ftext, "    mov x1, sp");
                        emitln(ftext, "    ldr x0, =joinbuf");
                        emitln(ftext, "    bl strcat");
                    }
                }
            }
        }
        emitln(ftext, "    add sp, sp, #128");
        // Duplicar resultado para evitar alias con joinbuf
        emitln(ftext, "    ldr x0, =joinbuf");
        emitln(ftext, "    bl strdup");
        emitln(ftext, "    mov x1, x0");
        return 1;
    }
    if (strcmp(t, "StringValueof") == 0) {
        emitir_string_valueof(node->hijos[0], ftext);
        return 1;
    }
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = buscar_variable(id->nombre);
        if (v && v->tipo == STRING) {
            // Si es referencia (parámetro por referencia), primero cargar la dirección y luego desreferenciar para obtener el puntero real
            if (v->is_ref) {
                char l1a[128]; snprintf(l1a, sizeof(l1a), "    sub x16, x29, #%d\n    ldr x1, [x16]\n    ldr x1, [x1]", v->offset); emitln(ftext, l1a);
            } else {
                char l1[96]; snprintf(l1, sizeof(l1), "    sub x16, x29, #%d\n    ldr x1, [x16]", v->offset); emitln(ftext, l1);
            }
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
