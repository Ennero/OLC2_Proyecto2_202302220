#ifndef ABSTRACT_EXPRESION_H
#define ABSTRACT_EXPRESION_H

#include "context/result.h"
#include "context/context.h"
#include <stddef.h>

typedef struct AbstractExpresion AbstractExpresion;
typedef Result (*Interpret)(AbstractExpresion *, Context *);

// Estructura base para todas las expresiones abstractas
struct AbstractExpresion
{
    Interpret interpret;
    const char *node_type;
    AbstractExpresion **hijos;
    size_t numHijos;
    int line;
    int column;
};

// Funciones para manejar el árbol de expresiones
void agregarHijo(AbstractExpresion *padre, AbstractExpresion *hijo);
void liberarAST(AbstractExpresion *raiz);
void buildAbstractExpresion(AbstractExpresion *base, Interpret interpretPuntero, const char *node_type, int line, int column);

#endif // ABSTRACT_EXPRESION_H
