#include "codegen/arm64_codegen.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_print.h"
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

// ----------------- Helpers de labels -----------------
// Etiquetas via helpers compartidos en flujo
static void emit_label(FILE *f, const char *prefix, int id) { flujo_emit_label(f, prefix, id); }

// ----------------- Pila simple de labels para 'break' -----------------
// break/continue delegados a flujo helpers
static void break_push(int id) { flujo_break_push(id); }
static int break_peek(void) { return flujo_break_peek(); }
static void break_pop(void) { flujo_break_pop(); }

// ----------------- Pila simple de labels para 'continue' (loops) -----------------
static void continue_push(int id) { flujo_continue_push(id); }
static int continue_peek(void) { return flujo_continue_peek(); }
static void continue_pop(void) { flujo_continue_pop(); }

// ----------------- Etiqueta global de salida de función para 'return' -----------------
static int __current_func_exit_id = -1;
static int __is_main_context = 0;
static TipoDato __current_func_ret = NULO;

// ----------------- Registro simple de funciones declaradas -----------------
typedef struct FuncInfo {
    char *name;
    TipoDato ret;
    int param_count;
    // Limitar a 8 params para este MVP
    TipoDato param_types[8];
    char *param_names[8];
    // Apuntador al bloque/cuerpo AST
    AbstractExpresion *body;
} FuncInfo;

static FuncInfo __funcs[64];
static int __funcs_count = 0;

static FuncInfo *funcs_lookup(const char *name) {
    for (int i = 0; i < __funcs_count; ++i) {
        if (strcmp(__funcs[i].name, name) == 0) return &__funcs[i];
    }
    return NULL;
}

static void funcs_reset(void) {
    for (int i = 0; i < __funcs_count; ++i) {
        // nombres y param_names apuntan a memoria de AST; no liberar aquí
        __funcs[i].name = NULL;
        __funcs[i].body = NULL;
        for (int j = 0; j < __funcs[i].param_count && j < 8; ++j) {
            __funcs[i].param_names[j] = NULL;
        }
    }
    __funcs_count = 0;
}

static void funcs_collect(AbstractExpresion *n) {
    if (!n) return;
    if (n->node_type && strcmp(n->node_type, "FunctionDeclaration") == 0) {
        if (__funcs_count < (int)(sizeof(__funcs)/sizeof(__funcs[0]))) {
            FuncionDeclarationNode *fn = (FuncionDeclarationNode *)n;
            FuncInfo *fi = &__funcs[__funcs_count++];
            memset(fi, 0, sizeof(*fi));
            fi->name = fn->nombre;
            fi->ret = fn->tipo_retorno;
            // hijos[0] = params list, hijos[1] = cuerpo/bloque
            AbstractExpresion *params_list = n->hijos[0];
            fi->param_count = (int)(params_list ? params_list->numHijos : 0);
            if (fi->param_count > 8) fi->param_count = 8; // límite
            for (int i = 0; i < fi->param_count; ++i) {
                ParametroNode *pn = (ParametroNode *)params_list->hijos[i];
                fi->param_types[i] = pn->tipo;
                fi->param_names[i] = pn->nombre;
            }
            fi->body = n->hijos[1];
        }
    }
    for (size_t i = 0; i < n->numHijos; ++i) funcs_collect(n->hijos[i]);
}

// ----------------- Emisión de llamada a función -----------------
// Devuelve el tipo de retorno; para INT-like deja w1 con el valor; para DOUBLE deja d0
static TipoDato emitir_llamada_funcion(AbstractExpresion *call_node, FILE *ftext) {
    if (!call_node || !(call_node->node_type && strcmp(call_node->node_type, "FunctionCall") == 0)) return INT;
    LlamadaFuncionNode *ln = (LlamadaFuncionNode *)call_node;
    FuncInfo *fi = funcs_lookup(ln->nombre);
    if (!fi) {
        // No conocida en codegen; llamar de todos modos (asumir INT) sin args
        char line[128]; snprintf(line, sizeof(line), "    bl fn_%s", ln->nombre ? ln->nombre : "unknown"); emitln(ftext, line);
        emitln(ftext, "    mov w1, w0");
        return INT;
    }
    // Evaluar y mover argumentos a registros x0.. o d0..
    AbstractExpresion *args_list = (call_node->numHijos > 0) ? call_node->hijos[0] : NULL;
    int nargs = args_list ? (int)args_list->numHijos : 0;
    if (nargs > fi->param_count) nargs = fi->param_count;
    for (int i = 0; i < nargs; ++i) {
        AbstractExpresion *arg = args_list->hijos[i];
        TipoDato esperado = fi->param_types[i];
        if (esperado == STRING) {
            // Evaluar puntero a string en x1
            if (!emitir_eval_string_ptr(arg, ftext)) {
                emitln(ftext, "    mov x1, #0");
            }
            char mv[64]; snprintf(mv, sizeof(mv), "    mov x%d, x1", i); emitln(ftext, mv);
        } else if (esperado == DOUBLE || esperado == FLOAT) {
            // Evaluar numérico y convertir a double si es necesario -> d0
            TipoDato ty = emitir_eval_numerico(arg, ftext);
            if (ty != DOUBLE) emitln(ftext, "    scvtf d0, w1");
            char mv[64]; snprintf(mv, sizeof(mv), "    fmov d%d, d0", i); emitln(ftext, mv);
        } else {
            // INT-like
            TipoDato ty = emitir_eval_numerico(arg, ftext);
            if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
            char mv[64]; snprintf(mv, sizeof(mv), "    mov w%d, w1", i); emitln(ftext, mv);
        }
    }
    // Llamar
    {
        char line[128]; snprintf(line, sizeof(line), "    bl fn_%s", fi->name); emitln(ftext, line);
    }
    // Mover retorno a convención local (w1/d0)
    if (fi->ret == DOUBLE || fi->ret == FLOAT) {
        // Resultado ya está en d0
        return DOUBLE;
    } else {
        emitln(ftext, "    mov w1, w0");
        return INT;
    }
}

// ----------------- Helpers de runtime para arreglos (flat) -----------------
// new_array_flat(dims=w0, sizes_ptr=x1) -> x0: puntero a cabecera
//  [align8] : int data[prod(sizes)]
static void emit_array_helpers(FILE *ftext) {
    emitln(ftext, "// --- Runtime helpers para arreglos ---");
    emitln(ftext, "// x0 = dims (w0), x1 = ptr a sizes[int32] -> retorna x0 puntero a arreglo");
    emitln(ftext, "new_array_flat:");
    // Prologue: save FP/LR and callee-saved we use (x19-x28)
    emitln(ftext, "    stp x29, x30, [sp, -16]!");
    emitln(ftext, "    mov x29, sp");
    emitln(ftext, "    sub sp, sp, #80"); // space for x19-x28 (10 regs * 8 = 80)
    emitln(ftext, "    stp x19, x20, [sp, #0]");
    emitln(ftext, "    stp x21, x22, [sp, #16]");
    emitln(ftext, "    stp x23, x24, [sp, #32]");
    emitln(ftext, "    stp x25, x26, [sp, #48]");
    emitln(ftext, "    stp x27, x28, [sp, #64]");
    emitln(ftext, "    // Guardar args en callee-saved (preservados a través de llamadas)");
    emitln(ftext, "    mov w19, w0"); // dims
    emitln(ftext, "    mov x20, x1"); // sizes ptr
    emitln(ftext, "    mov x21, #1"); // total_elems (64-bit)
    emitln(ftext, "L_arr_prod_loop:");
    emitln(ftext, "    cmp w12, w19");
    emitln(ftext, "    add x14, x20, x12, uxtw #2");
    emitln(ftext, "    uxtw x13, w13");
    emitln(ftext, "    mul x21, x21, x13");
    emitln(ftext, "    add w12, w12, #1");
    emitln(ftext, "    b L_arr_prod_loop");
    emitln(ftext, "L_arr_prod_done:");
    emitln(ftext, "    // bytes de header = 8 + dims*4; alinear a 8");
    emitln(ftext, "    mov x15, #8");
    emitln(ftext, "    uxtw x16, w19");
    emitln(ftext, "    lsl x16, x16, #2");
    emitln(ftext, "    add x15, x15, x16");
    emitln(ftext, "    add x17, x15, #7");
    emitln(ftext, "    and x17, x17, #-8");
    emitln(ftext, "    mov x27, x17"); // preservar header_size (callee-saved)
    emitln(ftext, "    // total_bytes = data_off + total_elems*4");
    emitln(ftext, "    lsl x18, x21, #2");
    emitln(ftext, "    add x22, x17, x18");
    emitln(ftext, "    mov x0, x22");
    emitln(ftext, "    bl malloc");
    emitln(ftext, "    mov x23, x0"); // arr base
    emitln(ftext, "    // escribir dims");
    emitln(ftext, "    str w19, [x23]");
    emitln(ftext, "    // copiar sizes");
    emitln(ftext, "    add x24, x23, #8");
    emitln(ftext, "    mov w12, #0");
    emitln(ftext, "L_arr_store_sizes:");
    emitln(ftext, "    cmp w12, w19");
    emitln(ftext, "    b.ge L_arr_sizes_done");
    emitln(ftext, "    add x14, x20, x12, uxtw #2");
    emitln(ftext, "    ldr w13, [x14]");
    emitln(ftext, "    add x25, x24, x12, uxtw #2");
    emitln(ftext, "    str w13, [x25]");
    emitln(ftext, "    add w12, w12, #1");
    emitln(ftext, "    b L_arr_store_sizes");
    emitln(ftext, "L_arr_sizes_done:");
    emitln(ftext, "    // limpiar data a cero");
    emitln(ftext, "    add x26, x23, x27"); // data base
    emitln(ftext, "    mov x25, #0"); // i = 0 .. total_elems-1 (x21)
    emitln(ftext, "L_arr_zero_loop:");
    emitln(ftext, "    cmp x25, x21");
    emitln(ftext, "    b.ge L_arr_zero_done");
    emitln(ftext, "    add x28, x26, x25, lsl #2");
    emitln(ftext, "    mov w14, #0");
    emitln(ftext, "    str w14, [x28]");
    emitln(ftext, "    add x25, x25, #1");
    emitln(ftext, "    b L_arr_zero_loop");
    emitln(ftext, "L_arr_zero_done:");
    emitln(ftext, "    mov x0, x23");
    emitln(ftext, "    ldp x19, x20, [sp, #0]");
    emitln(ftext, "    ldp x21, x22, [sp, #16]");
    emitln(ftext, "    ldp x23, x24, [sp, #32]");
    emitln(ftext, "    ldp x25, x26, [sp, #48]");
    emitln(ftext, "    ldp x27, x28, [sp, #64]");
    emitln(ftext, "    add sp, sp, #80");
    emitln(ftext, "    ldp x29, x30, [sp], 16");
    emitln(ftext, "    ret\n");

    // x0 = arr_ptr, x1 = ptr indices[int32], w2 = k -> x0 = &data[lin]
    emitln(ftext, "// x0 = arr_ptr, x1 = indices ptr, w2 = num_indices -> x0 = puntero a elemento int");
    emitln(ftext, "array_element_addr:");
    // Prologue: save FP/LR and callee-saved we use (x19-x28)
    emitln(ftext, "    stp x29, x30, [sp, -16]!");
    emitln(ftext, "    mov x29, sp");
    emitln(ftext, "    sub sp, sp, #80");
    emitln(ftext, "    stp x19, x20, [sp, #0]");
    emitln(ftext, "    stp x21, x22, [sp, #16]");
    emitln(ftext, "    stp x23, x24, [sp, #32]");
    emitln(ftext, "    stp x25, x26, [sp, #48]");
    emitln(ftext, "    stp x27, x28, [sp, #64]");
    emitln(ftext, "    mov x9, x0"); // arr
    emitln(ftext, "    mov x10, x1"); // idx ptr
    emitln(ftext, "    mov w11, w2"); // k
    emitln(ftext, "    ldr w12, [x9]"); // dims
    emitln(ftext, "    // calcular data_offset");
    emitln(ftext, "    mov x15, #8");
    emitln(ftext, "    uxtw x16, w12");
    emitln(ftext, "    lsl x16, x16, #2");
    emitln(ftext, "    add x15, x15, x16");
    emitln(ftext, "    add x17, x15, #7");
    emitln(ftext, "    and x17, x17, #-8");
    emitln(ftext, "    // puntero a sizes");
    emitln(ftext, "    add x18, x9, #8");
    emitln(ftext, "    mov x19, #0"); // lin idx
    emitln(ftext, "    mov w20, #0"); // i=0..k-1
    emitln(ftext, "L_lin_outer:");
    emitln(ftext, "    cmp w20, w11");
    emitln(ftext, "    b.ge L_lin_done");
    emitln(ftext, "    // cargar idx[i]");
    emitln(ftext, "    add x21, x10, x20, uxtw #2");
    emitln(ftext, "    ldr w22, [x21]");
    emitln(ftext, "    uxtw x22, w22");
    emitln(ftext, "    // stride = prod sizes[j] para j=i+1..dims-1");
    emitln(ftext, "    mov x23, #1");
    emitln(ftext, "    add w24, w20, #1");
    emitln(ftext, "L_lin_stride:");
    emitln(ftext, "    cmp w24, w12");
    emitln(ftext, "    b.ge L_lin_stride_done");
    emitln(ftext, "    add x25, x18, x24, uxtw #2");
    emitln(ftext, "    ldr w26, [x25]");
    emitln(ftext, "    uxtw x26, w26");
    emitln(ftext, "    mul x23, x23, x26");
    emitln(ftext, "    add w24, w24, #1");
    emitln(ftext, "    b L_lin_stride");
    emitln(ftext, "L_lin_stride_done:");
    emitln(ftext, "    madd x19, x22, x23, x19"); // lin += idx*stride
    emitln(ftext, "    add w20, w20, #1");
    emitln(ftext, "    b L_lin_outer");
    emitln(ftext, "L_lin_done:");
    emitln(ftext, "    // &data[lin]");
    emitln(ftext, "    add x0, x9, x17");
    emitln(ftext, "    add x0, x0, x19, lsl #2");
    emitln(ftext, "    ldp x19, x20, [sp, #0]");
    emitln(ftext, "    ldp x21, x22, [sp, #16]");
    emitln(ftext, "    ldp x23, x24, [sp, #32]");
    emitln(ftext, "    ldp x25, x26, [sp, #48]");
    emitln(ftext, "    ldp x27, x28, [sp, #64]");
    emitln(ftext, "    add sp, sp, #80");
    emitln(ftext, "    ldp x29, x30, [sp], 16");
    emitln(ftext, "    ret\n");
}

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
        (void)emitir_llamada_funcion(node, ftext);
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
    if (node->node_type && strcmp(node->node_type, "Declaracion") == 0) {
        // Declaración de variable local con inicialización de literal primitivo
        DeclaracionVariable *decl = (DeclaracionVariable *)node;
        if (decl->dimensiones > 0) {
            // Reservar slot de 8 bytes para puntero a arreglo
            VarEntry *v = vars_agregar_ext(decl->nombre, ARRAY, 8, decl->es_constante ? 1 : 0, ftext);
            if (node->numHijos > 0 && node->hijos[0] && strcmp(node->hijos[0]->node_type ? node->hijos[0]->node_type : "", "ArrayCreation") == 0) {
                // Emitir creación del arreglo y almacenar el puntero
                AbstractExpresion *arr_create = node->hijos[0];
                // dims expresados en hijo[1]
                AbstractExpresion *lista = arr_create->hijos[1];
                int dims = (int)(lista ? lista->numHijos : 0);
                // Reservar buffer temporal en stack para sizes (alineado a 16)
                int bytes = ((dims * 4) + 15) & ~15;
                if (bytes > 0) {
                    char sub[64]; snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes); emitln(ftext, sub);
                    for (int i = 0; i < dims; ++i) {
                        TipoDato ty = emitir_eval_numerico(lista->hijos[i], ftext);
                        if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                        char st[64]; snprintf(st, sizeof(st), "    str w1, [sp, #%d]", i * 4); emitln(ftext, st);
                    }
                    // x0=dims, x1=sp
                    char mv0[64]; snprintf(mv0, sizeof(mv0), "    mov w0, #%d", dims); emitln(ftext, mv0);
                    emitln(ftext, "    mov x1, sp");
                    emitln(ftext, "    bl new_array_flat");
                    // x0 tiene el puntero, almacenar en variable
                    char stp[64]; snprintf(stp, sizeof(stp), "    str x0, [x29, -%d]", v->offset); emitln(ftext, stp);
                    char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb);
                } else {
                    // dims==0: almacenar NULL
                    char stp[64]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    str x1, [x29, -%d]", v->offset); emitln(ftext, stp);
                }
            } else {
                // Sin inicializador: NULL
                char stp[64]; snprintf(stp, sizeof(stp), "    mov x1, #0\n    str x1, [x29, -%d]", v->offset); emitln(ftext, stp);
            }
            return;
        }
        // Tamaño
        int size = (decl->tipo == DOUBLE) ? 8 : 8; // usamos 8 para alinear (char/int/bool caben)
        VarEntry *v = NULL;
        int is_const = decl->es_constante ? 1 : 0;
        v = vars_agregar_ext(decl->nombre, decl->tipo, size, is_const, ftext);
        if (node->numHijos > 0) {
            AbstractExpresion *init = node->hijos[0];
            if (init && init->node_type && strcmp(init->node_type, "FunctionCall") == 0) {
                // Inicializar con llamada a función
                TipoDato rty = emitir_llamada_funcion(init, ftext);
                if (decl->tipo == DOUBLE || decl->tipo == FLOAT) {
                    if (rty != DOUBLE) emitln(ftext, "    scvtf d0, w1");
                    char st[64]; snprintf(st, sizeof(st), "    str d0, [x29, -%d]", v->offset); emitln(ftext, st);
                } else if (decl->tipo == STRING) {
                    if (!expresion_es_cadena(init)) {
                        // Evaluar nuevamente como string ptr si no fue pasado
                        if (!emitir_eval_string_ptr(init, ftext)) emitln(ftext, "    mov x1, #0");
                    } else {
                        // ya debería estar en x1, pero por seguridad
                        if (!emitir_eval_string_ptr(init, ftext)) emitln(ftext, "    mov x1, #0");
                    }
                    char st[64]; snprintf(st, sizeof(st), "    str x1, [x29, -%d]", v->offset); emitln(ftext, st);
                } else {
                    if (rty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
                    char st[64]; snprintf(st, sizeof(st), "    str w1, [x29, -%d]", v->offset); emitln(ftext, st);
                }
            } else if (decl->tipo == DOUBLE || decl->tipo == FLOAT) {
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
    // Asignación a elemento de arreglo: ArrayAssignment
    if (node->node_type && strcmp(node->node_type, "ArrayAssignment") == 0) {
        AbstractExpresion *acceso = node->hijos[0];
        AbstractExpresion *rhs = node->hijos[1];
        // Calcular profundidad y recolectar índices (orden externo->interno)
        int depth = 0; AbstractExpresion *it = acceso;
        while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0) { depth++; it = it->hijos[0]; }
        // it ahora es la base (esperado Identificador)
        if (!(it && it->node_type && strcmp(it->node_type, "Identificador") == 0)) {
            emitln(ftext, "    // ArrayAssignment base no soportada en codegen");
            return;
        }
        IdentificadorExpresion *id = (IdentificadorExpresion *)it;
        VarEntry *v = buscar_variable(id->nombre);
        if (!v) return;
        // Reservar buffer en stack para índices
        int bytes = ((depth * 4) + 15) & ~15;
        if (bytes > 0) { char sub[64]; snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes); emitln(ftext, sub); }
        // Rellenar índices
        it = acceso; for (int i = 0; i < depth; ++i) {
            AbstractExpresion *idx = it->hijos[1];
            TipoDato ty = emitir_eval_numerico(idx, ftext);
            if (ty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
            char st[64]; snprintf(st, sizeof(st), "    str w1, [sp, #%d]", i * 4); emitln(ftext, st);
            it = it->hijos[0];
        }
        // Cargar puntero al arreglo
        {
            char ld[64]; snprintf(ld, sizeof(ld), "    ldr x0, [x29, -%d]", v->offset); emitln(ftext, ld);
        }
        // x1 = sp, w2 = depth
        emitln(ftext, "    mov x1, sp");
        { char mv[64]; snprintf(mv, sizeof(mv), "    mov w2, #%d", depth); emitln(ftext, mv); }
        emitln(ftext, "    bl array_element_addr");
        // Evaluar RHS y guardar en [x0]
        TipoDato rty = emitir_eval_numerico(rhs, ftext);
        if (rty == DOUBLE) emitln(ftext, "    fcvtzs w1, d0");
        emitln(ftext, "    str w1, [x0]");
        if (bytes > 0) { char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes); emitln(ftext, addb); }
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
                        emitln(ftext, "    mov w0, w1");
                        emitln(ftext, "    bl char_to_utf8");
                        emitln(ftext, "    mov x1, x0");
                        emitln(ftext, "    ldr x0, =fmt_string");
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
    emit_array_helpers(f);
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
    // Recolectar funciones del AST
    funcs_reset();
    funcs_collect(root);

    // Emitir cada función como fn_<nombre>
    for (int i = 0; i < __funcs_count; ++i) {
        FuncInfo *fi = &__funcs[i];
        // Reset de estado de variables por función
        vars_reset();
        char lab[128]; snprintf(lab, sizeof(lab), "fn_%s:", fi->name); emitln(f, lab);
        emitln(f, "    stp x29, x30, [sp, -16]!");
        emitln(f, "    mov x29, sp");
        // Preparar estado de retorno para ReturnStatement
        __is_main_context = 0;
        __current_func_ret = fi->ret;
        __current_func_exit_id = flujo_next_label_id();
        // Crear variables locales para parámetros y mover desde registros de llamada
        for (int p = 0; p < fi->param_count && p < 8; ++p) {
            int size = (fi->param_types[p] == DOUBLE || fi->param_types[p] == FLOAT) ? 8 : 8;
            VarEntry *v = vars_agregar_ext(fi->param_names[p], fi->param_types[p], size, 0, f);
            if (fi->param_types[p] == DOUBLE || fi->param_types[p] == FLOAT) {
                char st[64]; snprintf(st, sizeof(st), "    str d%d, [x29, -%d]", p, v->offset); emitln(f, st);
            } else if (fi->param_types[p] == STRING) {
                char st[64]; snprintf(st, sizeof(st), "    str x%d, [x29, -%d]", p, v->offset); emitln(f, st);
            } else {
                char st[64]; snprintf(st, sizeof(st), "    str w%d, [x29, -%d]", p, v->offset); emitln(f, st);
            }
        }
        // Generar cuerpo
        gen_node(f, fi->body);
        // Salida de función
        emit_label(f, "L_func_exit", __current_func_exit_id);
        __current_func_exit_id = -1;
        // Restaurar stack de variables locales
        vars_epilogo(f);
        emitln(f, "    ldp x29, x30, [sp], 16");
        emitln(f, "    ret\n");
        // Fin de función; continuar con la siguiente
    }

    // Ahora main
    vars_reset();
    emitln(f, "main:");
    emitln(f, "    stp x29, x30, [sp, -16]!");
    emitln(f, "    mov x29, sp\n");

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
