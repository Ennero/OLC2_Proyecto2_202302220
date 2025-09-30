#include "logicas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

static Result nuevoResultadoBooleano(int valor)
{
    int *res = malloc(sizeof(int));
    if (!res)
        return nuevoValorResultadoVacio();

    *res = valor ? 1 : 0;
    return nuevoValorResultado(res, BOOLEAN);
}

// Interpretador para el Nodo NOT
Result interpretNotExpresion(AbstractExpresion *self, Context *context)
{
    // Interpretar la expresión hija
    Result res = self->hijos[0]->interpret(self->hijos[0], context);

    if (has_semantic_error_been_found())
    {
        if (res.tipo != ARRAY)
            free(res.valor);
        return nuevoValorResultadoVacio();
    }

    int valor_bool = 0;
    if (!convertirResultadoLogico(&res, &valor_bool))
    {
        char desc[256];
        sprintf(desc, "El operador unario '!' no se puede aplicar a un valor de tipo '%s'.", labelTipoDato[res.tipo]);
        add_error_to_report("Semantico", "!", desc, self->line, self->column, context->nombre_completo);
        if (res.tipo != ARRAY)
            free(res.valor);
        return nuevoValorResultadoVacio();
    }

    if (res.tipo != ARRAY)
        free(res.valor);

    return nuevoResultadoBooleano(!valor_bool);
}

// Constructor del Nodo
AbstractExpresion *nuevoNotExpresion(AbstractExpresion *expresion, int line, int column)
{
    AbstractExpresion *notExpresion = malloc(sizeof(AbstractExpresion));
    if (!notExpresion)
        return NULL;

    buildAbstractExpresion(notExpresion, interpretNotExpresion, "Not", line, column);
    agregarHijo(notExpresion, expresion);

    return notExpresion;
}