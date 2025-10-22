#include "codegen/instrucciones/arm64_flujo.h"
#include "codegen/arm64_core.h"
#include <string.h>

static int __label_seq_shared = 0;
static int break_label_stack[64];
static int break_label_sp = 0;
static int continue_label_stack[64];
static int continue_label_sp = 0;

void flujo_emitln(FILE *f, const char *s) { core_emitln(f, s); }

int flujo_next_label_id(void) { return ++__label_seq_shared; }

// Emite una etiqueta de flujo con el prefijo y ID dados
void flujo_emit_label(FILE *f, const char *prefix, int id)
{
    char lab[64];
    snprintf(lab, sizeof(lab), "%s_%d:", prefix, id);
    flujo_emitln(f, lab);
}

// Manejo de pilas de etiquetas para break/continue
void flujo_break_push(int id)
{
    if (break_label_sp < (int)(sizeof(break_label_stack) / sizeof(break_label_stack[0])))
        break_label_stack[break_label_sp++] = id;
}

// Devuelve el ID de la etiqueta tope de la pila de break, o -1 si está vacía
int flujo_break_peek(void) { return break_label_sp > 0 ? break_label_stack[break_label_sp - 1] : -1; }
void flujo_break_pop(void)
{
    if (break_label_sp > 0)
        break_label_sp--;
}

// Manejo de pilas de etiquetas para continue
void flujo_continue_push(int id)
{
    if (continue_label_sp < (int)(sizeof(continue_label_stack) / sizeof(continue_label_stack[0])))
        continue_label_stack[continue_label_sp++] = id;
}

// Devuelve el ID de la etiqueta tope de la pila de continue, o -1 si está vacía
int flujo_continue_peek(void) { return continue_label_sp > 0 ? continue_label_stack[continue_label_sp - 1] : -1; }
void flujo_continue_pop(void)
{
    if (continue_label_sp > 0)
        continue_label_sp--;
}
