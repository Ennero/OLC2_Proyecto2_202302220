#ifndef ARM64_BOOL_H
#define ARM64_BOOL_H
#include "ast/AbstractExpresion.h"
#include <stdio.h>

void emitir_eval_booleano(AbstractExpresion *node, FILE *ftext);
int nodo_es_resultado_booleano(AbstractExpresion *node);

#endif // ARM64_BOOL_H
