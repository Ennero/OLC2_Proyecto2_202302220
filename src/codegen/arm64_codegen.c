#include "codegen/arm64_codegen.h"
#include "ast/AbstractExpresion.h"
#include "ast/nodos/instrucciones/instrucciones.h"
#include "ast/nodos/expresiones/listaExpresiones.h"
#include "ast/nodos/instrucciones/instruccion/print.h"
#include "ast/nodos/instrucciones/instruccion/declaracion.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Pequeña util para escribir una línea en el archivo
static void emitln(FILE *f, const char *s) { fputs(s, f); fputc('\n', f); }

// Estructura simple para acumular literales string en .data
typedef struct StrLit {
    char *label;   // etiqueta en .data
    char *text;    // contenido asciz
    struct StrLit *next;
} StrLit;

static StrLit *str_head = NULL, *str_tail = NULL;
static int str_counter = 0;

static const char *add_string_literal(const char *text) {
    // Crear y registrar
    StrLit *n = (StrLit *)calloc(1, sizeof(StrLit));
    char label[64];
    snprintf(label, sizeof(label), "str_lit_%d", ++str_counter);
    n->label = strdup(label);
    n->text = strdup(text ? text : "");
    if (!str_head) str_head = n; else str_tail->next = n; str_tail = n;
    return n->label;
}

// Escapa comillas y backslashes para usar en .asciz
static char *escape_for_asciz(const char *s) {
    size_t len = strlen(s);
    // peor caso duplica
    char *out = (char *)malloc(len * 4 + 1);
    size_t j = 0;
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char)s[i];
        switch (c) {
            case '"':
                out[j++] = '\\'; out[j++] = '"';
                break;
            case '\\':
                out[j++] = '\\'; out[j++] = '\\';
                break;
            case '\n':
                out[j++] = '\\'; out[j++] = 'n';
                break;
            case '\t':
                out[j++] = '\\'; out[j++] = 't';
                break;
            case '\r':
                out[j++] = '\\'; out[j++] = 'r';
                break;
            default:
                out[j++] = c;
        }
    }
    out[j] = '\0';
    return out;
}

// ----------------- Gestión simple de variables locales -----------------
typedef struct VarEntry {
    char *name;
    TipoDato tipo;
    int offset; // bytes desde x29 hacia abajo (usamos [x29, -offset])
    struct VarEntry *next;
} VarEntry;

static VarEntry *vars_head = NULL;
static int local_bytes = 0; // total actual reservado con sub sp, sp, #...

static VarEntry *find_var(const char *name) {
    for (VarEntry *v = vars_head; v; v = v->next) {
        if (strcmp(v->name, name) == 0) return v;
    }
    return NULL;
}

static VarEntry *add_var(const char *name, TipoDato tipo, int size_bytes, FILE *ftext) {
    // Alinear a 8 bytes
    int sz = size_bytes;
    if (sz % 8 != 0) sz = ((sz / 8) + 1) * 8;
    // Reservar en stack
    local_bytes += sz;
    char line[64];
    snprintf(line, sizeof(line), "    sub sp, sp, #%d", sz);
    emitln(ftext, line);
    VarEntry *v = (VarEntry *)calloc(1, sizeof(VarEntry));
    v->name = strdup(name);
    v->tipo = tipo;
    v->offset = local_bytes; // desde x29 hacia abajo
    v->next = vars_head;
    vars_head = v;
    return v;
}

// ----------------- Emisión de expresiones -----------------
// Devuelve 1 si el árbol es de concatenación (contiene string en algún lado)
static int expr_is_stringy(AbstractExpresion *node) {
    if (!node) return 0;
    const char *t = node->node_type ? node->node_type : "";
    if (strcmp(t, "Primitivo") == 0) {
        PrimitivoExpresion *p = (PrimitivoExpresion *)node;
        return p->tipo == STRING;
    }
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = find_var(id->nombre);
        return v && v->tipo == STRING;
    }
    if (strcmp(t, "Suma") == 0) {
        return expr_is_stringy(node->hijos[0]) || expr_is_stringy(node->hijos[1]);
    }
    return 0;
}

// Evalúa una expresión numérica a:
// - INT en w1
// - DOUBLE en d0
// Retorna el TipoDato del resultado (INT o DOUBLE)
static TipoDato emit_eval_numeric(AbstractExpresion *node, FILE *ftext) {
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
                } else { // CHAR básico
                    v = (unsigned char)p->valor[0];
                }
            }
            char line[64]; snprintf(line, sizeof(line), "    mov w1, #%ld", v); emitln(ftext, line);
            return INT;
        } else if (p->tipo == DOUBLE || p->tipo == FLOAT) {
            char lab[64]; snprintf(lab, sizeof(lab), "dbl_lit_%d", (int)++str_counter);
            char ref[128]; snprintf(ref, sizeof(ref), "    ldr x16, =%s\n    ldr d0, [x16]", lab); emitln(ftext, ref);
            // registrar el literal
            StrLit *n = (StrLit *)calloc(1, sizeof(StrLit)); n->label = strdup(lab); n->text = strdup(p->valor ? p->valor : "0");
            if (!str_head) str_head = n; else str_tail->next = n; str_tail = n;
            return DOUBLE;
        }
    } else if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = find_var(id->nombre);
        if (!v) return INT;
        if (v->tipo == DOUBLE || v->tipo == FLOAT) {
            char line[64]; snprintf(line, sizeof(line), "    ldr d0, [x29, -%d]", v->offset); emitln(ftext, line);
            return DOUBLE;
        } else { // INT/BOOLEAN/CHAR
            char line[64]; snprintf(line, sizeof(line), "    ldr w1, [x29, -%d]", v->offset); emitln(ftext, line);
            return INT;
        }
    } else if (strcmp(t, "Suma") == 0) {
        // Evaluar ambos lados
        // Lado izquierdo
        TipoDato tl;
        tl = emit_eval_numeric(node->hijos[0], ftext); // result in w1 or d0
        // mover a temporales
        if (tl == DOUBLE) emitln(ftext, "    fmov d8, d0"); else emitln(ftext, "    mov w19, w1");
        // Lado derecho
        TipoDato tr = emit_eval_numeric(node->hijos[1], ftext); // now in w1 or d0
        if (tr == DOUBLE) emitln(ftext, "    fmov d9, d0"); else emitln(ftext, "    mov w20, w1");
        // Determinar tipo resultado
        if (tl == DOUBLE || tr == DOUBLE) {
            // Convertir ints a double si hace falta
            if (tl != DOUBLE) emitln(ftext, "    scvtf d8, w19");
            if (tr != DOUBLE) emitln(ftext, "    scvtf d9, w20");
            emitln(ftext, "    fadd d0, d8, d9");
            return DOUBLE;
        } else {
            emitln(ftext, "    add w1, w19, w20");
            return INT;
        }
    }
    // Por defecto, 0
    emitln(ftext, "    mov w1, #0");
    return INT;
}

// Emite las partes de una expresión stringy en orden (sin salto de línea)
static void emit_print_stringy(AbstractExpresion *node, FILE *ftext) {
    const char *t = node->node_type ? node->node_type : "";
    if (strcmp(t, "Suma") == 0) {
        // Si esta suma NO es stringy, evalúala completa como número (respeta paréntesis)
        if (!expr_is_stringy(node)) {
            TipoDato ty = emit_eval_numeric(node, ftext);
            if (ty == DOUBLE) emitln(ftext, "    ldr x0, =fmt_double"); else emitln(ftext, "    ldr x0, =fmt_int");
            emitln(ftext, "    bl printf");
            return;
        }
        // Caso contrario, descompón en partes stringy
        emit_print_stringy(node->hijos[0], ftext);
        emit_print_stringy(node->hijos[1], ftext);
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
        } else if (p->tipo == INT || p->tipo == CHAR || p->tipo == BOOLEAN) {
            // numérico como texto
            TipoDato ty = emit_eval_numeric(node, ftext);
            if (ty == INT) {
                emitln(ftext, "    ldr x0, =fmt_int");
                emitln(ftext, "    bl printf");
            } else {
                emitln(ftext, "    ldr x0, =fmt_double");
                emitln(ftext, "    bl printf");
            }
            return;
        } else { // double/float
            (void)emit_eval_numeric(node, ftext);
            emitln(ftext, "    ldr x0, =fmt_double");
            emitln(ftext, "    bl printf");
            return;
        }
    }
    if (strcmp(t, "Identificador") == 0) {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = find_var(id->nombre);
        if (v && v->tipo == STRING) {
            char l1[64]; snprintf(l1, sizeof(l1), "    ldr x1, [x29, -%d]", v->offset); emitln(ftext, l1);
            emitln(ftext, "    ldr x0, =fmt_string");
            emitln(ftext, "    bl printf");
        } else if (v) {
            // numérico
            if (v->tipo == DOUBLE || v->tipo == FLOAT) {
                char l1[64]; snprintf(l1, sizeof(l1), "    ldr d0, [x29, -%d]", v->offset); emitln(ftext, l1);
                emitln(ftext, "    ldr x0, =fmt_double");
                emitln(ftext, "    bl printf");
            } else {
                char l1[64]; snprintf(l1, sizeof(l1), "    ldr w1, [x29, -%d]", v->offset); emitln(ftext, l1);
                if (v->tipo == CHAR) {
                    emitln(ftext, "    ldr x0, =fmt_char");
                } else if (v->tipo == BOOLEAN) {
                    // mapear a true/false
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
        }
        return;
    }
    // fallback: eval numérico
    TipoDato ty = emit_eval_numeric(node, ftext);
    if (ty == DOUBLE) emitln(ftext, "    ldr x0, =fmt_double"); else emitln(ftext, "    ldr x0, =fmt_int");
    emitln(ftext, "    bl printf");
}

// Recorre el árbol emitiendo código para Print con literales primitivos
static void gen_node(FILE *ftext, AbstractExpresion *node) {
    if (!node) return;

    // Recorremos primero hijos (pre-orden simple para statements)
    for (size_t i = 0; i < node->numHijos; i++) {
        gen_node(ftext, node->hijos[i]);
    }

    // Detectar por node_type minimalista
    if (node->node_type && strcmp(node->node_type, "Instrucciones") == 0) {
        // ya recorremos hijos arriba
        return;
    }
    if (node->node_type && strcmp(node->node_type, "Bloque") == 0) {
        return;
    }
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
        VarEntry *v = add_var(decl->nombre, decl->tipo, size, ftext);
        if (node->numHijos > 0) {
            AbstractExpresion *init = node->hijos[0];
            if (decl->tipo == DOUBLE || decl->tipo == FLOAT) {
                (void)emit_eval_numeric(init, ftext); // d0
                char st[64]; snprintf(st, sizeof(st), "    str d0, [x29, -%d]", v->offset); emitln(ftext, st);
            } else if (decl->tipo == STRING) {
                if (strcmp(init->node_type, "Primitivo") == 0) {
                    PrimitivoExpresion *p = (PrimitivoExpresion *)init;
                    const char *lab = add_string_literal(p->valor ? p->valor : "");
                    char l1[64]; snprintf(l1, sizeof(l1), "    ldr x1, =%s", lab); emitln(ftext, l1);
                    char st[64]; snprintf(st, sizeof(st), "    str x1, [x29, -%d]", v->offset); emitln(ftext, st);
                }
            } else {
                (void)emit_eval_numeric(init, ftext); // w1
                char st[64]; snprintf(st, sizeof(st), "    str w1, [x29, -%d]", v->offset); emitln(ftext, st);
            }
        } else {
            // Valor por defecto 0/false/null
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

        // Imprimimos cada expr seguido de espacio (excepto la última), luego un \n
        for (size_t i = 0; i < lista->numHijos; i++) {
            AbstractExpresion *expr = lista->hijos[i];
            // Si es concatenación (stringy), imprimir sus partes
            if (expr_is_stringy(expr)) {
                emit_print_stringy(expr, ftext);
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
                            char lab[64];
                            snprintf(lab, sizeof(lab), "dbl_lit_%d", (int)++str_counter);
                            // Registrar en lista de strings como hack? Mejor lo escribimos directo desde .text usando etiqueta
                            // Aquí solo emitimos carga de esa etiqueta; la sección .data se generará en arm64_generate_program.
                            char ref[128];
                            snprintf(ref, sizeof(ref), "    ldr x16, =%s\n    ldr d0, [x16]", lab);
                            emitln(ftext, ref);
                            emitln(ftext, "    bl printf");
                            // Guardamos temporalmente el label en next de str list con texto especial "#DOUBLE:" para la fase .data
                            StrLit *n = (StrLit *)calloc(1, sizeof(StrLit));
                            n->label = strdup(lab);
                            n->text = strdup(p->valor ? p->valor : "0"); // guardamos el literal como texto
                            if (!str_head) str_head = n; else str_tail->next = n; str_tail = n;
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
                            // muy básico: soportar \\n, \\t, \\r, \\'
                            int v = 0;
                            switch (p->valor[1]) {
                                case 'n': v = '\n'; break;
                                case 't': v = '\t'; break;
                                case 'r': v = '\r'; break;
                                case '\\': v = '\\'; break;
                                case '\'': v = '\''; break;
                                default: v = (unsigned char)p->valor[1]; break;
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
                VarEntry *v = find_var(id->nombre);
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
            } else if (expr->node_type && strcmp(expr->node_type, "Suma") == 0) {
                // Si no es stringy, evaluar como numérico y luego imprimir
                TipoDato ty = emit_eval_numeric(expr, ftext);
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
    if (local_bytes > 0) {
        char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", local_bytes); emitln(f, addb);
    }
    emitln(f, "\n    mov w0, #0");
    emitln(f, "    ldp x29, x30, [sp], 16");
    emitln(f, "    ret\n");

    // Volvemos a .data y emitimos literales recolectados (strings y doubles)
    emitln(f, "// --- Literales recolectados ---");
    emitln(f, ".data");
    for (StrLit *n = str_head; n; n = n->next) {
        // Si es un label de double "dbl_lit_X" entonces emitir .double
        if (strncmp(n->label, "dbl_lit_", 8) == 0) {
            // n->text contiene el literal como string
            char line[256];
            snprintf(line, sizeof(line), "%s:    .double %s", n->label, n->text);
            emitln(f, line);
        } else {
            // tratar como string asciz
            char *esc = escape_for_asciz(n->text);
            char line[512];
            snprintf(line, sizeof(line), "%s:    .asciz \"%s\"", n->label, esc);
            emitln(f, line);
            free(esc);
        }
    }

    fclose(f);
    // liberar lista
    while (str_head) {
        StrLit *nx = str_head->next;
        free(str_head->label);
        free(str_head->text);
        free(str_head);
        str_head = nx;
    }
    str_tail = NULL;
    str_counter = 0;
    // liberar tabla de variables
    while (vars_head) {
        VarEntry *nx = vars_head->next;
        free(vars_head->name);
        free(vars_head);
        vars_head = nx;
    }
    local_bytes = 0;
    return 0;
}
