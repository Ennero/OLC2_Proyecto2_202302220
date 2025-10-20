#ifndef ARM64_ARREGLOS_H
#define ARM64_ARREGLOS_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"

int arm64_emitir_asignacion_arreglo(AbstractExpresion *node, FILE *ftext);
void arm64_emit_runtime_arreglo_helpers(FILE *ftext);

#endif // ARM64_ARREGLOS_H
