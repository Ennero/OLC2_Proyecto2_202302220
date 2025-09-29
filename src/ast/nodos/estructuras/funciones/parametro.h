#ifndef PARAMETRO_H
#define PARAMETRO_H

#include "ast/AbstractExpresion.h"

typedef struct
{
    AbstractExpresion base;
    TipoDato tipo;
    int dimensiones;
    char *nombre;
} ParametroNode;

#endif // PARAMETRO_H