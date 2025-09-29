#ifndef FOR_H
#define FOR_H

#include "ast/AbstractExpresion.h"

typedef struct
{
    AbstractExpresion base;
} ForExpresion;

// Prototipo del constructor que usará el parser
AbstractExpresion *nuevoForExpresion(
    AbstractExpresion *init,
    AbstractExpresion *cond,
    AbstractExpresion *update,
    AbstractExpresion *bloque,
    int line,
    int column);

#endif // FOR_H