#include "main_function.h"
#include "ast/nodos/builders.h"
#include "compilacion/generador_codigo.h"
#include <stdlib.h>

// Nodo específico para la función main
static const char *generarMainFunction(AbstractExpresion *self, GeneradorCodigo *generador, Context *context)
{
    if (!self || self->numHijos == 0)
        return NULL;

    // El bloque de sentencias es el primer y único hijo.
    AbstractExpresion *bloque = self->hijos[0];
    if (bloque && bloque->generar)
    {
        bloque->generar(bloque, generador, context);
    }
    return NULL;
}

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
    nodo->base.generar = generarMainFunction;
    agregarHijo((AbstractExpresion *)nodo, bloque);
    return (AbstractExpresion *)nodo;
}