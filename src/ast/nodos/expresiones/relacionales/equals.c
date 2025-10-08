#include "ast/nodos/builders.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// La función que interpreta la llamada a .equals()
Result interpretEqualsExpresion(AbstractExpresion *self, Context *context)
{
    Result izquierda = self->hijos[0]->interpret(self->hijos[0], context);
    Result derecha = self->hijos[1]->interpret(self->hijos[1], context);

    if (has_semantic_error_been_found())
    {
        free(izquierda.valor);
        free(derecha.valor);
        return nuevoValorResultadoVacio();
    }

    // Ambos deben ser strings
    if (izquierda.tipo != STRING || derecha.tipo != STRING)
    {
        char desc[256];
        sprintf(desc, "El método '.equals()' solo se puede aplicar entre Strings, no entre '%s' y '%s'.", labelTipoDato[izquierda.tipo], labelTipoDato[derecha.tipo]);
        add_error_to_report("Semantico", ".equals()", desc, self->line, self->column, context->nombre_completo);
        free(izquierda.valor);
        free(derecha.valor);
        return nuevoValorResultadoVacio();
    }

    // Debug
    printf("DEBUG [equals]: Comparando A='%s' con B='%s'\n", (char *)izquierda.valor, (char *)derecha.valor);

    // Realizar la comparación
    int *res = malloc(sizeof(int));
    *res = (strcmp((char *)izquierda.valor, (char *)derecha.valor) == 0);

    // Debug
    printf("DEBUG [equals]: El resultado de la comparación es %s\n", *res ? "true" : "false");

    free(izquierda.valor);
    free(derecha.valor);

    return nuevoValorResultado(res, BOOLEAN);
}

// El constructor para el nodo
AbstractExpresion *nuevoEqualsExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    if (!nodo)
        return NULL;

    buildAbstractExpresion(nodo, interpretEqualsExpresion, "EqualsMethod", line, column);
    agregarHijo(nodo, izquierda);
    agregarHijo(nodo, derecha);

    return nodo;
}