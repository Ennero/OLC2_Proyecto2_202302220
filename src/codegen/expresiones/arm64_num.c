#include "codegen/arm64_num.h"
#include "codegen/arm64_core.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_globals.h"
#include "codegen/instrucciones/arm64_flujo.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "ast/nodos/expresiones/aritmeticas/aritmeticas.h"
#include <string.h>
#include <stdlib.h>
#include "ast/nodos/instrucciones/instruccion/casteos.h"
#include "codegen/arm64_print.h"
#include "codegen/estructuras/arm64_arreglos.h"
#include "ast/nodos/expresiones/postfix.h"
#include "parser.tab.h" 
#include "codegen/funciones/arm64_funciones.h"

// Shorthand to match arm64_codegen.c helpers
static void emitln(FILE *f, const char *s) { core_emitln(f, s); }
typedef VarEntry VarEntry;
static VarEntry *buscar_variable(const char *name) { return vars_buscar(name); }

// Emite una carga inmediata robusta en w1 para cualquier constante de 32 bits.
static void emit_mov_imm_w1(FILE *f, long v)
{
    unsigned int u = (unsigned int)v;
    unsigned int lo = u & 0xFFFFu;
    unsigned int hi = (u >> 16) & 0xFFFFu;
    char buf[64];
    snprintf(buf, sizeof(buf), "    movz w1, #%u", lo);
    emitln(f, buf);
    if (hi)
    {
        snprintf(buf, sizeof(buf), "    movk w1, #%u, lsl #16", hi);
        emitln(f, buf);
    }
}

// Emite código para evaluar una expresión numérica, dejando el resultado en w1 (INT/BOOLEAN/CHAR) o d0 (DOUBLE).
TipoDato emitir_eval_numerico(AbstractExpresion *node, FILE *ftext)
{
    // Manejar casos según el tipo de nodo
    const char *t = node->node_type ? node->node_type : "";
    if (strcmp(t, "Primitivo") == 0)
    {
        // Literal numérico
        PrimitivoExpresion *p = (PrimitivoExpresion *)node;
        if (p->tipo == INT || p->tipo == BOOLEAN || p->tipo == CHAR)
        {
            long v = 0;
            // Parsear el valor según el tipo
            if (p->valor)
            {
                // Soporte para enteros decimales y hexadecimales
                if (p->tipo == INT)
                {
                    if (strncmp(p->valor, "0x", 2) == 0 || strncmp(p->valor, "0X", 2) == 0)
                        v = strtol(p->valor, NULL, 16);
                    else
                        v = strtol(p->valor, NULL, 10);
                }

                // Booleano
                else if (p->tipo == BOOLEAN)
                {
                    v = (strcmp(p->valor, "true") == 0);
                }

                // Char
                else
                { // Con soporte de escapes y \u decimal
                    const char *s = p->valor;
                    size_t n = strlen(s);
                    int cp = 0;
                    if (n >= 2 && s[0] == '\\')
                    {
                        switch (s[1])
                        {
                        case 'n':
                            cp = '\n';
                            break;
                        case 't':
                            cp = '\t';
                            break;
                        case 'r':
                            cp = '\r';
                            break;
                        case '\\':
                            cp = '\\';
                            break;
                        case '"':
                            cp = '"';
                            break;
                        case '\'':
                            cp = '\'';
                            break;
                        case 'u':
                        {
                            // Leer hasta 5 dígitos decimales después de \u
                            int val = 0;
                            size_t i = 2;
                            size_t cnt = 0;
                            while (i < n && cnt < 5 && s[i] >= '0' && s[i] <= '9')
                            {
                                val = val * 10 + (s[i] - '0');
                                i++;
                                cnt++;
                            }
                            if (val < 0)
                                val = 0;
                            if (val > 0x10FFFF)
                                val = 0x10FFFF;
                            cp = val;
                            break;
                        }
                        default:
                            cp = (unsigned char)s[1];
                            break;
                        }
                    }
                    else
                    {
                        cp = (unsigned char)s[0];
                    }
                    v = cp;
                }
            }
            // Cargar la constante en w1 evitando errores de ensamblado por inmediatos grandes
            emit_mov_imm_w1(ftext, v);
            return INT;
        }

        // Literal double/float
        else if (p->tipo == DOUBLE || p->tipo == FLOAT)
        {
            const char *lab = core_add_double_literal(p->valor ? p->valor : "0");
            char ref[128];
            snprintf(ref, sizeof(ref), "    ldr x16, =%s\n    ldr d0, [x16]", lab);
            emitln(ftext, ref);
            return DOUBLE;
        }
    }
    else if (strcmp(t, "FunctionCall") == 0)
    {
        // Evaluar llamada a función usada como expresión numérica
        TipoDato rty = arm64_emitir_llamada_funcion(node, ftext);
        if (rty == DOUBLE)
        {
            return DOUBLE;
        }
        else if (rty == ARRAY)
        {
            // No numérico: producir 0
            emitln(ftext, "    mov w1, #0");
            return INT;
        }
        else
        {
            // INT/BOOLEAN/CHAR
            return INT;
        }
    }

    // Identificador
    else if (strcmp(t, "Identificador") == 0)
    {
        IdentificadorExpresion *id = (IdentificadorExpresion *)node;
        VarEntry *v = buscar_variable(id->nombre);

        // Variable local
        if (v)
        {
            // Cargar según el tipo
            if (v->tipo == DOUBLE || v->tipo == FLOAT)
            {
                char line[96];
                snprintf(line, sizeof(line), "    sub x16, x29, #%d\n    ldr d0, [x16]", v->offset);
                emitln(ftext, line);
                return DOUBLE;
            }
            else
            { // INT/BOOLEAN/CHAR
                char line[96];
                snprintf(line, sizeof(line), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset);
                emitln(ftext, line);
                return INT;
            }
        }
        // Intentar determinar tipo
        const GlobalInfo *gi = globals_lookup(id->nombre);
        if (gi && (gi->tipo == DOUBLE || gi->tipo == FLOAT))
        {
            char sym[128];
            snprintf(sym, sizeof(sym), "    ldr x16, =g_%s\n    ldr d0, [x16]", id->nombre);
            emitln(ftext, sym);
            return DOUBLE;
        }
        
        // Variable global INT/BOOLEAN/CHAR
        else
        {
            char sym[128];
            snprintf(sym, sizeof(sym), "    ldr x16, =g_%s\n    ldr w1, [x16]", id->nombre);
            emitln(ftext, sym);
            return INT;
        }
    }

    // Acceso a arreglo
    else if (strcmp(t, "ArrayAccess") == 0)
    {
        int depth = 0;
        AbstractExpresion *it = node;

        // Contar la profundidad del acceso
        while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0)
        {
            depth++;
            it = it->hijos[0];
        }

        // El nodo base debe ser un identificador
        if (!(it && it->node_type && strcmp(it->node_type, "Identificador") == 0))
        {
            emitln(ftext, "    mov w1, #0");
            return INT;
        }

        // Obtener la variable
        IdentificadorExpresion *id = (IdentificadorExpresion *)it;
        VarEntry *v = buscar_variable(id->nombre);
        if (!v)
        {
            emitln(ftext, "    mov w1, #0");
            return INT;
        }

        // Determinar tipo base del arreglo si se registró
        TipoDato base_t = arm64_array_elem_tipo_for_var(id->nombre);
        int bytes = ((depth * 4) + 15) & ~15;
        if (bytes > 0)
        {
            char sub[64];
            snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes);
            emitln(ftext, sub);
        }

        // Recopilar nodos de índices en orden correcto (izq->der)
        AbstractExpresion **idx_nodes = NULL;
        if (depth > 0)
            idx_nodes = (AbstractExpresion **)malloc(sizeof(AbstractExpresion *) * (size_t)depth);
        int pos = depth - 1;
        it = node;

        // Recolectar nodos de índices
        for (int i = 0; i < depth; ++i)
        {
            idx_nodes[pos--] = it->hijos[1];
            it = it->hijos[0];
        }

        // Evaluar índices y almacenarlos en stack
        for (int k = 0; k < depth; ++k)
        {
            TipoDato ty = emitir_eval_numerico(idx_nodes[k], ftext);
            if (ty == DOUBLE)
                emitln(ftext, "    fcvtzs w1, d0");
            char st[64];
            snprintf(st, sizeof(st), "    str w1, [sp, #%d]", k * 4);
            emitln(ftext, st);
        }

        // Cargar puntero al arreglo y resolver dirección del elemento según tamaño
        {
            char ld[96];
            snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", v->offset);
            emitln(ftext, ld);
        }
        emitln(ftext, "    mov x1, sp");
        {
            char mv[64];
            snprintf(mv, sizeof(mv), "    mov w2, #%d", depth);
            emitln(ftext, mv);
        }

        // Obtener el valor del elemento
        if (base_t == DOUBLE || base_t == FLOAT)
        {
            emitln(ftext, "    bl array_element_addr_ptr");
            emitln(ftext, "    ldr d0, [x0]");
        }

        // Elemento entero
        else if (base_t == STRING)
        {
            // No es numérico; retornar 0
            emitln(ftext, "    mov w1, #0");
        }

        // Elemento INT/BOOLEAN/CHAR
        else
        {
            emitln(ftext, "    bl array_element_addr");
            if (base_t == CHAR)
                emitln(ftext, "    ldrb w1, [x0]");
            else
                emitln(ftext, "    ldr w1, [x0]");
        }

        // Liberar stack y recursos
        if (bytes > 0)
        {
            char addb[64];
            snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes);
            emitln(ftext, addb);
        }

        // Free index nodes
        if (idx_nodes)
            free(idx_nodes);
        if (base_t == DOUBLE || base_t == FLOAT)
            return DOUBLE;
        else
            return INT;
    }

    // Operaciones aritméticas
    else if (strcmp(t, "Suma") == 0)
    {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE)
            emitln(ftext, "    str d0, [sp]");
        else
            emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE)
        {
            if (tl == DOUBLE)
                emitln(ftext, "    ldr d8, [sp]");
            else
            {
                emitln(ftext, "    ldr w19, [sp]");
                emitln(ftext, "    scvtf d8, w19");
            }
            if (tr == DOUBLE)
                emitln(ftext, "    fmov d9, d0");
            else
                emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fadd d0, d8, d9");
            emitln(ftext, "    add sp, sp, #16");
            return DOUBLE;
        }
        else
        {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    add w1, w19, w1");
            return INT;
        }
    }
    else if (strcmp(t, "Resta") == 0)
    {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE)
            emitln(ftext, "    str d0, [sp]");
        else
            emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE)
        {
            if (tl == DOUBLE)
                emitln(ftext, "    ldr d8, [sp]");
            else
            {
                emitln(ftext, "    ldr w19, [sp]");
                emitln(ftext, "    scvtf d8, w19");
            }
            if (tr == DOUBLE)
                emitln(ftext, "    fmov d9, d0");
            else
                emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fsub d0, d8, d9");
            emitln(ftext, "    add sp, sp, #16");
            return DOUBLE;
        }
        else
        {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    sub w1, w19, w1");
            return INT;
        }
    }
    else if (strcmp(t, "Multiplicacion") == 0)
    {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE)
            emitln(ftext, "    str d0, [sp]");
        else
            emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE)
        {
            if (tl == DOUBLE)
                emitln(ftext, "    ldr d8, [sp]");
            else
            {
                emitln(ftext, "    ldr w19, [sp]");
                emitln(ftext, "    scvtf d8, w19");
            }
            if (tr == DOUBLE)
                emitln(ftext, "    fmov d9, d0");
            else
                emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fmul d0, d8, d9");
            emitln(ftext, "    add sp, sp, #16");
            return DOUBLE;
        }
        else
        {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    mul w1, w19, w1");
            return INT;
        }
    }
    else if (strcmp(t, "Division") == 0)
    {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE)
            emitln(ftext, "    str d0, [sp]");
        else
            emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE)
        {
            if (tl == DOUBLE)
                emitln(ftext, "    ldr d8, [sp]");
            else
            {
                emitln(ftext, "    ldr w19, [sp]");
                emitln(ftext, "    scvtf d8, w19");
            }
            if (tr == DOUBLE)
                emitln(ftext, "    fmov d9, d0");
            else
                emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fdiv d0, d8, d9");
            emitln(ftext, "    add sp, sp, #16");
            return DOUBLE;
        }
        else
        {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    sdiv w1, w19, w1");
            return INT;
        }
    }
    else if (strcmp(t, "Modulo") == 0)
    {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE)
            emitln(ftext, "    str d0, [sp]");
        else
            emitln(ftext, "    str w1, [sp]");
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tl == DOUBLE || tr == DOUBLE)
        {
            if (tl == DOUBLE)
                emitln(ftext, "    ldr d8, [sp]");
            else
            {
                emitln(ftext, "    ldr w19, [sp]");
                emitln(ftext, "    scvtf d8, w19");
            }
            if (tr == DOUBLE)
                emitln(ftext, "    fmov d9, d0");
            else
                emitln(ftext, "    scvtf d9, w1");
            emitln(ftext, "    fmov d0, d8");
            emitln(ftext, "    fmov d1, d9");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    bl fmod");
            return DOUBLE;
        }
        else
        {
            emitln(ftext, "    ldr w19, [sp]");
            emitln(ftext, "    add sp, sp, #16");
            emitln(ftext, "    sdiv w21, w19, w1");
            emitln(ftext, "    msub w1, w21, w1, w19");
            return INT;
        }
    }
    else if (strcmp(t, "NegacionUnaria") == 0)
    {
        TipoDato ty = emitir_eval_numerico(node->hijos[0], ftext);
        if (ty == DOUBLE)
        {
            emitln(ftext, "    fneg d0, d0");
            return DOUBLE;
        }
        else
        {
            emitln(ftext, "    neg w1, w1");
            return INT;
        }
    }
    else if (strcmp(t, "BitwiseAnd") == 0 || strcmp(t, "BitwiseOr") == 0 || strcmp(t, "BitwiseXor") == 0 ||
            strcmp(t, "LeftShift") == 0 || strcmp(t, "RightShift") == 0 || strcmp(t, "UnsignedRightShift") == 0)
    {
        TipoDato tl = emitir_eval_numerico(node->hijos[0], ftext);
        // Guardar lhs entero en stack para protegerlo
        emitln(ftext, "    sub sp, sp, #16");
        if (tl == DOUBLE)
        {
            emitln(ftext, "    fcvtzs w19, d0");
            emitln(ftext, "    str w19, [sp]");
        }
        else
        {
            emitln(ftext, "    str w1, [sp]");
        }
        TipoDato tr = emitir_eval_numerico(node->hijos[1], ftext);
        if (tr == DOUBLE)
        {
            emitln(ftext, "    fcvtzs w20, d0");
        }
        else
        {
            emitln(ftext, "    mov w20, w1");
        }
        emitln(ftext, "    ldr w19, [sp]");
        emitln(ftext, "    add sp, sp, #16");
        if (strcmp(t, "BitwiseAnd") == 0)
            emitln(ftext, "    and w1, w19, w20");
        else if (strcmp(t, "BitwiseOr") == 0)
            emitln(ftext, "    orr w1, w19, w20");
        else if (strcmp(t, "BitwiseXor") == 0)
            emitln(ftext, "    eor w1, w19, w20");
        else if (strcmp(t, "LeftShift") == 0)
            emitln(ftext, "    lsl w1, w19, w20");
        else if (strcmp(t, "RightShift") == 0)
            emitln(ftext, "    asr w1, w19, w20");
        else // UnsignedRightShift
            emitln(ftext, "    lsr w1, w19, w20");
        return INT;
    }
    else if (strcmp(t, "BitwiseNot") == 0)
    {
        TipoDato ty = emitir_eval_numerico(node->hijos[0], ftext);
        if (ty == DOUBLE)
        {
            emitln(ftext, "    fcvtzs w1, d0");
        }
        emitln(ftext, "    mvn w1, w1");
        return INT;
    }

    // Casteo explícito
    else if (strcmp(t, "Casteo") == 0)
    {
        // Casteo explícito entre tipos numéricos
        CasteoExpresion *c = (CasteoExpresion *)node;
        TipoDato dest = c->tipo_destino;
        // Evaluar hijo
        TipoDato from = emitir_eval_numerico(node->hijos[0], ftext);
        // Normalizar conversiones
        if (dest == DOUBLE || dest == FLOAT)
        {
            // Producir d0
            if (from != DOUBLE)
            {
                // w1 -> d0
                emitln(ftext, "    scvtf d0, w1");
            }
            return DOUBLE;
        }
        else if (dest == INT || dest == CHAR)
        {
            // Producir w1
            if (from == DOUBLE)
            {
                emitln(ftext, "    fcvtzs w1, d0");
            }
            return INT;
        }
        else if (dest == BOOLEAN)
        {
            // booleano 0/1 en w1
            if (from == DOUBLE)
            {
                emitln(ftext, "    fcmp d0, #0.0");
                emitln(ftext, "    cset w1, ne");
            }
            else
            {
                emitln(ftext, "    cmp w1, #0");
                emitln(ftext, "    cset w1, ne");
            }
            return INT;
        }
        // Otros casteos no soportados: retornar 0
        emitln(ftext, "    mov w1, #0");
        return INT;
    }
    else if (strcmp(t, "Postfix") == 0)
    {
        // Devuelve valor antiguo y escribe el nuevo.
        AbstractExpresion *lvalue = node->hijos[0];
        int op = postfix_get_op(node);
        if (lvalue && strcmp(lvalue->node_type ? lvalue->node_type : "", "Identificador") == 0)
        {
            IdentificadorExpresion *id = (IdentificadorExpresion *)lvalue;
            VarEntry *v = buscar_variable(id->nombre);
            if (v)
            {
                // Cargar valor actual y guardar como retorno
                if (v->tipo == DOUBLE || v->tipo == FLOAT)
                {
                    char ld[96];
                    snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr d0, [x16]", v->offset);
                    emitln(ftext, ld);
                    const char *one = core_add_double_literal("1.0");
                    char l1[96];
                    snprintf(l1, sizeof(l1), "    ldr x16, =%s\n    ldr d1, [x16]", one);
                    emitln(ftext, l1);
                    if (op == TOKEN_INCREMENTO)
                        emitln(ftext, "    fadd d1, d0, d1");
                    else
                        emitln(ftext, "    fsub d1, d0, d1");
                    char st[96];
                    snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d1, [x16]", v->offset);
                    emitln(ftext, st);
                    return DOUBLE;
                }
                else
                {
                    char ld[96];
                    snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr w1, [x16]", v->offset);
                    emitln(ftext, ld);
                    if (op == TOKEN_INCREMENTO)
                        emitln(ftext, "    add w20, w1, #1");
                    else
                        emitln(ftext, "    sub w20, w1, #1");
                    char st[96];
                    snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w20, [x16]", v->offset);
                    emitln(ftext, st);
                    return INT;
                }
            }
            else
            {
                // Postfix sobre global
                const GlobalInfo *gi = globals_lookup(id->nombre);
                if (!gi)
                {
                    emitln(ftext, "    mov w1, #0");
                    return INT;
                }
                // Dirección global
                char adr[128];
                snprintf(adr, sizeof(adr), "    ldr x16, =g_%s", id->nombre);
                emitln(ftext, adr);
                if (gi->tipo == DOUBLE || gi->tipo == FLOAT)
                {
                    emitln(ftext, "    ldr d0, [x16]");
                    const char *one = core_add_double_literal("1.0");
                    char l1[96];
                    snprintf(l1, sizeof(l1), "    ldr x17, =%s\n    ldr d1, [x17]", one);
                    emitln(ftext, l1);
                    if (op == TOKEN_INCREMENTO)
                        emitln(ftext, "    fadd d1, d0, d1");
                    else
                        emitln(ftext, "    fsub d1, d0, d1");
                    emitln(ftext, "    str d1, [x16]");
                    return DOUBLE;
                }
                else
                {
                    emitln(ftext, "    ldr w1, [x16]");
                    if (op == TOKEN_INCREMENTO)
                        emitln(ftext, "    add w20, w1, #1");
                    else
                        emitln(ftext, "    sub w20, w1, #1");
                    emitln(ftext, "    str w20, [x16]");
                    return INT;
                }
            }
        }
        else if (lvalue && strcmp(lvalue->node_type ? lvalue->node_type : "", "ArrayAccess") == 0)
        {
            // Postfix ++/-- 
            // Calcular profundidad e indices y obtener dirección del elemento con array_element_addr
            int depth = 0;
            AbstractExpresion *it = lvalue;
            while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0)
            {
                depth++;
                it = it->hijos[0];
            }
            if (!(it && it->node_type && strcmp(it->node_type, "Identificador") == 0))
            {
                emitln(ftext, "    mov w1, #0");
                return INT;
            }
            IdentificadorExpresion *aid = (IdentificadorExpresion *)it;
            VarEntry *av = buscar_variable(aid->nombre);

            // Empujar indices en la pila (4 bytes cada uno), con alineación como en accesos numéricos
            int bytes = ((depth * 4) + 15) & ~15;
            if (bytes > 0)
            {
                char sub[64];
                snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes);
                emitln(ftext, sub);
            }

            // Reservar arreglo dinámico para soportar profundidades arbitrarias
            AbstractExpresion **idx_nodes2 = NULL;
            if (depth > 0)
                idx_nodes2 = (AbstractExpresion **)malloc(sizeof(AbstractExpresion *) * (size_t)depth);
            int pos2 = depth - 1;
            it = lvalue;
            for (int i = 0; i < depth; ++i)
            {
                idx_nodes2[pos2--] = it->hijos[1];
                it = it->hijos[0];
            }
            for (int k = 0; k < depth; ++k)
            {
                TipoDato ty = emitir_eval_numerico(idx_nodes2[k], ftext);
                if (ty == DOUBLE)
                    emitln(ftext, "    fcvtzs w1, d0");
                char st[64];
                snprintf(st, sizeof(st), "    str w1, [sp, #%d]", k * 4);
                emitln(ftext, st);
            }

            // Cargar puntero al arreglo en x0
            if (av)
            {
                char ld[96];
                snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", av->offset);
                emitln(ftext, ld);
            }
            else
            {
                const GlobalInfo *gi = globals_lookup(aid->nombre);
                if (gi)
                {
                    char lg[128];
                    snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x0, [x16]", aid->nombre);
                    emitln(ftext, lg);
                }
                else
                {
                    emitln(ftext, "    mov x0, #0");
                }
            }
            emitln(ftext, "    mov x1, sp");
            {
                char mv[64];
                snprintf(mv, sizeof(mv), "    mov w2, #%d", depth);
                emitln(ftext, mv);
            }
            emitln(ftext, "    bl array_element_addr");

            // Determinar tipo base para elegir ldr/str de 1, 4 u 8 bytes
            TipoDato base_t = arm64_array_elem_tipo_for_var(aid->nombre);
            if (base_t == CHAR)
            {
                // Guardar valor antiguo en w1 
                emitln(ftext, "    ldrb w1, [x0]");
                // Calcular nuevo valor en w20 y escribirlo
                if (op == TOKEN_INCREMENTO)
                    emitln(ftext, "    add w20, w1, #1");
                else
                    emitln(ftext, "    sub w20, w1, #1");
                emitln(ftext, "    strb w20, [x0]");
                if (bytes > 0)
                {
                    char addb[64];
                    snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes);
                    emitln(ftext, addb);
                }
                if (idx_nodes2)
                    free(idx_nodes2);
                return INT;
            }
            else if (base_t == DOUBLE || base_t == FLOAT)
            {
                // d0 = valor antiguo (retorno)
                emitln(ftext, "    ldr d0, [x0]");
                const char *one = core_add_double_literal("1.0");
                char l1[96];
                snprintf(l1, sizeof(l1), "    ldr x16, =%s\n    ldr d1, [x16]", one);
                emitln(ftext, l1);
                if (op == TOKEN_INCREMENTO)
                    emitln(ftext, "    fadd d2, d0, d1");
                else
                    emitln(ftext, "    fsub d2, d0, d1");
                emitln(ftext, "    str d2, [x0]");
                if (bytes > 0)
                {
                    char addb[64];
                    snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes);
                    emitln(ftext, addb);
                }
                if (idx_nodes2)
                    free(idx_nodes2);
                return DOUBLE;
            }
            else
            {
                emitln(ftext, "    ldr w1, [x0]");
                if (op == TOKEN_INCREMENTO)
                    emitln(ftext, "    add w20, w1, #1");
                else
                    emitln(ftext, "    sub w20, w1, #1");
                emitln(ftext, "    str w20, [x0]");
                if (bytes > 0)
                {
                    char addb[64];
                    snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes);
                    emitln(ftext, addb);
                }
                if (idx_nodes2)
                    free(idx_nodes2);
                return INT;
            }
        }
        else
        {
            // No soportado: devolver 0
            emitln(ftext, "    mov w1, #0");
            return INT;
        }
    }
    else if (strcmp(t, "ParseInt") == 0)
    {
        emitir_parse_int(node->hijos[0], ftext);
        return INT;
    }
    else if (strcmp(t, "ParseFloat") == 0)
    {
        emitir_parse_float(node->hijos[0], ftext);
        return DOUBLE;
    }
    else if (strcmp(t, "ParseDouble") == 0)
    {
        emitir_parse_double(node->hijos[0], ftext);
        return DOUBLE;
    }
    else if (strcmp(t, "ArrayLength") == 0)
    {
        // child can be: Identificador | ArrayAccess | FunctionCall (that returns ARRAY)
        AbstractExpresion *arr = node->hijos[0];
        if (!arr)
        {
            emitln(ftext, "    mov w1, #0");
            return INT;
        }
        const char *nt = arr->node_type ? arr->node_type : "";
        if (strcmp(nt, "Identificador") == 0)
        {
            // arr.length -> sizes[0]
            IdentificadorExpresion *id = (IdentificadorExpresion *)arr;
            VarEntry *v = buscar_variable(id->nombre);
            if (v)
            {
                char ld[96];
                snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", v->offset);
                emitln(ftext, ld);
            }
            else
            {
                char lg[128];
                snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x0, [x16]", id->nombre);
                emitln(ftext, lg);
            }
            emitln(ftext, "    // load sizes[0] from header: [x0+8]");
            emitln(ftext, "    add x18, x0, #8");
            emitln(ftext, "    ldr w1, [x18]");
            return INT;
        }

        // Array access e.g., arr[2][3].length
        else if (strcmp(nt, "ArrayAccess") == 0)
        {
            int depth = 0;
            AbstractExpresion *it = arr;
            while (it && it->node_type && strcmp(it->node_type, "ArrayAccess") == 0)
            {
                depth++;
                it = it->hijos[0];
            }
            if (!(it && it->node_type && strcmp(it->node_type, "Identificador") == 0))
            {
                emitln(ftext, "    mov w1, #0");
                return INT;
            }
            // Cargar Indices en la pila
            AbstractExpresion **idx_nodes = NULL;
            if (depth > 0)
                idx_nodes = (AbstractExpresion **)malloc(sizeof(AbstractExpresion *) * (size_t)depth);
            int pos = depth - 1;
            AbstractExpresion *it2 = arr;
            for (int i = 0; i < depth; ++i)
            {
                idx_nodes[pos--] = it2->hijos[1];
                it2 = it2->hijos[0];
            }
            int bytes = ((depth * 4) + 15) & ~15;
            if (bytes > 0)
            {
                char sub[64];
                snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", bytes);
                emitln(ftext, sub);
            }
            for (int k = 0; k < depth; ++k)
            {
                TipoDato ty = emitir_eval_numerico(idx_nodes[k], ftext);
                if (ty == DOUBLE)
                    emitln(ftext, "    fcvtzs w1, d0");
                char st[64];
                snprintf(st, sizeof(st), "    str w1, [sp, #%d]", k * 4);
                emitln(ftext, st);
            }
            if (idx_nodes)
                free(idx_nodes);
            IdentificadorExpresion *id = (IdentificadorExpresion *)it;
            VarEntry *v = buscar_variable(id->nombre);

            // Cargar puntero al arreglo en x0
            if (v)
            {
                char ld[96];
                snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x0, [x16]", v->offset);
                emitln(ftext, ld);
            }
            else
            {
                char lg[128];
                snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x0, [x16]", id->nombre);
                emitln(ftext, lg);
            }
            
            // Instrucciones para determinar si es jagged o flat
            emitln(ftext, "    ldr w12, [x0]");
            int lbl = flujo_next_label_id();
            {
                char cmp[64];
                snprintf(cmp, sizeof(cmp), "    cmp w12, #1");
                emitln(ftext, cmp);
            }
            {
                char bne[64];
                snprintf(bne, sizeof(bne), "    b.ne L_len_flat_%d", lbl);
                emitln(ftext, bne);
            }

            // Descender por los headers de subarreglos
            for (int k = 0; k < depth; ++k)
            {
                {
                    char addp[96];
                    snprintf(addp, sizeof(addp), "    add x1, sp, #%d", k * 4);
                    emitln(ftext, addp);
                }
                emitln(ftext, "    mov w2, #1");
                emitln(ftext, "    bl array_element_addr_ptr");
                emitln(ftext, "    ldr x0, [x0]");
            }

            // Cargar sizes[0] del header actual
            emitln(ftext, "    add x18, x0, #8");
            emitln(ftext, "    ldr w1, [x18]");
            {
                char jmp[64];
                snprintf(jmp, sizeof(jmp), "    b L_len_done_%d", lbl);
                emitln(ftext, jmp);
            }

            // Caso flat array 
            {
                char lab[64];
                snprintf(lab, sizeof(lab), "L_len_flat_%d:", lbl);
                emitln(ftext, lab);
            }
            {
                int off = 8 + (depth * 4);
                char ad[96];
                snprintf(ad, sizeof(ad), "    add x18, x0, #%d", off);
                emitln(ftext, ad);
            }
            emitln(ftext, "    ldr w1, [x18]");
            {
                char labd[64];
                snprintf(labd, sizeof(labd), "L_len_done_%d:", lbl);
                emitln(ftext, labd);
            }
            if (bytes > 0)
            {
                char addb[64];
                snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes);
                emitln(ftext, addb);
            }
            return INT;
        }
        else if (strcmp(nt, "FunctionCall") == 0)
        {
            // Soporte de funciones que retornan arreglos
            TipoDato rty = arm64_emitir_llamada_funcion(arr, ftext);
            if (rty == ARRAY)
            {
                emitln(ftext, "    // load sizes[0] from header: [x0+8]");
                emitln(ftext, "    add x18, x0, #8");
                emitln(ftext, "    ldr w1, [x18]");
                return INT;
            }
            else
            {
                emitln(ftext, "    mov w1, #0");
                return INT;
            }
        }
        else
        {
            emitln(ftext, "    mov w1, #0");
            return INT;
        }
    }
    
    // Array indexOf implementación 
    else if (strcmp(t, "ArraysIndexof") == 0)
    {
        AbstractExpresion *arr = node->hijos[0];
        AbstractExpresion *val = node->hijos[1];
        if (!(arr && strcmp(arr->node_type ? arr->node_type : "", "Identificador") == 0))
        {
            emitln(ftext, "    mov w1, #-1");
            return INT;
        }
        IdentificadorExpresion *id = (IdentificadorExpresion *)arr;
        VarEntry *v = buscar_variable(id->nombre);
        if (v)
        {
            char ld[96];
            snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x9, [x16]", v->offset);
            emitln(ftext, ld);
        }
        else
        {
            char lg[128];
            snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x9, [x16]", id->nombre);
            emitln(ftext, lg);
        }
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
        TipoDato base_t = arm64_array_elem_tipo_for_var(id->nombre);
        if (base_t == STRING)
        {
            int lid = flujo_next_label_id();
            if (!emitir_eval_string_ptr(val, ftext))
                emitln(ftext, "    mov x1, #0");
            emitln(ftext, "    mov x23, x1");
            emitln(ftext, "    mov w20, #0");
            emitln(ftext, "    mov w24, #-1");
            {
                char l[64];
                snprintf(l, sizeof(l), "L_idxof_loop_s_%d:", lid);
                emitln(ftext, l);
            }
            emitln(ftext, "    cmp w20, w19");
            {
                char b[64];
                snprintf(b, sizeof(b), "    b.ge L_idxof_done_s_%d", lid);
                emitln(ftext, b);
            }
            emitln(ftext, "    add x22, x21, x20, lsl #3");
            emitln(ftext, "    ldr x0, [x22]");
            emitln(ftext, "    // Compare element vs search (handle NULL)");
            emitln(ftext, "    cmp x23, #0");
            {
                char b[64];
                snprintf(b, sizeof(b), "    b.eq L_cmp_null_s_%d", lid);
                emitln(ftext, b);
            }
            emitln(ftext, "    // strcmp(elem, search) == 0?");
            emitln(ftext, "    mov x1, x23");
            emitln(ftext, "    bl strcmp");
            emitln(ftext, "    cmp w0, #0");
            {
                char b1[64];
                snprintf(b1, sizeof(b1), "    b.eq L_idxof_found_s_%d", lid);
                emitln(ftext, b1);
                char b2[64];
                snprintf(b2, sizeof(b2), "    b L_idxof_next_s_%d", lid);
                emitln(ftext, b2);
            }
            {
                char l[64];
                snprintf(l, sizeof(l), "L_cmp_null_s_%d:", lid);
                emitln(ftext, l);
            }
            emitln(ftext, "    cmp x0, #0");
            {
                char b[64];
                snprintf(b, sizeof(b), "    b.eq L_idxof_found_s_%d", lid);
                emitln(ftext, b);
            }
            {
                char l[64];
                snprintf(l, sizeof(l), "L_idxof_next_s_%d:", lid);
                emitln(ftext, l);
            }
            emitln(ftext, "    add w20, w20, #1");
            {
                char b[64];
                snprintf(b, sizeof(b), "    b L_idxof_loop_s_%d", lid);
                emitln(ftext, b);
            }
            {
                char l[64];
                snprintf(l, sizeof(l), "L_idxof_found_s_%d:", lid);
                emitln(ftext, l);
            }
            emitln(ftext, "    mov w24, w20");
            {
                char l[64];
                snprintf(l, sizeof(l), "L_idxof_done_s_%d:", lid);
                emitln(ftext, l);
            }
            // Mover resultado a w1 para el consumidor
            emitln(ftext, "    mov w1, w24");
            return INT;
        }
        else
        {
            int lid = flujo_next_label_id();
            // Evaluar valor de búsqueda
            TipoDato vty = emitir_eval_numerico(val, ftext);
            if (vty == DOUBLE)
                emitln(ftext, "    fcvtzs w22, d0");
            else
                emitln(ftext, "    mov w22, w1");
            emitln(ftext, "    mov w20, #0");
            emitln(ftext, "    mov w24, #-1");
            {
                char l[64];
                snprintf(l, sizeof(l), "L_idxof_loop_i_%d:", lid);
                emitln(ftext, l);
            }
            emitln(ftext, "    cmp w20, w19");
            {
                char b[64];
                snprintf(b, sizeof(b), "    b.ge L_idxof_done_i_%d", lid);
                emitln(ftext, b);
            }
            // Cargar elemento y compararlo
            emitln(ftext, "    add x14, x21, x20, lsl #2");
            emitln(ftext, "    ldr w0, [x14]");
            emitln(ftext, "    cmp w0, w22");
            {
                char b[64];
                snprintf(b, sizeof(b), "    b.eq L_idxof_found_i_%d", lid);
                emitln(ftext, b);
            }
            emitln(ftext, "    add w20, w20, #1");
            {
                char b[64];
                snprintf(b, sizeof(b), "    b L_idxof_loop_i_%d", lid);
                emitln(ftext, b);
            }
            {
                char l[64];
                snprintf(l, sizeof(l), "L_idxof_found_i_%d:", lid);
                emitln(ftext, l);
            }
            emitln(ftext, "    mov w24, w20");
            {
                char l[64];
                snprintf(l, sizeof(l), "L_idxof_done_i_%d:", lid);
                emitln(ftext, l);
            }
            // Mover resultado a w1 para el consumidor
            emitln(ftext, "    mov w1, w24");
            return INT;
        }
    }
    emitln(ftext, "    mov w1, #0");
    return INT;
}
