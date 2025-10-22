#ifndef ARM64_DECLARACIONES_H
#define ARM64_DECLARACIONES_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"

int arm64_emitir_declaracion(AbstractExpresion *node, FILE *ftext);

#endif // ARM64_DECLARACIONES_H
