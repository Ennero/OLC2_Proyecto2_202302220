#include "ast/AbstractExpresion.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/result.h"
#include "listaExpresiones.h"
#include <stdlib.h>

// Función de interpretación para el nodo ListaExpresiones
static Result interpretListaExpresiones(AbstractExpresion *self, Context *context)
{
    (void)self;
    (void)context;
    return nuevoValorResultadoVacio();
}

// Constructor del nodo ListaExpresiones
AbstractExpresion *nuevoListaExpresiones()
{
    // reservar el espacio en memoria y obtener el puntero a este
    ListaExpresiones *nodo = malloc(sizeof(ListaExpresiones));
    if (!nodo)
        return NULL;

    // asignar valores
    buildAbstractExpresion(&nodo->base, interpretListaExpresiones, "ListaExpresiones", 0, 0);

    return (AbstractExpresion *)nodo;
}