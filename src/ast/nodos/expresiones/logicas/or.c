#include "logicas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdio.h>
#include <stdlib.h>

static Result nuevoResultadoBooleano(int valor)
{
    int *res = malloc(sizeof(int));
    if (!res)
        return nuevoValorResultadoVacio();

    *res = valor ? 1 : 0;
    return nuevoValorResultado(res, BOOLEAN);
}

static Result interpretOrExpresion(AbstractExpresion *self, Context *context)
{
    Result izquierda = self->hijos[0]->interpret(self->hijos[0], context);

    if (has_semantic_error_been_found())
    {
        if (izquierda.tipo != ARRAY)
            free(izquierda.valor);
        return nuevoValorResultadoVacio();
    }

    int izquierda_bool = 0;
    if (!convertirResultadoLogico(&izquierda, &izquierda_bool))
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "El operador lógico '||' no se puede aplicar a un valor de tipo '%s'.", labelTipoDato[izquierda.tipo]);
        add_error_to_report("Semantico", "||", desc, self->line, self->column, context->nombre_completo);
        if (izquierda.tipo != ARRAY)
            free(izquierda.valor);
        return nuevoValorResultadoVacio();
    }

    if (izquierda.tipo != ARRAY)
        free(izquierda.valor);

    if (izquierda_bool)
    {
        return nuevoResultadoBooleano(1);
    }

    Result derecha = self->hijos[1]->interpret(self->hijos[1], context);

    if (has_semantic_error_been_found())
    {
        if (derecha.tipo != ARRAY)
            free(derecha.valor);
        return nuevoValorResultadoVacio();
    }

    int derecha_bool = 0;
    if (!convertirResultadoLogico(&derecha, &derecha_bool))
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "El operador lógico '||' no se puede aplicar a un valor de tipo '%s'.", labelTipoDato[derecha.tipo]);
        add_error_to_report("Semantico", "||", desc, self->line, self->column, context->nombre_completo);
        if (derecha.tipo != ARRAY)
            free(derecha.valor);
        return nuevoValorResultadoVacio();
    }

    if (derecha.tipo != ARRAY)
        free(derecha.valor);

    return nuevoResultadoBooleano(derecha_bool);
}

// Constructor del Nodo del AST
AbstractExpresion *nuevoOrExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretOrExpresion, izquierda, derecha, line, column);
    expr->base.node_type = "Or";
    expr->tablaOperaciones = NULL;
    return (AbstractExpresion *)expr;
}