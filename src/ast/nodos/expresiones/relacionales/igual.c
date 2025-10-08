#include "ast/nodos/expresiones/expresiones.h"
#include "ast/nodos/builders.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static Result crearResultadoBooleano(int valor)
{
    int *res = malloc(sizeof(int));
    if (!res)
        return nuevoValorResultadoVacio();

    *res = valor ? 1 : 0;
    return nuevoValorResultado(res, BOOLEAN);
}

static bool convertirResultadoNumerico(const Result *res, double *out)
{
    if (!res || !out)
        return false;

    switch (res->tipo)
    {
    case BOOLEAN:
        if (!res->valor)
        {
            *out = 0.0;
            return true;
        }
        *out = (*((int *)res->valor) != 0) ? 1.0 : 0.0;
        return true;
    case INT:
    case CHAR:
        if (!res->valor)
        {
            *out = 0.0;
            return true;
        }
        *out = (double)(*((int *)res->valor));
        return true;
    case FLOAT:
        if (!res->valor)
        {
            *out = 0.0;
            return true;
        }
        *out = (double)(*((float *)res->valor));
        return true;
    case DOUBLE:
        if (!res->valor)
        {
            *out = 0.0;
            return true;
        }
        *out = *((double *)res->valor);
        return true;
    default:
        return false;
    }
}

static inline void liberarResultado(Result resultado)
{
    if (resultado.tipo != ARRAY && resultado.valor)
        free(resultado.valor);
}

static Result interpretarComparacionIgualComun(AbstractExpresion *self, Context *context, const char *operador, int negar)
{
    Result izquierda = self->hijos[0]->interpret(self->hijos[0], context);
    if (has_semantic_error_been_found())
    {
        liberarResultado(izquierda);
        return nuevoValorResultadoVacio();
    }

    Result derecha = self->hijos[1]->interpret(self->hijos[1], context);
    if (has_semantic_error_been_found())
    {
        liberarResultado(izquierda);
        liberarResultado(derecha);
        return nuevoValorResultadoVacio();
    }

    int bool_result = 0;
    bool handled = false;

    if (izquierda.tipo == ARRAY || derecha.tipo == ARRAY)
    {
        if ((izquierda.tipo == ARRAY && (derecha.tipo == ARRAY || derecha.tipo == NULO)) ||
            (derecha.tipo == ARRAY && izquierda.tipo == NULO))
        {
            handled = true;
            bool_result = (izquierda.valor == derecha.valor);
        }
    }
    else if ((izquierda.tipo == STRING && derecha.tipo == STRING))
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "Para comparar Strings utiliza el método '.equals()' en lugar del operador '%s'.", operador);
        add_error_to_report("Semantico", operador, desc, self->line, self->column, context->nombre_completo);
        liberarResultado(izquierda);
        liberarResultado(derecha);
        return nuevoValorResultadoVacio();
    }
    else if (izquierda.tipo == STRING || derecha.tipo == STRING)
    {
        if (izquierda.tipo == NULO || derecha.tipo == NULO)
        {
            handled = true;
            bool_result = (izquierda.tipo == NULO && derecha.tipo == NULO);
        }
    }
    else if (izquierda.tipo == NULO || derecha.tipo == NULO)
    {
        if (izquierda.tipo == NULO && derecha.tipo == NULO)
        {
            handled = true;
            bool_result = 1;
        }
    }
    else
    {
        double valor_izquierda = 0.0;
        double valor_derecha = 0.0;
        if (convertirResultadoNumerico(&izquierda, &valor_izquierda) && convertirResultadoNumerico(&derecha, &valor_derecha))
        {
            bool_result = (valor_izquierda == valor_derecha);
            handled = true;
        }
    }

    if (!handled)
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "El operador relacional '%s' no se puede aplicar entre '%s' y '%s'.", operador, labelTipoDato[izquierda.tipo], labelTipoDato[derecha.tipo]);
        add_error_to_report("Semantico", operador, desc, self->line, self->column, context->nombre_completo);
        liberarResultado(izquierda);
        liberarResultado(derecha);
        return nuevoValorResultadoVacio();
    }

    if (negar)
        bool_result = !bool_result;

    liberarResultado(izquierda);
    liberarResultado(derecha);

    return crearResultadoBooleano(bool_result);
}

static Result interpretIgualExpresion(AbstractExpresion *self, Context *context)
{
    return interpretarComparacionIgualComun(self, context, "==", 0);
}

static Result interpretDiferenteExpresion(AbstractExpresion *self, Context *context)
{
    return interpretarComparacionIgualComun(self, context, "!=", 1);
}

// Constructores de Nodos ------
AbstractExpresion *nuevoIgualExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretIgualExpresion, i, d, line, column);
    expr->base.node_type = "IgualIgual";
    expr->tablaOperaciones = NULL;
    return (AbstractExpresion *)expr;
}

AbstractExpresion *nuevoDiferenteExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretDiferenteExpresion, i, d, line, column);
    expr->base.node_type = "Diferente";
    expr->tablaOperaciones = NULL;
    return (AbstractExpresion *)expr;
}