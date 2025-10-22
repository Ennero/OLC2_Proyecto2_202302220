#ifndef ARM64_FUNCIONES_H
#define ARM64_FUNCIONES_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"
#include "context/result.h"

typedef struct Arm64FuncionInfo
{
    char *name;
    TipoDato ret;
    int param_count;
    TipoDato param_types[8];
    char *param_names[8];
    AbstractExpresion *body;
} Arm64FuncionInfo;

void arm64_funciones_reset(void);
void arm64_funciones_colectar(AbstractExpresion *n);
int arm64_funciones_count(void);
const Arm64FuncionInfo *arm64_funciones_get(int idx);

// Emite una llamada a función usando el ABI AArch64 y retorna el tipo de retorno.
TipoDato arm64_emitir_llamada_funcion(AbstractExpresion *call_node, FILE *ftext);

#endif // ARM64_FUNCIONES_H
