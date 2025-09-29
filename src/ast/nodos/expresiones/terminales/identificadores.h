#ifndef IDENTIFICADORES_H
#define IDENTIFICADORES_H

#include "ast/AbstractExpresion.h"

// Estructura para el nodo Identificador
typedef struct
{
    AbstractExpresion base;
    char *nombre;
    int line;
    int column;
} IdentificadorExpresion;

AbstractExpresion *nuevoIdentificadorExpresion(char *nombre, int line, int column);

#endif // IDENTIFICADORES_H