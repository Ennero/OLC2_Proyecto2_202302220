#ifndef ARM64_DECLARACIONES_H
#define ARM64_DECLARACIONES_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"

// Maneja nodos de tipo Declaracion y retorna 1 si lo manejó, 0 si no.
int arm64_emitir_declaracion(AbstractExpresion *node, FILE *ftext);

#endif // ARM64_DECLARACIONES_H
