#ifndef ARM64_CICLOS_H
#define ARM64_CICLOS_H
#include "ast/AbstractExpresion.h"
#include <stdio.h>

typedef void (*EmitirNodoFn)(FILE *ftext, AbstractExpresion *node);

int arm64_emitir_ciclo(AbstractExpresion *node, FILE *ftext, EmitirNodoFn emitir_nodo_cb);

#endif // ARM64_CICLOS_H
