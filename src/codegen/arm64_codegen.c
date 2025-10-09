#include "codegen/arm64_codegen.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_print.h"
#include "ast/AbstractExpresion.h"
#include "ast/nodos/instrucciones/instrucciones.h"
#include "ast/nodos/expresiones/listaExpresiones.h"
#include "ast/nodos/instrucciones/instruccion/print.h"
#include "ast/nodos/instrucciones/instruccion/declaracion.h"
#include "ast/nodos/instrucciones/instruccion/reasignacion.h"
#include "ast/nodos/instrucciones/instruccion/asignacion_compuesta.h"
#include "ast/nodos/instrucciones/instruccion/casteos.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "ast/nodos/expresiones/aritmeticas/aritmeticas.h"
#include "ast/nodos/expresiones/relacionales/relacionales.h"
#include "ast/nodos/expresiones/logicas/logicas.h"
#include "context/result.h"
#include "parser.tab.h" // Para tokens como TOKEN_LSHIFT en asignaciones compuestas
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Pequeña util para escribir una línea en el archivo (delegar a core)
static void emitln(FILE *f, const char *s) { core_emitln(f, s); }

// Delegar manejo de literales a core
static const char *add_string_literal(const char *text) { return core_add_string_literal(text); }

// escape_for_asciz movido a core

// ----------------- Gestión simple de variables locales -----------------
// Variables locales delegadas a arm64_vars
// Tip alias para compatibilidad local
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }
static VarEntry *agregar_variable(const char *name, TipoDato tipo, int size_bytes, FILE *ftext) { return vars_agregar(name, tipo, size_bytes, ftext); }

// ----------------- Emisión de expresiones -----------------
// Implementaciones movidas a codegen/expresiones/*.c (arm64_num.c, arm64_bool.c, arm64_print.c)

// Recorre el árbol emitiendo código para Print con literales primitivos
static void gen_node(FILE *ftext, AbstractExpresion *node) {
    if (!node) return;
    // Manejo especial de bloques: crean un nuevo alcance de variables
    if (node->node_type && strcmp(node->node_type, "Bloque") == 0) {
        vars_push_scope(ftext);
        for (size_t i = 0; i < node->numHijos; i++) {
            gen_node(ftext, node->hijos[i]);
        }
        vars_pop_scope(ftext);
        return;
    }

    // Recorremos primero hijos (pre-orden simple para statements) excepto Bloque (ya manejado)
    for (size_t i = 0; i < node->numHijos; i++) {
        // No procesar aquí sub-bloques; serán manejados al entrar a gen_node
        if (node->hijos[i] && node->hijos[i]->node_type && strcmp(node->hijos[i]->node_type, "Bloque") == 0) {
            gen_node(ftext, node->hijos[i]);
        } else {
            gen_node(ftext, node->hijos[i]);
        }
    }

    // Detectar por node_type minimalista
    if (node->node_type && strcmp(node->node_type, "Instrucciones") == 0) {
        // ya recorremos hijos arriba
        return;
    }
    // Bloques ya fueron manejados arriba
    if (node->node_type && strcmp(node->node_type, "MainFunction") == 0) {
        // ya procesamos sus hijos
        return;
    }
    if (node->node_type && strcmp(node->node_type, "Declaracion") == 0) {
        // Declaración de variable local con inicialización de literal primitivo
        DeclaracionVariable *decl = (DeclaracionVariable *)node;
        if (decl->dimensiones > 0) {
            // Arreglos no soportados aún
            return;
        }
        // Tamaño
        int size = (decl->tipo == DOUBLE) ? 8 : 8; // usamos 8 para alinear (char/int/bool caben)
        VarEntry *v = NULL;
        int is_const = decl->es_constante ? 1 : 0;
        v = vars_agregar_ext(decl->nombre, decl->tipo, size, is_const, ftext);
        if (node->numHijos > 0) {
            AbstractExpresion *init = node->hijos[0];
            if (decl->tipo == DOUBLE || decl->tipo == FLOAT) {
                // Inicializa a double/float; si RHS es int, convertir implícitamente
                TipoDato ty = emitir_eval_numerico(init, ftext);
                if (ty != DOUBLE) emitln(ftext, "    scvtf d0, w1");
                char st[64]; snprintf(st, sizeof(st), "    str d0, [x29, -%d]", v->offset); emitln(ftext, st);
            } else if (decl->tipo == STRING) {
                if (strcmp(init->node_type, "Primitivo") == 0) {
                    PrimitivoExpresion *p = (PrimitivoExpresion *)init;
                    const char *lab = add_string_literal(p->valor ? p->valor : "");
                    char l1[64]; snprintf(l1, sizeof(l1), "    ldr x1, =%s", lab); emitln(ftext, l1);
                    char st[64]; snprintf(st, sizeof(st), "    str x1, [x29, -%d]", v->offset); emitln(ftext, st);
                }
            } else {
                // Inicializa a entero/bool/char; si RHS es double, convertir implícitamente
                TipoDato ty = emitir_eval_numerico(init, ftext);
                if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                char st[64]; snprintf(st, sizeof(st), "    str w1, [x29, -%d]", v->offset); emitln(ftext, st);
            }
        } else {
            // Valor por defecto 0/false/null. Para constantes 'final', en Java es error; aquí no reportamos en codegen.
            if (decl->tipo == STRING) {
                char st[64]; snprintf(st, sizeof(st), "    mov x1, #0\n    str x1, [x29, -%d]", v->offset); emitln(ftext, st);
            } else if (decl->tipo == DOUBLE || decl->tipo == FLOAT) {
                emitln(ftext, "    fmov d0, xzr");
                char st[64]; snprintf(st, sizeof(st), "    str d0, [x29, -%d]", v->offset); emitln(ftext, st);
            } else {
                char st[64]; snprintf(st, sizeof(st), "    mov w1, #0\n    str w1, [x29, -%d]", v->offset); emitln(ftext, st);
            }
        }
        return;
    }
    if (node->node_type && strcmp(node->node_type, "Print") == 0) {
        // Esperamos 1 hijo: una ListaExpresiones, cuyas entradas por ahora deben ser Primitivos
        if (node->numHijos == 0) return;
        AbstractExpresion *lista = node->hijos[0];
        {
            char cm[256];
            snprintf(cm, sizeof(cm), "    // Print lista node_type: %s, numHijos=%zu", lista && lista->node_type ? lista->node_type : "<null>", lista ? lista->numHijos : 0);
            emitln(ftext, cm);
        }

        // Imprimimos cada expr seguido de espacio (excepto la última), luego un \n
        for (size_t i = 0; i < lista->numHijos; i++) {
            AbstractExpresion *expr = lista->hijos[i];
            {
                char cm[256];
                snprintf(cm, sizeof(cm), "    // print expr node_type: %s", expr && expr->node_type ? expr->node_type : "<null>");
                emitln(ftext, cm);
            }
            // Tratar String.valueOf como cadena directa
            if (expr->node_type && strcmp(expr->node_type, "StringValueof") == 0) {
                emitir_imprimir_cadena(expr, ftext);
            }
            // Si es concatenación (stringy), imprimir sus partes
            else if (expresion_es_cadena(expr)) {
                emitir_imprimir_cadena(expr, ftext);
            }
            // Soportar Primitivo
            else if (expr->node_type && strcmp(expr->node_type, "Primitivo") == 0) {
                PrimitivoExpresion *p = (PrimitivoExpresion *)expr;
                switch (p->tipo) {
                    case INT:
                        emitln(ftext, "    // print int");
                        emitln(ftext, "    ldr x0, =fmt_int");
                        // cargar inmediato en w1
                        // p->valor es texto (ej. "42"), conviértelo a int con strtol
                        {
                            long v = 0;
                            if (p->valor) {
                                if (strncmp(p->valor, "0x", 2) == 0 || strncmp(p->valor, "0X", 2) == 0)
                                    v = strtol(p->valor, NULL, 16);
                                else
                                    v = strtol(p->valor, NULL, 10);
                            }
                            char line[64];
                            snprintf(line, sizeof(line), "    mov w1, #%ld", v);
                            emitln(ftext, line);
                            emitln(ftext, "    bl printf");
                        }
                        break;
                    case FLOAT:
                    case DOUBLE:
                        emitln(ftext, "    // print double");
                        emitln(ftext, "    ldr x0, =fmt_double");
                        // Guardar el double en .data y cargar en d0
                        {
                            // Crear etiqueta única con el valor
                            const char *lab = core_add_double_literal(p->valor ? p->valor : "0");
                            // Registrar en lista de strings como hack? Mejor lo escribimos directo desde .text usando etiqueta
                            // Aquí solo emitimos carga de esa etiqueta; la sección .data se generará en arm64_generate_program.
                            char ref[128];
                            snprintf(ref, sizeof(ref), "    ldr x16, =%s\n    ldr d0, [x16]", lab);
                            emitln(ftext, ref);
                            emitln(ftext, "    bl printf");
                            // doble literal ya registrado en core
                        }
                        break;
                    case BOOLEAN:
                        emitln(ftext, "    // print boolean");
                        emitln(ftext, "    ldr x0, =fmt_string");
                        {
                            int is_true = (p->valor && strcmp(p->valor, "true") == 0);
                            emitln(ftext, is_true ? "    ldr x1, =true_str" : "    ldr x1, =false_str");
                            emitln(ftext, "    bl printf");
                        }
                        break;
                    case CHAR:
                        emitln(ftext, "    // print char");
                        emitln(ftext, "    ldr x0, =fmt_char");
                        if (p->valor && p->valor[0] == '\\' && p->valor[1]) {
                            int v = 0;
                            if (p->valor[1] == 'u') {
                                // Leer hasta 5 dígitos decimales tras \u
                                const char *s = p->valor; size_t n = strlen(s);
                                int val = 0; size_t i = 2, cnt = 0;
                                while (i < n && cnt < 5 && s[i] >= '0' && s[i] <= '9') { val = val*10 + (s[i]-'0'); i++; cnt++; }
                                if (val < 0) val = 0; if (val > 0x10FFFF) val = 0x10FFFF; v = val;
                            } else {
                                switch (p->valor[1]) {
                                    case 'n': v = '\n'; break;
                                    case 't': v = '\t'; break;
                                    case 'r': v = '\r'; break;
                                    case '\\': v = '\\'; break;
                                    case '\'': v = '\''; break;
                                    case '"': v = '"'; break;
                                    default: v = (unsigned char)p->valor[1]; break;
                                }
                            }
                            char line[64]; snprintf(line, sizeof(line), "    mov w1, #%d", v); emitln(ftext, line);
                        } else {
                            int v = p->valor && p->valor[0] ? (unsigned char)p->valor[0] : 0;
                            char line[64]; snprintf(line, sizeof(line), "    mov w1, #%d", v); emitln(ftext, line);
                        }
                        emitln(ftext, "    bl printf");
                        break;
                    case STRING:
                    default: {
                        emitln(ftext, "    // print string" );
                        emitln(ftext, "    ldr x0, =fmt_string");
                        const char *label = add_string_literal(p->valor ? p->valor : "");
                        char line[64]; snprintf(line, sizeof(line), "    ldr x1, =%s", label); emitln(ftext, line);
                        emitln(ftext, "    bl printf");
                        break;
                    }
                }
            } else if (expr->node_type && strcmp(expr->node_type, "Identificador") == 0) {
                IdentificadorExpresion *id = (IdentificadorExpresion *)expr;
                VarEntry *v = buscar_variable(id->nombre);
                if (v) {
                    if (v->tipo == DOUBLE || v->tipo == FLOAT) {
                        char l1[64]; snprintf(l1, sizeof(l1), "    ldr d0, [x29, -%d]", v->offset); emitln(ftext, l1);
                        emitln(ftext, "    ldr x0, =fmt_double");
                        emitln(ftext, "    bl printf");
                    } else if (v->tipo == STRING) {
                        char l1[64]; snprintf(l1, sizeof(l1), "    ldr x1, [x29, -%d]", v->offset); emitln(ftext, l1);
                        emitln(ftext, "    ldr x0, =fmt_string");
                        emitln(ftext, "    bl printf");
                    } else if (v->tipo == CHAR) {
                        char l1[64]; snprintf(l1, sizeof(l1), "    ldr w1, [x29, -%d]", v->offset); emitln(ftext, l1);
                        emitln(ftext, "    ldr x0, =fmt_char");
                        emitln(ftext, "    bl printf");
                    } else if (v->tipo == BOOLEAN) {
                        char l1[64]; snprintf(l1, sizeof(l1), "    ldr w1, [x29, -%d]", v->offset); emitln(ftext, l1);
                        emitln(ftext, "    cmp w1, #0");
                        emitln(ftext, "    ldr x1, =false_str");
                        emitln(ftext, "    ldr x16, =true_str");
                        emitln(ftext, "    csel x1, x16, x1, ne");
                        emitln(ftext, "    ldr x0, =fmt_string");
                        emitln(ftext, "    bl printf");
                    } else { // INT
                        char l1[64]; snprintf(l1, sizeof(l1), "    ldr w1, [x29, -%d]", v->offset); emitln(ftext, l1);
                        emitln(ftext, "    ldr x0, =fmt_int");
                        emitln(ftext, "    bl printf");
                    }
                }
            } else if (expr->node_type && (strcmp(expr->node_type, "Suma") == 0 ||
                                           strcmp(expr->node_type, "Resta") == 0 ||
                                           strcmp(expr->node_type, "Multiplicacion") == 0 ||
                                           strcmp(expr->node_type, "Division") == 0 ||
                                           strcmp(expr->node_type, "Modulo") == 0 ||
                                           strcmp(expr->node_type, "NegacionUnaria") == 0)) {
                // Si no es stringy, evaluar como numérico y luego imprimir
                TipoDato ty = emitir_eval_numerico(expr, ftext);
                if (ty == DOUBLE) emitln(ftext, "    ldr x0, =fmt_double"); else emitln(ftext, "    ldr x0, =fmt_int");
                emitln(ftext, "    bl printf");
            } else if (expr->node_type && strcmp(expr->node_type, "Casteo") == 0) {
                // Casteo: formateo especial para CHAR y BOOLEAN
                CasteoExpresion *c = (CasteoExpresion *)expr;
                TipoDato ty = emitir_eval_numerico(expr, ftext);
                if (c->tipo_destino == CHAR) {
                    emitln(ftext, "    ldr x0, =fmt_char");
                } else if (c->tipo_destino == BOOLEAN) {
                    emitln(ftext, "    cmp w1, #0");
                    emitln(ftext, "    ldr x1, =false_str");
                    emitln(ftext, "    ldr x16, =true_str");
                    emitln(ftext, "    csel x1, x16, x1, ne");
                    emitln(ftext, "    ldr x0, =fmt_string");
                } else {
                    if (ty == DOUBLE || c->tipo_destino == DOUBLE || c->tipo_destino == FLOAT) emitln(ftext, "    ldr x0, =fmt_double");
                    else emitln(ftext, "    ldr x0, =fmt_int");
                }
                emitln(ftext, "    bl printf");
            } else if (expr->node_type && nodo_es_resultado_booleano(expr)) {
                // Evaluar booleano y mapear a true/false
                emitir_eval_booleano(expr, ftext);
                emitln(ftext, "    cmp w1, #0");
                emitln(ftext, "    ldr x1, =false_str");
                emitln(ftext, "    ldr x16, =true_str");
                emitln(ftext, "    csel x1, x16, x1, ne");
                emitln(ftext, "    ldr x0, =fmt_string");
                emitln(ftext, "    bl printf");
            } else {
                // Fallback: evalúa como numérico por defecto
                TipoDato ty = emitir_eval_numerico(expr, ftext);
                if (ty == DOUBLE) emitln(ftext, "    ldr x0, =fmt_double"); else emitln(ftext, "    ldr x0, =fmt_int");
                emitln(ftext, "    bl printf");
            }
            // Agregar espacio si no es el último
            if (i + 1 < lista->numHijos) {
                const char *lab = add_string_literal(" ");
                emitln(ftext, "    ldr x0, =fmt_string");
                char l2[64]; snprintf(l2, sizeof(l2), "    ldr x1, =%s", lab); emitln(ftext, l2);
                emitln(ftext, "    bl printf");
            }
        }
        // salto de línea
        const char *nl = add_string_literal("\n");
        emitln(ftext, "    ldr x0, =fmt_string");
        {
            char l2[64]; snprintf(l2, sizeof(l2), "    ldr x1, =%s", nl); emitln(ftext, l2);
        }
        emitln(ftext, "    bl printf");
        return;
    }
    // Reasignación simple: id = expr
    if (node->node_type && strcmp(node->node_type, "Reasignacion") == 0) {
        ReasignacionExpresion *rea = (ReasignacionExpresion *)node;
        VarEntry *v = buscar_variable(rea->nombre);
    if (!v) return;
        if (v->is_const) {
            emitln(ftext, "    // reasignación a constante ignorada en codegen");
            return;
        }
        AbstractExpresion *rhs = node->hijos[0];
        if (v->tipo == STRING) {
            // Soportar literal string o id string
            if (rhs->node_type && strcmp(rhs->node_type, "Primitivo") == 0) {
                PrimitivoExpresion *p = (PrimitivoExpresion *)rhs;
                if (p->tipo == STRING) {
                    const char *lab = add_string_literal(p->valor ? p->valor : "");
                    char l1[64]; snprintf(l1, sizeof(l1), "    ldr x1, =%s", lab); emitln(ftext, l1);
                    char st[64]; snprintf(st, sizeof(st), "    str x1, [x29, -%d]", v->offset); emitln(ftext, st);
                }
            } else if (rhs->node_type && strcmp(rhs->node_type, "Identificador") == 0) {
                IdentificadorExpresion *rid = (IdentificadorExpresion *)rhs;
                VarEntry *rv = buscar_variable(rid->nombre);
                if (rv) {
                    char l1[64]; snprintf(l1, sizeof(l1), "    ldr x1, [x29, -%d]", rv->offset); emitln(ftext, l1);
                    char st[64]; snprintf(st, sizeof(st), "    str x1, [x29, -%d]", v->offset); emitln(ftext, st);
                }
            }
        } else if (v->tipo == DOUBLE || v->tipo == FLOAT) {
            TipoDato ty = emitir_eval_numerico(rhs, ftext);
            if (ty != DOUBLE) emitln(ftext, "    scvtf d0, w1");
            char st[64]; snprintf(st, sizeof(st), "    str d0, [x29, -%d]", v->offset); emitln(ftext, st);
        } else {
            TipoDato ty = emitir_eval_numerico(rhs, ftext);
            if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
            char st[64]; snprintf(st, sizeof(st), "    str w1, [x29, -%d]", v->offset); emitln(ftext, st);
        }
        return;
    }
    // Asignación compuesta: id op= expr
    if (node->node_type && strcmp(node->node_type, "AsignacionCompuesta") == 0) {
        AsignacionCompuestaExpresion *ac = (AsignacionCompuestaExpresion *)node;
        VarEntry *v = buscar_variable(ac->nombre);
        if (!v) return;
        if (v->is_const) { emitln(ftext, "    // asignación compuesta sobre constante ignorada"); return; }
        AbstractExpresion *rhs = node->hijos[0];
        int op = ac->op_type;
        // Cargar LHS según tipo
        if (op == '&' || op == '|' || op == '^' || op == TOKEN_LSHIFT || op == TOKEN_RSHIFT || op == TOKEN_URSHIFT) {
            // Operaciones enteras
            // lhs -> w19
            char l1[64]; snprintf(l1, sizeof(l1), "    ldr w19, [x29, -%d]", v->offset); emitln(ftext, l1);
            // rhs -> w20 (conv si double)
            TipoDato tr = emitir_eval_numerico(rhs, ftext);
            if (tr == DOUBLE) emitln(ftext, "    fcvtzs w20, d0"); else emitln(ftext, "    mov w20, w1");
            if (op == '&') emitln(ftext, "    and w1, w19, w20");
            else if (op == '|') emitln(ftext, "    orr w1, w19, w20");
            else if (op == '^') emitln(ftext, "    eor w1, w19, w20");
            else if (op == TOKEN_LSHIFT) emitln(ftext, "    lsl w1, w19, w20");
            else if (op == TOKEN_RSHIFT) emitln(ftext, "    asr w1, w19, w20");
            else /* TOKEN_URSHIFT */ emitln(ftext, "    lsr w1, w19, w20");
            // Guardar
            char st[64]; snprintf(st, sizeof(st), "    str w1, [x29, -%d]", v->offset); emitln(ftext, st);
        } else if (op == '+' || op == '-' || op == '*' || op == '/' || op == '%') {
            // Numérico con posible double
            // Cargar lhs
            if (v->tipo == DOUBLE || v->tipo == FLOAT) {
                char l1[64]; snprintf(l1, sizeof(l1), "    ldr d8, [x29, -%d]", v->offset); emitln(ftext, l1);
            } else {
                char l1[64]; snprintf(l1, sizeof(l1), "    ldr w19, [x29, -%d]", v->offset); emitln(ftext, l1);
            }
            TipoDato tr = emitir_eval_numerico(rhs, ftext);
            // Normalizar a double si cualquiera es double
            int use_fp = (v->tipo == DOUBLE || v->tipo == FLOAT || tr == DOUBLE);
            if (use_fp) {
                if (!(v->tipo == DOUBLE || v->tipo == FLOAT)) emitln(ftext, "    scvtf d8, w19");
                if (tr != DOUBLE) emitln(ftext, "    scvtf d9, w1"); else emitln(ftext, "    fmov d9, d0");
                if (op == '+') emitln(ftext, "    fadd d0, d8, d9");
                else if (op == '-') emitln(ftext, "    fsub d0, d8, d9");
                else if (op == '*') emitln(ftext, "    fmul d0, d8, d9");
                else if (op == '/') emitln(ftext, "    fdiv d0, d8, d9");
                else /* % */ {
                    emitln(ftext, "    fmov d0, d8");
                    emitln(ftext, "    fmov d1, d9");
                    emitln(ftext, "    bl fmod");
                }
                // Guardar double
                char st[64]; snprintf(st, sizeof(st), "    str d0, [x29, -%d]", v->offset); emitln(ftext, st);
            } else {
                // Entero
                if (op == '+') emitln(ftext, "    add w1, w19, w1");
                else if (op == '-') emitln(ftext, "    sub w1, w19, w1");
                else if (op == '*') emitln(ftext, "    mul w1, w19, w1");
                else if (op == '/') emitln(ftext, "    sdiv w1, w19, w1");
                else /* % */ { emitln(ftext, "    sdiv w21, w19, w1"); emitln(ftext, "    msub w1, w21, w1, w19"); }
                char st[64]; snprintf(st, sizeof(st), "    str w1, [x29, -%d]", v->offset); emitln(ftext, st);
            }
        }
        return;
    }
}

int arm64_generate_program(AbstractExpresion *root, const char *out_path) {
    // Crear carpeta de salida si no existe
    FILE *f = fopen(out_path, "w");
    if (!f) {
        // intentar crear carpeta "arm/" si la ruta lo contiene
        // estrategia simple: crear directorio arm/
        system("mkdir -p arm");
        f = fopen(out_path, "w");
        if (!f) return 1;
    }

    // Encabezado .data básico
    emitln(f, ".data\n");
    emitln(f, "// Cadenas de formato para printf (sin salto de línea) ");
    emitln(f, "fmt_int:        .asciz \"%d\"");
    emitln(f, "fmt_double:     .asciz \"%f\"");
    emitln(f, "fmt_string:     .asciz \"%s\"");
    emitln(f, "fmt_char:       .asciz \"%c\"\n");
    emitln(f, "true_str:       .asciz \"true\"");
    emitln(f, "false_str:      .asciz \"false\"\n");
    // Buffer temporal para String.valueOf (no reentrante)
    emitln(f, "tmpbuf:         .skip 1024\n");

    // Recorrer primero para llenar string literals durante gen
    // Generaremos .text primero para recolectar datos de dobles/strings
    // pero necesitamos escribir .data de strings antes de .text.
    // Solución: escribimos placeholder; generamos el cuerpo a un buffer temporal.

    // Emite .text y main
    emitln(f, ".text");
    emitln(f, ".global main\n");
    emitln(f, "main:");
    emitln(f, "    stp x29, x30, [sp, -16]!");
    emitln(f, "    mov x29, sp\n");

    // Para poder generar secciones .data adicionales (dobles y strings) después,
    // escribiremos código en un archivo temporal y luego insertaremos .data y .text en orden.
    // Simplificamos: guardamos el file pointer y generamos directo, y al final emitimos la parte .data restante.

    // Generación del cuerpo
    gen_node(f, root);

    // Epílogo
    // Epílogo de variables locales
    vars_epilogo(f);
    emitln(f, "\n    mov w0, #0");
    emitln(f, "    ldp x29, x30, [sp], 16");
    emitln(f, "    ret\n");

    // Volvemos a .data y emitimos literales recolectados (strings y doubles)
    core_emit_collected_literals(f);

    fclose(f);
    // liberar estructuras
    core_reset_literals();
    vars_reset();
    return 0;
}
