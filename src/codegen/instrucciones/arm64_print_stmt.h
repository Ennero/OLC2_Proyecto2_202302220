#ifndef ARM64_PRINT_STMT_H
#define ARM64_PRINT_STMT_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"

int arm64_emitir_print_stmt(AbstractExpresion *node, FILE *ftext);

#endif // ARM64_PRINT_STMT_H
