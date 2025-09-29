#ifndef REASIGNACION_H
#define REASIGNACION_H

#include "ast/AbstractExpresion.h"

// Estructura para un nodo de reasignación.
typedef struct
{
    AbstractExpresion base;
    char *nombre;
    int line;
    int column;
} ReasignacionExpresion;

#endif // REASIGNACION_H
