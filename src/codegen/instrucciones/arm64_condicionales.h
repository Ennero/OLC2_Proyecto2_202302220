#ifndef ARM64_CONDICIONALES_H
#define ARM64_CONDICIONALES_H
#include "ast/AbstractExpresion.h"
#include <stdio.h>

// Callback para emitir un subnodo (evita dependencia circular)
typedef void (*EmitirNodoFn)(FILE *ftext, AbstractExpresion *node);

// Devuelve 1 si manejó el nodo (IfStatement/SwitchStatement), 0 si no.
int arm64_emitir_condicional(AbstractExpresion *node, FILE *ftext, EmitirNodoFn emitir_nodo_cb);

#endif // ARM64_CONDICIONALES_H
