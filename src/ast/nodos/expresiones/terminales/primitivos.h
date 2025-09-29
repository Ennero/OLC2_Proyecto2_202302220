#ifndef PRIMITIVOS_H
#define PRIMITIVOS_H

#include "ast/AbstractExpresion.h"
#include "context/context.h"
#include "context/result.h"

typedef struct
{
    AbstractExpresion base;
    TipoDato tipo;
    char *valor;
} PrimitivoExpresion;

Result interpretPrimitivoExpresion(AbstractExpresion *, Context *);
#endif // PRIMITIVOS_H