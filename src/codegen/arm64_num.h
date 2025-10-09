#ifndef ARM64_NUM_H
#define ARM64_NUM_H
#include "ast/AbstractExpresion.h"
#include "context/result.h"
#include <stdio.h>

TipoDato emitir_eval_numerico(AbstractExpresion *node, FILE *ftext);

#endif // ARM64_NUM_H
