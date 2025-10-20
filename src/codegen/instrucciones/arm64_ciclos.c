#include "codegen/instrucciones/arm64_ciclos.h"
#include "codegen/instrucciones/arm64_flujo.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_vars.h"
#include "parser.tab.h"
#include <string.h>

static void emitln(FILE *f, const char *s) { flujo_emitln(f, s); }

int arm64_emitir_ciclo(AbstractExpresion *node, FILE *ftext, EmitirNodoFn gen_node) {
    if (!node || !node->node_type) return 0;
    const char *nt = node->node_type;

    if (strcmp(nt, "ContinueStatement") == 0) {
        int cid = flujo_continue_peek();
        if (cid >= 0) { char cbr[64]; snprintf(cbr, sizeof(cbr), "    b L_continue_%d", cid); emitln(ftext, cbr); }
        else emitln(ftext, "    // 'continue' fuera de bucle; ignorado en codegen");
        return 1;
    }
    if (strcmp(nt, "BreakStatement") == 0) {
        int bid = flujo_break_peek();
        if (bid >= 0) { char brk[64]; snprintf(brk, sizeof(brk), "    b L_break_%d", bid); emitln(ftext, brk); }
        else emitln(ftext, "    // 'break' fuera de contexto; ignorado en codegen");
        return 1;
    }
    if (strcmp(nt, "WhileStatement") == 0) {
        int wid = flujo_next_label_id();
        char lcond[32], lcont[32], lbreak[32];
        snprintf(lcond, sizeof(lcond),  "L_while_cond");
        snprintf(lcont, sizeof(lcont),  "L_continue");
        snprintf(lbreak, sizeof(lbreak), "L_break");
        flujo_break_push(wid);
        flujo_continue_push(wid);
        flujo_emit_label(ftext, lcond, wid);
        emitir_eval_booleano(node->hijos[0], ftext);
        emitln(ftext, "    cmp w1, #0");
        { char bexit[64]; snprintf(bexit, sizeof(bexit), "    beq %s_%d", lbreak, wid); emitln(ftext, bexit); }
        if (node->hijos[1]) gen_node(ftext, node->hijos[1]);
        flujo_emit_label(ftext, lcont, wid);
        { char bcond[64]; snprintf(bcond, sizeof(bcond), "    b %s_%d", lcond, wid); emitln(ftext, bcond); }
        flujo_emit_label(ftext, lbreak, wid);
        flujo_continue_pop();
        flujo_break_pop();
        return 1;
    }
    if (strcmp(nt, "ForStatement") == 0) {
        int fid = flujo_next_label_id();
        vars_push_scope(ftext);
        AbstractExpresion *init = node->numHijos > 0 ? node->hijos[0] : NULL;
        AbstractExpresion *cond = node->numHijos > 1 ? node->hijos[1] : NULL;
        AbstractExpresion *update = node->numHijos > 2 ? node->hijos[2] : NULL;
        AbstractExpresion *bloque = NULL;
        if (node->numHijos > 3) { bloque = node->hijos[3]; if (bloque == NULL && node->numHijos > 4) bloque = node->hijos[4]; }
        if (init) gen_node(ftext, init);
        char lcond[32], lcont[32], lbreak[32];
        snprintf(lcond, sizeof(lcond),  "L_for_cond");
        snprintf(lcont, sizeof(lcont),  "L_continue");
        snprintf(lbreak, sizeof(lbreak), "L_break");
        flujo_break_push(fid);
        flujo_continue_push(fid);
        flujo_emit_label(ftext, lcond, fid);
        if (cond) { emitir_eval_booleano(cond, ftext); emitln(ftext, "    cmp w1, #0"); char bexit[64]; snprintf(bexit, sizeof(bexit), "    beq %s_%d", lbreak, fid); emitln(ftext, bexit); }
        if (bloque) gen_node(ftext, bloque);
        flujo_emit_label(ftext, lcont, fid);
        if (update) { const char *t = update->node_type ? update->node_type : ""; if (strcmp(t, "AsignacionCompuesta") == 0 || strcmp(t, "Reasignacion") == 0) gen_node(ftext, update); else (void)emitir_eval_numerico(update, ftext); }
        { char bcond[64]; snprintf(bcond, sizeof(bcond), "    b %s_%d", lcond, fid); emitln(ftext, bcond); }
        flujo_emit_label(ftext, lbreak, fid);
        flujo_continue_pop();
        flujo_break_pop();
        vars_pop_scope(ftext);
        return 1;
    }
    return 0;
}
