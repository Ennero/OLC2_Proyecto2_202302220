#include "ast/nodos/builders.h"
#include <stdlib.h>

// El nodo 'case' solo agrupa, la lógica está en el 'switch'
Result interpretCaseExpresion(AbstractExpresion *self, Context *context)
{
    return self->hijos[1]->interpret(self->hijos[1], context);
}

// Constructor para el nodo 'case'
AbstractExpresion *nuevoCaseExpresion(AbstractExpresion *expr, AbstractExpresion *sentencias, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretCaseExpresion, "Case", line, column);
    agregarHijo(nodo, expr);
    agregarHijo(nodo, sentencias);
    return nodo;
}

// El nodo 'default'
Result interpretDefaultExpresion(AbstractExpresion *self, Context *context)
{
    return self->hijos[0]->interpret(self->hijos[0], context);
}

// Constructor para el nodo 'default'
AbstractExpresion *nuevoDefaultExpresion(AbstractExpresion *sentencias, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretDefaultExpresion, "DefaultCase", line, column);
    agregarHijo(nodo, sentencias);
    return nodo;
}