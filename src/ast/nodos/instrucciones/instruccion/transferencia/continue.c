#include "ast/nodos/builders.h"
#include <stdlib.h>

// El constructor para el nodo de instrucción de continue
Result interpretContinueExpresion(AbstractExpresion *self, Context *context)
{
    // No se usan los parámetros
    (void)self;
    (void)context;
    return nuevoValorResultado(NULL, CONTINUE_T);
}

// El constructor para el nodo de instrucción de continue
AbstractExpresion *nuevoContinueExpresion(int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretContinueExpresion, "ContinueStatement", line, column);
    return nodo;
}