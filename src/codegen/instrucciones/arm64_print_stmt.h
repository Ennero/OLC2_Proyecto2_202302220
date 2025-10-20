#ifndef ARM64_PRINT_STMT_H
#define ARM64_PRINT_STMT_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"

// Maneja nodos de tipo Print y retorna 1 si lo manejó, 0 si no.
int arm64_emitir_print_stmt(AbstractExpresion *node, FILE *ftext);

#endif // ARM64_PRINT_STMT_H
