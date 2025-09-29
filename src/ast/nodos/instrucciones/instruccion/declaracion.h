#ifndef DECLARACION_H
#define DECLARACION_H

#include "ast/AbstractExpresion.h"
#include "context/context.h"
#include "context/result.h"

typedef struct
{
    AbstractExpresion base;
    char *nombre;
    TipoDato tipo;
    int dimensiones;
    int es_constante; // 1 si se declaró como 'final'
    int line;
    int column;
} DeclaracionVariable;

Result interpretDeclaracionVariable(AbstractExpresion *, Context *);
AbstractExpresion *nuevoDeclaracionVariable(TipoDato tipo, int dimensiones, char *nombre, AbstractExpresion *expresion, int line, int column);

#endif // DECLARACION_H