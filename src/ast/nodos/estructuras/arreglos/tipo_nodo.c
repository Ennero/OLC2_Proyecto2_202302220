#include "ast/AbstractExpresion.h"
#include <stdlib.h>

typedef struct
{
    AbstractExpresion base;
    TipoDato tipo;
} TypeNodeExpresion;

// Interpretar un nodo de tipo simplemente devuelve el tipo almacenado en él.
Result interpretTipoNode(AbstractExpresion *self, Context *context)
{
    (void)context;
    TypeNodeExpresion *nodo = (TypeNodeExpresion *)self;
    return nuevoValorResultado(NULL, nodo->tipo);
}

// Constructor del nodo TypeNode
AbstractExpresion *nuevoTipoNode(TipoDato tipo)
{
    TypeNodeExpresion *nodo = malloc(sizeof(TypeNodeExpresion));
    if (!nodo)
        return NULL;
    buildAbstractExpresion(&nodo->base, interpretTipoNode, "TypeNode", 0, 0);
    nodo->tipo = tipo;
    return (AbstractExpresion *)nodo;
}