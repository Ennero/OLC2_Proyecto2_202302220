#ifndef CASTEOS_H
#define CASTEOS_H

#include "ast/AbstractExpresion.h"
#include "context/context.h"

// Estructura para un nodo de casteo explícito
typedef struct
{
    AbstractExpresion base;
    TipoDato tipo_destino;
} CasteoExpresion;

AbstractExpresion *nuevoCasteoExpresion(TipoDato tipo_destino, AbstractExpresion *expresion, int line, int column);

#endif // CASTEOS_H
