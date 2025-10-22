#ifndef ARM64_CONDICIONALES_H
#define ARM64_CONDICIONALES_H
#include "ast/AbstractExpresion.h"
#include <stdio.h>

typedef void (*EmitirNodoFn)(FILE *ftext, AbstractExpresion *node);

int arm64_emitir_condicional(AbstractExpresion *node, FILE *ftext, EmitirNodoFn emitir_nodo_cb);

#endif // ARM64_CONDICIONALES_H
