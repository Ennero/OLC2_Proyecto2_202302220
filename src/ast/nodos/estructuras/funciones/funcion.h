#ifndef FUNCION_H
#define FUNCION_H
#include "ast/AbstractExpresion.h"

typedef struct
{
    AbstractExpresion base;
    char *nombre;
    TipoDato tipo_retorno;
    int retorno_dimensiones;
} FuncionDeclarationNode;

#endif // FUNCION_H