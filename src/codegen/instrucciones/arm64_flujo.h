#ifndef ARM64_FLUJO_H
#define ARM64_FLUJO_H
#include <stdio.h>

// Emisor de una línea (delegado por core)
void flujo_emitln(FILE *f, const char *s);

// Generación de etiquetas secuenciales
int flujo_next_label_id(void);
void flujo_emit_label(FILE *f, const char *prefix, int id);

// Pilas de control para break/continue
void flujo_break_push(int id);
int  flujo_break_peek(void);
void flujo_break_pop(void);

void flujo_continue_push(int id);
int  flujo_continue_peek(void);
void flujo_continue_pop(void);

#endif // ARM64_FLUJO_H
