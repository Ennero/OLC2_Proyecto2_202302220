#ifndef ARM64_REASIGNACIONES_H
#define ARM64_REASIGNACIONES_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"

// Maneja nodos de tipo Reasignacion y retorna 1 si lo manejó, 0 si no.
int arm64_emitir_reasignacion(AbstractExpresion *node, FILE *ftext);

#endif // ARM64_REASIGNACIONES_H
