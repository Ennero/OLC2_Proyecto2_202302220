#include "codegen/instrucciones/arm64_ciclos.h"
#include "codegen/instrucciones/arm64_flujo.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_globals.h"
#include "codegen/estructuras/arm64_arreglos.h"
#include "parser.tab.h"
#include <string.h>

static void emitln(FILE *f, const char *s) { flujo_emitln(f, s); }

// Acceder a metadatos del nodo ForEach definiendo el struct equivalente
#include "ast/AbstractExpresion.h"
#include "context/result.h"
typedef struct
{
    AbstractExpresion base;
    TipoDato tipo_var;
    int dimensiones_var;
    char *nombre_var;
    int line;
    int column;
} ForEachNodeInfo;

// Emite código ARM64 para ciclos: while, for, foreach, break, continue
int arm64_emitir_ciclo(AbstractExpresion *node, FILE *ftext, EmitirNodoFn gen_node)
{
    if (!node || !node->node_type)
        return 0;
    const char *nt = node->node_type;

    // Manejo de continue
    if (strcmp(nt, "ContinueStatement") == 0)
    {
        int cid = flujo_continue_peek();
        if (cid >= 0)
        {
            char cbr[64];
            snprintf(cbr, sizeof(cbr), "    b L_continue_%d", cid);
            emitln(ftext, cbr);
        }
        else
            emitln(ftext, "    // 'continue' fuera de bucle; ignorado en codegen");
        return 1;
    }
    // Manejo de break
    if (strcmp(nt, "BreakStatement") == 0)
    {
        int bid = flujo_break_peek();
        if (bid >= 0)
        {
            char brk[64];
            snprintf(brk, sizeof(brk), "    b L_break_%d", bid);
            emitln(ftext, brk);
        }
        else
            emitln(ftext, "    // 'break' fuera de contexto; ignorado en codegen");
        return 1;
    }

    // Manejo de while
    if (strcmp(nt, "WhileStatement") == 0)
    {
        int wid = flujo_next_label_id();
        char lcond[32], lcont[32], lbreak[32];
        snprintf(lcond, sizeof(lcond), "L_while_cond");
        snprintf(lcont, sizeof(lcont), "L_continue");
        snprintf(lbreak, sizeof(lbreak), "L_break");
        flujo_break_push(wid);
        flujo_continue_push(wid);
        flujo_emit_label(ftext, lcond, wid);
        emitir_eval_booleano(node->hijos[0], ftext);
        emitln(ftext, "    cmp w1, #0");
        {
            char bexit[64];
            snprintf(bexit, sizeof(bexit), "    beq %s_%d", lbreak, wid);
            emitln(ftext, bexit);
        }
        if (node->hijos[1])
            gen_node(ftext, node->hijos[1]);
        flujo_emit_label(ftext, lcont, wid);
        {
            char bcond[64];
            snprintf(bcond, sizeof(bcond), "    b %s_%d", lcond, wid);
            emitln(ftext, bcond);
        }
        flujo_emit_label(ftext, lbreak, wid);
        flujo_continue_pop();
        flujo_break_pop();
        return 1;
    }

    // Manejo de for
    if (strcmp(nt, "ForStatement") == 0)
    {
        int fid = flujo_next_label_id();
        vars_push_scope(ftext);
        AbstractExpresion *init = node->numHijos > 0 ? node->hijos[0] : NULL;
        AbstractExpresion *cond = node->numHijos > 1 ? node->hijos[1] : NULL;
        AbstractExpresion *update = node->numHijos > 2 ? node->hijos[2] : NULL;
        AbstractExpresion *bloque = NULL;
        if (node->numHijos > 3)
        {
            bloque = node->hijos[3];
            if (bloque == NULL && node->numHijos > 4)
                bloque = node->hijos[4];
        }
        if (init)
            gen_node(ftext, init);
        char lcond[32], lcont[32], lbreak[32];
        snprintf(lcond, sizeof(lcond), "L_for_cond");
        snprintf(lcont, sizeof(lcont), "L_continue");
        snprintf(lbreak, sizeof(lbreak), "L_break");
        flujo_break_push(fid);
        flujo_continue_push(fid);
        flujo_emit_label(ftext, lcond, fid);
        if (cond)
        {
            emitir_eval_booleano(cond, ftext);
            emitln(ftext, "    cmp w1, #0");
            char bexit[64];
            snprintf(bexit, sizeof(bexit), "    beq %s_%d", lbreak, fid);
            emitln(ftext, bexit);
        }
        if (bloque)
            gen_node(ftext, bloque);
        flujo_emit_label(ftext, lcont, fid);
        if (update)
        {
            const char *t = update->node_type ? update->node_type : "";
            if (strcmp(t, "AsignacionCompuesta") == 0 || strcmp(t, "Reasignacion") == 0)
                gen_node(ftext, update);
            else
                (void)emitir_eval_numerico(update, ftext);
        }
        {
            char bcond[64];
            snprintf(bcond, sizeof(bcond), "    b %s_%d", lcond, fid);
            emitln(ftext, bcond);
        }
        flujo_emit_label(ftext, lbreak, fid);
        flujo_continue_pop();
        flujo_break_pop();
        vars_pop_scope(ftext);
        return 1;
    }

    // Manejo de foreach
    if (strcmp(nt, "ForEach") == 0)
    {
        AbstractExpresion *iterable = node->hijos[0];
        AbstractExpresion *bloque = node->hijos[1];
        ForEachNodeInfo *meta = (ForEachNodeInfo *)node;

        // Calcular puntero a arreglo en x9
        if (iterable && strcmp(iterable->node_type ? iterable->node_type : "", "Identificador") == 0)
        {
            IdentificadorExpresion *id = (IdentificadorExpresion *)iterable;
            VarEntry *v = vars_buscar(id->nombre);
            if (v)
            {
                char ld[96];
                snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x9, [x16]", v->offset);
                emitln(ftext, ld);
            }
            else
            {
                const GlobalInfo *gi = globals_lookup(id->nombre);
                if (gi)
                {
                    char lg[128];
                    snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x9, [x16]", id->nombre);
                    emitln(ftext, lg);
                }
                else
                    emitln(ftext, "    mov x9, #0");
            }

            int fid = flujo_next_label_id();
            flujo_break_push(fid);
            flujo_continue_push(fid);
            vars_push_scope(ftext);

            // Declarar variable iteradora en el nuevo scope si no existe
            const char *iter_name = meta->nombre_var ? meta->nombre_var : "__it";
            VarEntry *itv = vars_buscar(iter_name);
            TipoDato iter_tipo = (meta->dimensiones_var > 0) ? ARRAY : meta->tipo_var;

            // Crear slot local para la variable iteradora si no existe
            if (!itv)
            {
                int size_bytes = (iter_tipo == ARRAY || iter_tipo == STRING || iter_tipo == DOUBLE || iter_tipo == FLOAT) ? 8 : 8;
                itv = vars_agregar_ext(iter_name, iter_tipo, size_bytes, 0, ftext);

                // Si es arreglo 
                if (iter_tipo == ARRAY)
                {
                    // Base del arreglo iterador es el base del iterable original
                    TipoDato base_t = arm64_array_elem_tipo_for_var(id->nombre);
                    arm64_registrar_arreglo(iter_name, base_t);
                }
            }

            // Crear/obtener slot local para el índice del foreach 
            char idxname[32];
            snprintf(idxname, sizeof(idxname), "__it_idx_%d", fid);
            VarEntry *idxv = vars_buscar(idxname);
            if (!idxv)
            {
                idxv = vars_agregar_ext(idxname, INT, 8, 0, ftext);
            }
            // i=0
            emitln(ftext, "    mov w20, #0");

            // Guardar índice inicial en su slot anclado al frame pointer
            {
                char stx[128];
                snprintf(stx, sizeof(stx), "    sub x16, x29, #%d\n    str w20, [x16]", idxv->offset);
                emitln(ftext, stx);
            }
            flujo_emit_label(ftext, "L_for_cond", fid);

            emitln(ftext, "    // ForEach: recomputar base de datos y longitud");

            // Recargar puntero al iterable en x9
            {
                if (v)
                {
                    char ldx[96];
                    snprintf(ldx, sizeof(ldx), "    sub x16, x29, #%d\n    ldr x9, [x16]", v->offset);
                    emitln(ftext, ldx);
                }
                else
                {
                    const GlobalInfo *gi = globals_lookup(id->nombre);
                    if (gi)
                    {
                        char lg2[128];
                        snprintf(lg2, sizeof(lg2), "    ldr x16, =g_%s\n    ldr x9, [x16]", id->nombre);
                        emitln(ftext, lg2);
                    }
                    else
                        emitln(ftext, "    mov x9, #0");
                }
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

            // Cargar índice actual desde el slot persistente
            {
                char ldx[128];
                snprintf(ldx, sizeof(ldx), "    sub x16, x29, #%d\n    ldr w20, [x16]", idxv->offset);
                emitln(ftext, ldx);
            }
            emitln(ftext, "    cmp w20, w19");
            {
                char be[64];
                snprintf(be, sizeof(be), "    b.ge L_break_%d", fid);
                emitln(ftext, be);
            }

            // Cargar elemento según tipo base registrado del iterable
            TipoDato base_t = arm64_array_elem_tipo_for_var(((IdentificadorExpresion *)iterable)->nombre);
            if (meta->dimensiones_var > 0)
            {
                // Iterador es un arreglo 1D (
                emitln(ftext, "    add x22, x21, x20, lsl #3");
                emitln(ftext, "    ldr x0, [x22]");
                // Guardar en variable iteradora (tipo ARRAY)
                char st[128];
                snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x0, [x16]", itv->offset);
                emitln(ftext, st);
            }
            else
            {
                // Iterador primitivo
                if (base_t == STRING)
                {
                    // Elementos son punteros 
                    emitln(ftext, "    add x22, x21, x20, lsl #3");
                    emitln(ftext, "    ldr x1, [x22]");
                    char st[128];
                    snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str x1, [x16]", itv->offset);
                    emitln(ftext, st);
                }

                // Otros tipos primitivos
                else if (base_t == DOUBLE || base_t == FLOAT)
                {
                    emitln(ftext, "    add x22, x21, x20, lsl #3");
                    emitln(ftext, "    ldr d0, [x22]");
                    char st[128];
                    snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str d0, [x16]", itv->offset);
                    emitln(ftext, st);
                }

                // Enteros y chars
                else if (base_t == CHAR)
                {
                    emitln(ftext, "    add x22, x21, x20, lsl #2");
                    emitln(ftext, "    ldrb w1, [x22]");
                    char st[128];
                    snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w1, [x16]", itv->offset);
                    emitln(ftext, st);
                }

                // Enteros y demás tipos
                else
                {
                    emitln(ftext, "    add x22, x21, x20, lsl #2");
                    emitln(ftext, "    ldr w1, [x22]");
                    char st[128];
                    snprintf(st, sizeof(st), "    sub x16, x29, #%d\n    str w1, [x16]", itv->offset);
                    emitln(ftext, st);
                }
            }

            // Ejecutar bloque 
            {
                char stx2[128];
                snprintf(stx2, sizeof(stx2), "    sub x16, x29, #%d\n    str w20, [x16]", idxv->offset);
                emitln(ftext, stx2);
            }
            if (bloque)
                gen_node(ftext, bloque);
            flujo_emit_label(ftext, "L_continue", fid);

            // Recargar índice, incrementarlo y guardarlo de vuelta
            {
                char ldx2[128];
                snprintf(ldx2, sizeof(ldx2), "    sub x16, x29, #%d\n    ldr w20, [x16]", idxv->offset);
                emitln(ftext, ldx2);
            }
            emitln(ftext, "    add w20, w20, #1");
            {
                char stx3[128];
                snprintf(stx3, sizeof(stx3), "    sub x16, x29, #%d\n    str w20, [x16]", idxv->offset);
                emitln(ftext, stx3);
            }
            {
                char bb[64];
                snprintf(bb, sizeof(bb), "    b L_for_cond_%d", fid);
                emitln(ftext, bb);
            }
            flujo_emit_label(ftext, "L_break", fid);
            vars_pop_scope(ftext);
            flujo_continue_pop();
            flujo_break_pop();
            return 1;
        }
        
        // Otro tipo iterable no soportado aún
        return 1;
    }
    return 0;
}
