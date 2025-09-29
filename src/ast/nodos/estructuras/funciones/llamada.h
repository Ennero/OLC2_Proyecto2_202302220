#ifndef LLAMADA_H
#define LLAMADA_H

#include "ast/AbstractExpresion.h"

typedef struct
{
    AbstractExpresion base;
    char *nombre;
} LlamadaFuncionNode;

#endif // LLAMADA_H