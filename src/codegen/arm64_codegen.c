#include "codegen/arm64_codegen.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_print.h"
#include "codegen/arm64_globals.h"
#include "ast/nodos/estructuras/funciones/funcion.h"
#include "ast/nodos/estructuras/funciones/llamada.h"
#include "ast/nodos/estructuras/funciones/parametro.h"
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
#include "codegen/instrucciones/arm64_flujo.h"
#include "codegen/instrucciones/arm64_condicionales.h"
#include "codegen/instrucciones/arm64_ciclos.h"
#include "parser.tab.h" // Para tokens como TOKEN_LSHIFT en asignaciones compuestas
#include "codegen/funciones/arm64_funciones.h"
#include "codegen/instrucciones/arm64_declaraciones.h"
#include "codegen/instrucciones/arm64_reasignaciones.h"
#include "codegen/instrucciones/arm64_asignacion_compuesta.h"
#include "codegen/instrucciones/arm64_print_stmt.h"
#include "codegen/estructuras/arm64_arreglos.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Atributo para silenciar warnings de funciones no usadas (GCC/Clang)
#ifndef UNUSED
#define UNUSED __attribute__((unused))
#endif

// Pequeña util para escribir una línea en el archivo (delegar a core)
static void emitln(FILE *f, const char *s) {
#ifdef ARM64_EMIT_GUARD
    // Guard: evitar direccionamiento inmediato FP-relativo [x29, -imm]
    if (s && strstr(s, "[x29, -") != NULL) {
        fprintf(stderr, "WARN(codegen): emisión contiene [x29, -...]: %s\n", s);
    }
#endif
    core_emitln(f, s);
}

// Delegar manejo de literales a core (mantener API histórica)
// Se delega directamente donde se requiera, evitamos helpers locales sin uso

// escape_for_asciz movido a core

// ----------------- Gestión simple de variables locales -----------------
// Variables locales delegadas a arm64_vars
// Tip alias para compatibilidad local
typedef VarEntry VarEntry;

// ----------------- Helpers de labels -----------------
// Etiquetas via helpers compartidos en flujo
static void emit_label(FILE *f, const char *prefix, int id) { flujo_emit_label(f, prefix, id); }

// ----------------- Pila simple de labels para 'break' -----------------
// break/continue delegados a flujo helpers
static void break_push(int id) UNUSED;
static void break_push(int id) { flujo_break_push(id); }
static int break_peek(void) { return flujo_break_peek(); }
static void break_pop(void) UNUSED;
static void break_pop(void) { flujo_break_pop(); }

// ----------------- Pila simple de labels para 'continue' (loops) -----------------
static void continue_push(int id) UNUSED;
static void continue_push(int id) { flujo_continue_push(id); }
static int continue_peek(void) { return flujo_continue_peek(); }
static void continue_pop(void) UNUSED;
static void continue_pop(void) { flujo_continue_pop(); }

// ----------------- Etiqueta global de salida de función para 'return' -----------------
static int __current_func_exit_id = -1;
static int __is_main_context = 0;
static TipoDato __current_func_ret = NULO;

// Registro de funciones movido a codegen/funciones/arm64_funciones.*

// ----------------- Recolección de variables globales -----------------
static void globals_collect(AbstractExpresion *n) {
    if (!n) return;
    if (n->node_type && strcmp(n->node_type, "Declaracion") == 0) {
        DeclaracionVariable *d = (DeclaracionVariable *)n;
        // Solo file-scope: heurística simple, considerar global si no estamos dentro de función: este recolector se llama en raíz.
        // Arrays globales no soportados aún en codegen: ignorar si dimensiones > 0
        if (d->dimensiones == 0) {
            AbstractExpresion *init = (n->numHijos > 0) ? n->hijos[0] : NULL;
            globals_register(d->nombre, d->tipo, d->es_constante ? 1 : 0, init);
        }
    }
    for (size_t i = 0; i < n->numHijos; ++i) globals_collect(n->hijos[i]);
}

// ----------------- Emisión de llamada a función -----------------
// Devuelve el tipo de retorno; para INT-like deja w1 con el valor; para DOUBLE deja d0
// Emisión de llamadas a función movido a arm64_funciones

// ----------------- Helpers de runtime para arreglos (flat) -----------------
// new_array_flat(dims=w0, sizes_ptr=x1) -> x0: puntero a cabecera
//  [align8] : int data[prod(sizes)]
// Helpers de arrays movidos a codegen/estructuras/arm64_arreglos.*

// ----------------- Emisión de expresiones -----------------
// Implementaciones movidas a codegen/expresiones/*.c (arm64_num.c, arm64_bool.c, arm64_print.c)

// Recorre el árbol emitiendo código para Print con literales primitivos
static void gen_node(FILE *ftext, AbstractExpresion *node) {
    if (!node) return;
    // Ignorar declaraciones de funciones en codegen (solo generamos el cuerpo de 'main')
    if (node->node_type && strcmp(node->node_type, "FunctionDeclaration") == 0) {
        return;
    }
    // Llamadas a función como sentencia
    if (node->node_type && strcmp(node->node_type, "FunctionCall") == 0) {
        (void)arm64_emitir_llamada_funcion(node, ftext);
        return;
    }
    // Delegar condicionales y ciclos a módulos especializados
    if (arm64_emitir_condicional(node, ftext, (EmitirNodoFn)gen_node)) return;
    if (arm64_emitir_ciclo(node, ftext, (EmitirNodoFn)gen_node)) return;
    // ReturnStatement: evaluar opcionalmente la expresión y saltar al epílogo
    if (node->node_type && strcmp(node->node_type, "ReturnStatement") == 0) {
        if (node->numHijos > 0 && node->hijos[0]) {
            AbstractExpresion *rhs = node->hijos[0];
            // Evaluar expresión de retorno
            if (__is_main_context) {
                // En main, retornar código de salida (int en w0)
                if (nodo_es_resultado_booleano(rhs) || (rhs->node_type && strcmp(rhs->node_type, "Primitivo") == 0) || (rhs->node_type && strcmp(rhs->node_type, "Identificador") == 0) || (rhs->node_type && strcmp(rhs->node_type, "Suma") == 0) || (rhs->node_type && strcmp(rhs->node_type, "Resta") == 0) || (rhs->node_type && strcmp(rhs->node_type, "Multiplicacion") == 0) || (rhs->node_type && strcmp(rhs->node_type, "Division") == 0) || (rhs->node_type && strcmp(rhs->node_type, "Modulo") == 0) || (rhs->node_type && strcmp(rhs->node_type, "NegacionUnaria") == 0) || (rhs->node_type && strcmp(rhs->node_type, "Casteo") == 0)) {
                    TipoDato ty = emitir_eval_numerico(rhs, ftext);
                    if (ty == DOUBLE) emitln(ftext, "    fcvtzs w0, d0"); else emitln(ftext, "    mov w0, w1");
                } else if (expresion_es_cadena(rhs)) {
                    emitln(ftext, "    mov w0, #0");
                } else {
                    emitln(ftext, "    mov w0, #0");
                }
            } else {
                // En funciones: colocar retorno en registro segun tipo
                if (__current_func_ret == DOUBLE || __current_func_ret == FLOAT) {
                    TipoDato ty = emitir_eval_numerico(rhs, ftext);
                    if (ty != DOUBLE) emitln(ftext, "    scvtf d0, w1");
                    // d0 lleva retorno
                } else if (__current_func_ret == STRING) {
                    // Evaluar puntero a string en x1 -> mover a x0
                    if (!emitir_eval_string_ptr(rhs, ftext)) emitln(ftext, "    mov x1, #0");
                    emitln(ftext, "    mov x0, x1");
                } else {
                    // Escalares int/bool/char -> w0
                    TipoDato ty = emitir_eval_numerico(rhs, ftext);
                    if (ty == DOUBLE) emitln(ftext, "    fcvtzs w0, d0"); else emitln(ftext, "    mov w0, w1");
                }
            }
        }
        if (__current_func_exit_id >= 0) {
            // Saltar al epílogo de función; ahí se restaurará el stack con vars_epilogo
            char br[64]; snprintf(br, sizeof(br), "    b L_func_exit_%d", __current_func_exit_id); emitln(ftext, br);
        } else {
            // No hay etiqueta de función (no debería ocurrir); emitir epílogo inline mínimo
            emitln(ftext, "    // return fuera de contexto; epílogo inline");
            emitln(ftext, "    ldp x29, x30, [sp], 16");
            emitln(ftext, "    ret");
        }
        return;
    }
    // ContinueStatement: saltar a la etiqueta de continuación más cercana (si existe)
    if (node->node_type && strcmp(node->node_type, "ContinueStatement") == 0) {
        int cid = continue_peek();
        if (cid >= 0) {
            char cbr[64]; snprintf(cbr, sizeof(cbr), "    b L_continue_%d", cid); emitln(ftext, cbr);
        } else {
            emitln(ftext, "    // 'continue' fuera de bucle; ignorado en codegen");
        }
        return;
    }
    // BreakStatement: salto a etiqueta de ruptura más cercana (switch/loop)
    if (node->node_type && strcmp(node->node_type, "BreakStatement") == 0) {
        int bid = break_peek();
        if (bid >= 0) {
            char brk[64]; snprintf(brk, sizeof(brk), "    b L_break_%d", bid); emitln(ftext, brk);
        } else {
            emitln(ftext, "    // 'break' fuera de contexto; ignorado en codegen");
        }
        return;
    }
    // IfStatement: emitir saltos con labels y no recorrer hijos antes
    // If/Switch fueron absorbidos por arm64_condicionales
    // Manejo especial de bloques: crean un nuevo alcance de variables
    if (node->node_type && strcmp(node->node_type, "Bloque") == 0) {
        vars_push_scope(ftext);
        for (size_t i = 0; i < node->numHijos; i++) {
            gen_node(ftext, node->hijos[i]);
        }
        vars_pop_scope(ftext);
        return;
    }

    // Switch también delegado

    // While delegado

    // For delegado

    // Recorremos primero hijos (pre-orden simple para statements) excepto Bloque/IfStatement (ya manejados)
    for (size_t i = 0; i < node->numHijos; i++) {
        if (!node->hijos[i]) continue;
        if (node->hijos[i]->node_type && (strcmp(node->hijos[i]->node_type, "Bloque") == 0 || strcmp(node->hijos[i]->node_type, "IfStatement") == 0)) {
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
    if (arm64_emitir_declaracion(node, ftext)) return;
    if (arm64_emitir_asignacion_arreglo(node, ftext)) return;
    if (arm64_emitir_print_stmt(node, ftext)) return;
    // Reasignación simple: id = expr
    if (arm64_emitir_reasignacion(node, ftext)) return;
    // Asignación compuesta: id op= expr
    if (arm64_emitir_asignacion_compuesta(node, ftext)) return;
}

// Búsqueda recursiva del nodo MainFunction en el AST (file-scope)
static AbstractExpresion *find_main(AbstractExpresion *n) {
    if (!n) return NULL;
    if (n->node_type && strcmp(n->node_type, "MainFunction") == 0) return n;
    for (size_t i = 0; i < n->numHijos; ++i) {
        AbstractExpresion *m = find_main(n->hijos[i]);
        if (m) return m;
    }
    return NULL;
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
    emitln(f, "null_str:       .asciz \"null\"\n");
    // Buffer temporal para String.valueOf (no reentrante)
    emitln(f, "tmpbuf:         .skip 1024");
    // Buffer para codificación UTF-8 de un solo carácter
    emitln(f, "charbuf:        .skip 8\n");

    // Recorrer primero para llenar string literals durante gen
    // Generaremos .text primero para recolectar datos de dobles/strings
    // pero necesitamos escribir .data de strings antes de .text.
    // Solución: escribimos placeholder; generamos el cuerpo a un buffer temporal.

    // Emite .text, helpers y funciones declaradas
    emitln(f, ".text");
    emitln(f, ".global main\n");
    // Helpers de arreglos y utilidades (definiciones en .text)
    arm64_emit_runtime_arreglo_helpers(f);
    // Helper para convertir code point (w0) a UTF-8 en charbuf y devolver puntero en x0
    emitln(f, "// --- Helper: char_to_utf8(w0->x0) ---");
    emitln(f, "char_to_utf8:");
    emitln(f, "    // preservar code point en w9 y preparar puntero de salida en x0");
    emitln(f, "    mov w9, w0");
    emitln(f, "    ldr x1, =charbuf");
    emitln(f, "    mov x0, x1");
    emitln(f, "    // if cp <= 0x7F -> 1 byte");
    emitln(f, "    mov w2, #0x7F");
    emitln(f, "    cmp w9, w2");
    emitln(f, "    b.hi 1f");
    emitln(f, "    // 1-byte ASCII");
    emitln(f, "    strb w9, [x1]");
    emitln(f, "    mov w3, #0");
    emitln(f, "    strb w3, [x1, #1]");
    emitln(f, "    ret");
    emitln(f, "1:");
    emitln(f, "    // if cp <= 0x7FF -> 2 bytes");
    emitln(f, "    mov w2, #0x7FF");
    emitln(f, "    cmp w9, w2");
    emitln(f, "    b.hi 2f");
    emitln(f, "    // 2 bytes: 110xxxxx 10xxxxxx");
    emitln(f, "    ubfx w4, w9, #6, #5");
    emitln(f, "    orr w4, w4, #0xC0");
    emitln(f, "    strb w4, [x1]");
    emitln(f, "    and w5, w9, #0x3F");
    emitln(f, "    orr w5, w5, #0x80");
    emitln(f, "    strb w5, [x1, #1]");
    emitln(f, "    mov w3, #0");
    emitln(f, "    strb w3, [x1, #2]");
    emitln(f, "    ret");
    emitln(f, "2:");
    emitln(f, "    // if cp <= 0xFFFF -> 3 bytes");
    emitln(f, "    mov w2, #0xFFFF");
    emitln(f, "    cmp w9, w2");
    emitln(f, "    b.hi 3f");
    emitln(f, "    // 3 bytes: 1110xxxx 10xxxxxx 10xxxxxx");
    emitln(f, "    ubfx w4, w9, #12, #4");
    emitln(f, "    orr w4, w4, #0xE0");
    emitln(f, "    strb w4, [x1]");
    emitln(f, "    ubfx w5, w9, #6, #6");
    emitln(f, "    orr w5, w5, #0x80");
    emitln(f, "    strb w5, [x1, #1]");
    emitln(f, "    and w6, w9, #0x3F");
    emitln(f, "    orr w6, w6, #0x80");
    emitln(f, "    strb w6, [x1, #2]");
    emitln(f, "    mov w3, #0");
    emitln(f, "    strb w3, [x1, #3]");
    emitln(f, "    ret");
    emitln(f, "3:");
    emitln(f, "    // 4 bytes: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx");
    emitln(f, "    ubfx w4, w9, #18, #3");
    emitln(f, "    orr w4, w4, #0xF0");
    emitln(f, "    strb w4, [x1]");
    emitln(f, "    ubfx w5, w9, #12, #6");
    emitln(f, "    orr w5, w5, #0x80");
    emitln(f, "    strb w5, [x1, #1]");
    emitln(f, "    ubfx w6, w9, #6, #6");
    emitln(f, "    orr w6, w6, #0x80");
    emitln(f, "    strb w6, [x1, #2]");
    emitln(f, "    and w7, w9, #0x3F");
    emitln(f, "    orr w7, w7, #0x80");
    emitln(f, "    strb w7, [x1, #3]");
    emitln(f, "    mov w3, #0");
    emitln(f, "    strb w3, [x1, #4]");
    emitln(f, "    ret\n");

    // --- Helpers: String.join sobre arreglos 1D ---
    emitln(f, "// join_array_strings(x0=arr_ptr, x1=delim) -> x0=tmpbuf");
    emitln(f, "join_array_strings:");
    emitln(f, "    stp x29, x30, [sp, -16]!");
    emitln(f, "    mov x29, sp");
    emitln(f, "    sub sp, sp, #48");
    emitln(f, "    stp x19, x20, [sp, #0]");
    emitln(f, "    stp x21, x22, [sp, #16]");
    emitln(f, "    stp x23, x24, [sp, #32]");
    emitln(f, "    mov x9, x0"); // arr
    emitln(f, "    mov x23, x1"); // preserve delim in callee-saved
    // header size align
    emitln(f, "    ldr w12, [x9]");
    emitln(f, "    mov x15, #8");
    emitln(f, "    uxtw x16, w12");
    emitln(f, "    lsl x16, x16, #2");
    emitln(f, "    add x15, x15, x16");
    emitln(f, "    add x17, x15, #7");
    emitln(f, "    and x17, x17, #-8");
    emitln(f, "    add x18, x9, #8"); // sizes base
    emitln(f, "    ldr w19, [x18]"); // n
    // compute data base in callee-saved x21 to survive calls
    emitln(f, "    add x21, x9, x17");
    emitln(f, "    ldr x0, =tmpbuf");
    emitln(f, "    mov w2, #0");
    emitln(f, "    strb w2, [x0]");
    emitln(f, "    mov w20, #0"); // i
    emitln(f, "1:");
    emitln(f, "    cmp w20, w19");
    emitln(f, "    b.ge 2f");
    emitln(f, "    // if i>0 append delim");
    emitln(f, "    cbz w20, 3f");
    emitln(f, "    // x0 already points to tmpbuf");
    emitln(f, "    mov x1, x23");
    emitln(f, "    bl strcat");
    emitln(f, "3:");
    emitln(f, "    // load element ptr from data base (x21) + i*8");
    emitln(f, "    add x22, x21, x20, lsl #3");
    emitln(f, "    ldr x22, [x22]");
    emitln(f, "    cbnz x22, 4f");
    emitln(f, "    ldr x22, =null_str");
    emitln(f, "4:");
    emitln(f, "    mov x1, x22");
    emitln(f, "    bl strcat");
    emitln(f, "    add w20, w20, #1");
    emitln(f, "    b 1b");
    emitln(f, "2:");
    emitln(f, "    ldp x23, x24, [sp, #32]");
    emitln(f, "    ldp x21, x22, [sp, #16]");
    emitln(f, "    ldp x19, x20, [sp, #0]");
    emitln(f, "    add sp, sp, #48");
    emitln(f, "    ldp x29, x30, [sp], 16");
    emitln(f, "    ret\n");

    emitln(f, "// join_array_ints(x0=arr_ptr, x1=delim) -> x0=tmpbuf");
    emitln(f, "join_array_ints:");
    emitln(f, "    stp x29, x30, [sp, -16]!");
    emitln(f, "    mov x29, sp");
    emitln(f, "    sub sp, sp, #112"); // 48(save regs) + 64(intbuf)
    emitln(f, "    stp x19, x20, [sp, #0]");
    emitln(f, "    stp x21, x22, [sp, #16]");
    emitln(f, "    stp x23, x24, [sp, #32]");
    emitln(f, "    mov x9, x0");
    emitln(f, "    mov x23, x1"); // preserve delim
    emitln(f, "    ldr w12, [x9]");
    emitln(f, "    mov x15, #8");
    emitln(f, "    uxtw x16, w12");
    emitln(f, "    lsl x16, x16, #2");
    emitln(f, "    add x15, x15, x16");
    emitln(f, "    add x17, x15, #7");
    emitln(f, "    and x17, x17, #-8");
    emitln(f, "    add x18, x9, #8");
    emitln(f, "    ldr w19, [x18]");
    // compute data base in x21
    emitln(f, "    add x21, x9, x17");
    emitln(f, "    ldr x0, =tmpbuf");
    emitln(f, "    mov w2, #0");
    emitln(f, "    strb w2, [x0]");
    emitln(f, "    mov w20, #0");
    emitln(f, "1:");
    emitln(f, "    cmp w20, w19");
    emitln(f, "    b.ge 2f");
    emitln(f, "    cbz w20, 3f");
    emitln(f, "    mov x1, x23");
    emitln(f, "    bl strcat");
    emitln(f, "3:");
    emitln(f, "    add x22, x21, x20, lsl #2");
    emitln(f, "    ldr w22, [x22]");
    emitln(f, "    add x0, sp, #48"); // int buffer after saved regs
    emitln(f, "    ldr x1, =fmt_int");
    emitln(f, "    mov w2, w22");
    emitln(f, "    bl sprintf");
    emitln(f, "    add x1, sp, #48");
    emitln(f, "    ldr x0, =tmpbuf");
    emitln(f, "    bl strcat");
    emitln(f, "    ldr x0, =tmpbuf");
    emitln(f, "    add w20, w20, #1");
    emitln(f, "    b 1b");
    emitln(f, "2:");
    emitln(f, "    ldp x23, x24, [sp, #32]");
    emitln(f, "    ldp x21, x22, [sp, #16]");
    emitln(f, "    ldp x19, x20, [sp, #0]");
    emitln(f, "    add sp, sp, #112");
    emitln(f, "    ldp x29, x30, [sp], 16");
    emitln(f, "    ret\n");
    // Recolectar funciones del AST
    arm64_funciones_reset();
    arm64_funciones_colectar(root);
    // Recolectar globales
    globals_reset();
    globals_collect(root);

    // Emitir cada función como fn_<nombre>
    for (int i = 0; i < arm64_funciones_count(); ++i) {
        const Arm64FuncionInfo *fi = arm64_funciones_get(i);
        // Reset de estado de variables por función
        vars_reset();
        char lab[128]; snprintf(lab, sizeof(lab), "fn_%s:", fi->name); emitln(f, lab);
        emitln(f, "    stp x29, x30, [sp, -16]!");
        emitln(f, "    mov x29, sp");
    // Reservar frame completo para locales una sola vez (se ajustará tras conocer local_bytes)
    // De momento, posponemos hasta después de declarar parámetros. Guardamos etiqueta para inserción.
        // Preparar estado de retorno para ReturnStatement
        __is_main_context = 0;
        __current_func_ret = fi->ret;
        __current_func_exit_id = flujo_next_label_id();
        // Crear variables locales para parámetros y mover desde registros de llamada
        for (int p = 0; p < fi->param_count && p < 8; ++p) {
            int size = (fi->param_types[p] == DOUBLE || fi->param_types[p] == FLOAT) ? 8 : 8;
            VarEntry *v = vars_agregar_ext(fi->param_names[p], fi->param_types[p], size, 0, f);
            if (fi->param_types[p] == DOUBLE || fi->param_types[p] == FLOAT) {
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d%d, [x16]", v->offset, p); emitln(f, st);
            } else if (fi->param_types[p] == STRING) {
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x%d, [x16]", v->offset, p); emitln(f, st);
            } else {
                char st[96]; snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w%d, [x16]", v->offset, p); emitln(f, st);
            }
        }
        // Reservas de locales se harán on-demand en vars_agregar; no reservar aquí
        // Generar cuerpo
        gen_node(f, fi->body);
        // Salida de función
        emit_label(f, "L_func_exit", __current_func_exit_id);
        __current_func_exit_id = -1;
        // Restaurar stack de variables locales (reset a FP) y epílogo estándar
        emitln(f, "    mov sp, x29");
        emitln(f, "    ldp x29, x30, [sp], 16");
        emitln(f, "    ret\n");
        // Fin de función; continuar con la siguiente
    }

    // Ahora main
    vars_reset();
    emitln(f, "main:");
    emitln(f, "    stp x29, x30, [sp, -16]!");
    emitln(f, "    mov x29, sp\n");
    // Reservar frame completo de main tras conocer local_bytes; de inicio 0, se actualizará después de declarar

    // Para poder generar secciones .data adicionales (dobles y strings) después,
    // escribiremos código en un archivo temporal y luego insertaremos .data y .text en orden.
    // Simplificamos: guardamos el file pointer y generamos directo, y al final emitimos la parte .data restante.

    // Establecer etiqueta de salida para 'return'
    __is_main_context = 1;
    __current_func_ret = INT;
    __current_func_exit_id = flujo_next_label_id();

    // Buscar nodo de entrada (MainFunction) para garantizar que ejecutamos 'main' sin importar el orden
    AbstractExpresion *entry = find_main(root);
    if (!entry) entry = root; // fallback: generar desde la raíz si no existe main

    // Generación del cuerpo sólo desde 'main'
    gen_node(f, entry);

    // Etiqueta de salida de función (usada por 'return')
    emit_label(f, "L_func_exit", __current_func_exit_id);
    __current_func_exit_id = -1;

    // Epílogo
    // Epílogo de variables locales (reset a FP)
    emitln(f, "    mov sp, x29");
    emitln(f, "\n    mov w0, #0");
    emitln(f, "    ldp x29, x30, [sp], 16");
    emitln(f, "    ret\n");

    // Volvemos a .data y emitimos literales recolectados (strings y doubles)
    core_emit_collected_literals(f);
    // Emitimos variables globales al final de .data
    globals_emit_data(f);

    fclose(f);
    // liberar estructuras
    core_reset_literals();
    vars_reset();
    globals_reset();
    return 0;
}
