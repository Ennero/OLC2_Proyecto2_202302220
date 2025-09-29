#ifndef BLOQUE_H
#define BLOQUE_H

#include "ast/AbstractExpresion.h"

// Nodo para un bloque de instrucciones
typedef struct
{
    AbstractExpresion base;
} BloqueExpresion;

#endif
