#include "AbstractExpresion.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Agrega un hijo a un nodo padre
void agregarHijo(AbstractExpresion *padre, AbstractExpresion *hijo)
{
    // Validar entradas
    if (!padre || !hijo)
        return;

    // Realizar realloc para aumentar el tamaño del arreglo de hijos
    AbstractExpresion **newarr = realloc(padre->hijos, sizeof(AbstractExpresion *) * (padre->numHijos + 1));

    // Manejar error de realloc
    if (!newarr)
    {
        perror("realloc");
        exit(EXIT_FAILURE);
    }

    // Actualizar el puntero y agregar el nuevo hijo
    padre->hijos = newarr;
    padre->hijos[padre->numHijos] = hijo;
    padre->numHijos++;
}

// Libera recursivamente el árbol de expresiones
void liberarAST(AbstractExpresion *raiz)
{
    // Si no hay nodo, retornar
    if (!raiz)
        return;

    // Liberar recursivamente cada hijo
    for (size_t i = 0; i < raiz->numHijos; ++i)
    {
        liberarAST(raiz->hijos[i]);
    }

    if (raiz->cleanup)
    {
        raiz->cleanup(raiz);
    }

    // Liberar el arreglo de hijos y el nodo actual
    free(raiz->hijos);
    free(raiz);
}

// Se añade el parámetro 'node_type'
void buildAbstractExpresion(AbstractExpresion *base, Interpret interpretPuntero, const char *node_type, int line, int column)
{
    base->interpret = interpretPuntero;
    base->generar = NULL;
    base->cleanup = NULL;
    base->node_type = node_type; // Se asigna el nombre
    base->hijos = NULL;
    base->numHijos = 0;
    base->line = line;
    base->column = column;
}