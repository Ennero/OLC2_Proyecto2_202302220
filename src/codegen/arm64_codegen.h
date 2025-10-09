#ifndef ARM64_CODEGEN_H
#define ARM64_CODEGEN_H

#include "ast/AbstractExpresion.h"

// Genera un archivo en ensamblador AArch64 que, por ahora, solo
// soporta sentencias Print con literales primitivos.
// out_path: ruta del archivo de salida (por ejemplo: "arm/salida.s")
// Retorna 0 si todo fue bien, distinto de 0 si hubo algún error.
int arm64_generate_program(AbstractExpresion *root, const char *out_path);

#endif // ARM64_CODEGEN_H
