#include "parametro.h"
#include "ast/nodos/builders.h"
#include <stdlib.h>

Result interpretParametro(AbstractExpresion *self, Context *context)
{
    (void)self;
    (void)context;
    return nuevoValorResultadoVacio();
}

AbstractExpresion *nuevoParametro(TipoDato tipo, int dimensiones, char *nombre)
{
    // reservar el espacio en memoria y obtener el puntero a este
    ParametroNode *nodo = malloc(sizeof(ParametroNode));
    buildAbstractExpresion(&nodo->base, interpretParametro, "Parametro", 0, 0);
    nodo->tipo = tipo;
    nodo->dimensiones = dimensiones;
    nodo->nombre = nombre;
    return (AbstractExpresion *)nodo;
}