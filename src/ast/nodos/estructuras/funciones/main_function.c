#include "main_function.h"
#include "ast/nodos/builders.h"
#include <stdlib.h>

// Interpretar la función main es simplemente interpretar su bloque de sentencias.
Result interpretMainFunctionNode(AbstractExpresion *self, Context *context)
{
    // El bloque de sentencias es el primer y único hijo.
    return self->hijos[0]->interpret(self->hijos[0], context);
}

// Constructor del nodo MainFunction
AbstractExpresion *nuevoMainFunctionNode(AbstractExpresion *bloque, int line, int column)
{
    MainFunctionNode *nodo = malloc(sizeof(MainFunctionNode));
    buildAbstractExpresion(&nodo->base, interpretMainFunctionNode, "MainFunction", line, column);
    agregarHijo((AbstractExpresion *)nodo, bloque);
    return (AbstractExpresion *)nodo;
}