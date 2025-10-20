#ifndef ARM64_ASIGNACION_COMPUESTA_H
#define ARM64_ASIGNACION_COMPUESTA_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"

int arm64_emitir_asignacion_compuesta(AbstractExpresion *node, FILE *ftext);

#endif // ARM64_ASIGNACION_COMPUESTA_H
