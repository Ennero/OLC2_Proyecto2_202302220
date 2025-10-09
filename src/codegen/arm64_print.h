#ifndef ARM64_PRINT_H
#define ARM64_PRINT_H
#include "ast/AbstractExpresion.h"
#include <stdio.h>

int expresion_es_cadena(AbstractExpresion *node);
void emitir_imprimir_cadena(AbstractExpresion *node, FILE *ftext);

#endif // ARM64_PRINT_H
