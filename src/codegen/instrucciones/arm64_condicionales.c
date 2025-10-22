#include "codegen/instrucciones/arm64_condicionales.h"
#include "codegen/instrucciones/arm64_flujo.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_print.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_core.h"
#include <string.h>

static void emitln(FILE *f, const char *s) { flujo_emitln(f, s); }

// Emite código ARM64 para instrucciones condicionales: if, switch
int arm64_emitir_condicional(AbstractExpresion *node, FILE *ftext, EmitirNodoFn gen_node)
{
    if (!node || !node->node_type)
        return 0;
    const char *nt = node->node_type;

    // IfStatement
    if (strcmp(nt, "IfStatement") == 0)
    {
        int id = flujo_next_label_id();
        char thenp[32], elsep[32], endp[32];
        snprintf(thenp, sizeof(thenp), "L_then");
        snprintf(elsep, sizeof(elsep), "L_else");
        snprintf(endp, sizeof(endp), "L_end");
        emitir_eval_booleano(node->hijos[0], ftext);
        emitln(ftext, "    cmp w1, #0");

        // Salto condicional al bloque else o end
        if (node->numHijos > 2 && node->hijos[2] != NULL)
        {
            char br_else[64];
            snprintf(br_else, sizeof(br_else), "    beq %s_%d", elsep, id);
            emitln(ftext, br_else);
        }

        // Salto condicional al bloque end
        else
        {
            char br_end[64];
            snprintf(br_end, sizeof(br_end), "    beq %s_%d", endp, id);
            emitln(ftext, br_end);
        }
        flujo_emit_label(ftext, thenp, id);
        if (node->hijos[1])
            gen_node(ftext, node->hijos[1]);
        if (node->numHijos > 2 && node->hijos[2] != NULL)
        {
            char br_end2[64];
            snprintf(br_end2, sizeof(br_end2), "    b %s_%d", endp, id);
            emitln(ftext, br_end2);
            flujo_emit_label(ftext, elsep, id);
            gen_node(ftext, node->hijos[2]);
        }
        flujo_emit_label(ftext, endp, id);
        return 1;
    }

    // SwitchStatement 
    if (strcmp(nt, "SwitchStatement") == 0)
    {
        emitln(ftext, "    // --- Generando switch ---");
        AbstractExpresion *selector = node->hijos[0];
        AbstractExpresion *case_list = node->hijos[1];
        int sid = flujo_next_label_id();
        int is_stringy = expresion_es_cadena(selector);
        if (is_stringy)
        {
            int ok = emitir_eval_string_ptr(selector, ftext);
            if (!ok)
                emitir_string_valueof(selector, ftext);
            emitln(ftext, "    mov x19, x1");
        }
        else
        {
            TipoDato ty = emitir_eval_numerico(selector, ftext);
            if (ty == DOUBLE)
                emitln(ftext, "    fcvtzs w19, d0");
            else
                emitln(ftext, "    mov w19, w1");
        }
        int has_default = 0;

        // Recorriendo cases para generar comparaciones
        for (size_t i = 0; i < (case_list ? case_list->numHijos : 0); i++)
        {
            AbstractExpresion *c = case_list->hijos[i];
            if (c && c->node_type && strcmp(c->node_type, "DefaultCase") == 0)
            {
                has_default = 1;
                break;
            }
        }

        // Recorriendo cases para generar comparaciones
        for (size_t i = 0; i < (case_list ? case_list->numHijos : 0); i++)
        {
            AbstractExpresion *c = case_list->hijos[i];
            if (!c || !c->node_type)
                continue;
            if (strcmp(c->node_type, "DefaultCase") == 0)
                continue;
            char lab_case[64];
            snprintf(lab_case, sizeof(lab_case), "L_case_%zu_%d", i, sid);
            if (is_stringy)
            {
                emitln(ftext, "    // comparar selector string con case string");
                if (!emitir_eval_string_ptr(c->hijos[0], ftext))
                {
                    emitir_string_valueof(c->hijos[0], ftext);
                }
                emitln(ftext, "    mov x0, x19");
                emitln(ftext, "    // strcmp(x0, x1) == 0 ? goto case");
                emitln(ftext, "    bl strcmp");
                emitln(ftext, "    cmp w0, #0");
                char br_eq[96];
                snprintf(br_eq, sizeof(br_eq), "    beq %s", lab_case);
                emitln(ftext, br_eq);
            }
            else
            {
                emitln(ftext, "    // comparar selector int con case int");
                TipoDato tcase = emitir_eval_numerico(c->hijos[0], ftext);
                if (tcase == DOUBLE)
                    emitln(ftext, "    fcvtzs w20, d0");
                else
                    emitln(ftext, "    mov w20, w1");
                emitln(ftext, "    cmp w19, w20");
                char br_eq[96];
                snprintf(br_eq, sizeof(br_eq), "    beq %s", lab_case);
                emitln(ftext, br_eq);
            }
        }

        // Salto al default o fin
        if (has_default)
        {
            char jdef[64];
            snprintf(jdef, sizeof(jdef), "    b L_default_%d", sid);
            emitln(ftext, jdef);
        }
        else
        {
            char jend[64];
            snprintf(jend, sizeof(jend), "    b L_break_%d", sid);
            emitln(ftext, jend);
        }
        flujo_break_push(sid);

        // Generando código de los cases
        for (size_t i = 0; i < (case_list ? case_list->numHijos : 0); i++)
        {
            AbstractExpresion *c = case_list->hijos[i];
            if (!c || !c->node_type)
                continue;
            if (strcmp(c->node_type, "DefaultCase") == 0)
            {
                flujo_emit_label(ftext, "L_default", sid);
                if (c->numHijos > 0 && c->hijos[0])
                    gen_node(ftext, c->hijos[0]);
            }
            else
            {
                char lab_case[64];
                snprintf(lab_case, sizeof(lab_case), "L_case_%zu", i);
                flujo_emit_label(ftext, lab_case, sid);
                if (c->numHijos > 1 && c->hijos[1])
                    gen_node(ftext, c->hijos[1]);
            }
        }

        // Final del switch
        flujo_emit_label(ftext, "L_break", sid);
        flujo_break_pop();
        return 1;
    }
    return 0;
}
