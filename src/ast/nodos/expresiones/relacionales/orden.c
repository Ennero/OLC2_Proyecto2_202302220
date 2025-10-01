#include "ast/nodos/expresiones/expresiones.h"
#include "ast/nodos/builders.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

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

typedef enum
{
    CMP_MAYOR,
    CMP_MENOR,
    CMP_MAYOR_IGUAL,
    CMP_MENOR_IGUAL
} ComparadorOrden;

static Result interpretarComparacionOrden(AbstractExpresion *self, Context *context, const char *operador, ComparadorOrden comparador)
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

    double valor_izquierda = 0.0;
    double valor_derecha = 0.0;

    if (!convertirResultadoNumerico(&izquierda, &valor_izquierda) || !convertirResultadoNumerico(&derecha, &valor_derecha))
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "El operador relacional '%s' requiere operandos numéricos o booleanos, pero se encontró '%s' y '%s'.", operador, labelTipoDato[izquierda.tipo], labelTipoDato[derecha.tipo]);
        add_error_to_report("Semantico", operador, desc, self->line, self->column, context->nombre_completo);
        liberarResultado(izquierda);
        liberarResultado(derecha);
        return nuevoValorResultadoVacio();
    }

    int bool_result = 0;

    switch (comparador)
    {
    case CMP_MAYOR:
        bool_result = (valor_izquierda > valor_derecha);
        break;
    case CMP_MENOR:
        bool_result = (valor_izquierda < valor_derecha);
        break;
    case CMP_MAYOR_IGUAL:
        bool_result = (valor_izquierda >= valor_derecha);
        break;
    case CMP_MENOR_IGUAL:
        bool_result = (valor_izquierda <= valor_derecha);
        break;
    }

    liberarResultado(izquierda);
    liberarResultado(derecha);

    return crearResultadoBooleano(bool_result);
}

static Result interpretMayorQue(AbstractExpresion *self, Context *context)
{
    return interpretarComparacionOrden(self, context, ">", CMP_MAYOR);
}

static Result interpretMenorQue(AbstractExpresion *self, Context *context)
{
    return interpretarComparacionOrden(self, context, "<", CMP_MENOR);
}

static Result interpretMayorIgual(AbstractExpresion *self, Context *context)
{
    return interpretarComparacionOrden(self, context, ">=", CMP_MAYOR_IGUAL);
}

static Result interpretMenorIgual(AbstractExpresion *self, Context *context)
{
    return interpretarComparacionOrden(self, context, "<=", CMP_MENOR_IGUAL);
}

// Constructores de Nodos ------
AbstractExpresion *nuevoMayorQueExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretMayorQue, i, d, line, column);
    expr->base.node_type = "MayorQue";
    expr->tablaOperaciones = NULL;
    return (AbstractExpresion *)expr;
}

AbstractExpresion *nuevoMenorQueExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretMenorQue, i, d, line, column);
    expr->base.node_type = "MenorQue";
    expr->tablaOperaciones = NULL;
    return (AbstractExpresion *)expr;
}

AbstractExpresion *nuevoMayorIgualExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretMayorIgual, i, d, line, column);
    expr->base.node_type = "MayorIgual";
    expr->tablaOperaciones = NULL;
    return (AbstractExpresion *)expr;
}

AbstractExpresion *nuevoMenorIgualExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretMenorIgual, i, d, line, column);
    expr->base.node_type = "MenorIgual";
    expr->tablaOperaciones = NULL;
    return (AbstractExpresion *)expr;
}