#ifndef ARM64_CODEGEN_H
#define ARM64_CODEGEN_H

#include "ast/AbstractExpresion.h"

// Genera un archivo en ensamblador AArch64 que, por ahora, solo
// Retorna 0 si todo fue bien, distinto de 0 si hubo algún error.
int arm64_generate_program(AbstractExpresion *root, const char *out_path);

#endif // ARM64_CODEGEN_H
