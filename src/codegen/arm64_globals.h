#ifndef ARM64_GLOBALS_H
#define ARM64_GLOBALS_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"
#include "context/result.h" // for TipoDato

typedef struct GlobalInfo {
    const char *name;
    TipoDato tipo;
    int is_const;
    AbstractExpresion *init; // puede ser NULL o un Primitivo
} GlobalInfo;

void globals_reset(void);
void globals_register(const char *name, TipoDato tipo, int is_const, AbstractExpresion *init);
const GlobalInfo *globals_lookup(const char *name);
void globals_emit_data(FILE *f);

#endif
