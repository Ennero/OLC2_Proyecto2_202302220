#include "ast/nodos/expresiones/expresiones.h"
#include "ast/nodos/builders.h"
#include "context/result.h"
#include <stdlib.h>

// Función genérica para comparar orden (>, <, >=, <=)
static Result compararOrden(ExpresionLenguaje *self, int op_type)
{
    int *res = malloc(sizeof(int));

    // Se compara con double para evitar duplicar código
    double v1 = 0.0;
    double v2 = 0.0;

    // Obtener valores numéricos
    switch (self->izquierda.tipo)
    {
    case INT:
        v1 = (double)(*(int *)self->izquierda.valor);
        break;
    case CHAR:
        v1 = (double)(*(int *)self->izquierda.valor);
        break;
    case FLOAT:
        v1 = (double)(*(float *)self->izquierda.valor);
        break;
    case DOUBLE:
        v1 = *((double *)self->izquierda.valor);
        break;
    default:
        v1 = 0.0;
        break;
    }

    // Obtener valores numéricos
    switch (self->derecha.tipo)
    {
    case INT:
        v2 = (double)(*(int *)self->derecha.valor);
        break;
    case CHAR:
        v2 = (double)(*(int *)self->derecha.valor);
        break;
    case FLOAT:
        v2 = (double)(*(float *)self->derecha.valor);
        break;
    case DOUBLE:
        v2 = *((double *)self->derecha.valor);
        break;
    default:
        v2 = 0.0;
        break;
    }

    // Realizar la comparación según el tipo de operación
    switch (op_type)
    {
    case 0:
        *res = (v1 > v2);
        break; // Mayor que
    case 1:
        *res = (v1 < v2);
        break; // Menor que
    case 2:
        *res = (v1 >= v2);
        break; // Mayor o igual
    case 3:
        *res = (v1 <= v2);
        break; // Menor o igual
    }
    return nuevoValorResultado(res, BOOLEAN);
}

// Wrappers para cada operador
static Result compararMayorQue(ExpresionLenguaje *self) { return compararOrden(self, 0); }
static Result compararMenorQue(ExpresionLenguaje *self) { return compararOrden(self, 1); }
static Result compararMayorIgual(ExpresionLenguaje *self) { return compararOrden(self, 2); }
static Result compararMenorIgual(ExpresionLenguaje *self) { return compararOrden(self, 3); }

// Tablas de operaciones
Operacion tablaOperacionesMayorQue[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = compararMayorQue, [DOUBLE] = compararMayorQue, [CHAR] = compararMayorQue, [FLOAT] = compararMayorQue},
    [DOUBLE] = {[INT] = compararMayorQue, [DOUBLE] = compararMayorQue, [CHAR] = compararMayorQue, [FLOAT] = compararMayorQue},
    [CHAR] = {[INT] = compararMayorQue, [DOUBLE] = compararMayorQue, [CHAR] = compararMayorQue, [FLOAT] = compararMayorQue},
    [FLOAT] = {[INT] = compararMayorQue, [DOUBLE] = compararMayorQue, [CHAR] = compararMayorQue, [FLOAT] = compararMayorQue}};
Operacion tablaOperacionesMenorQue[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = compararMenorQue, [DOUBLE] = compararMenorQue, [CHAR] = compararMenorQue, [FLOAT] = compararMenorQue},
    [DOUBLE] = {[INT] = compararMenorQue, [DOUBLE] = compararMenorQue, [CHAR] = compararMenorQue, [FLOAT] = compararMenorQue},
    [CHAR] = {[INT] = compararMenorQue, [DOUBLE] = compararMenorQue, [CHAR] = compararMenorQue, [FLOAT] = compararMenorQue},
    [FLOAT] = {[INT] = compararMenorQue, [DOUBLE] = compararMenorQue, [CHAR] = compararMenorQue, [FLOAT] = compararMenorQue}};
Operacion tablaOperacionesMayorIgual[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = compararMayorIgual, [DOUBLE] = compararMayorIgual, [CHAR] = compararMayorIgual, [FLOAT] = compararMayorIgual},
    [DOUBLE] = {[INT] = compararMayorIgual, [DOUBLE] = compararMayorIgual, [CHAR] = compararMayorIgual, [FLOAT] = compararMayorIgual},
    [CHAR] = {[INT] = compararMayorIgual, [DOUBLE] = compararMayorIgual, [CHAR] = compararMayorIgual, [FLOAT] = compararMayorIgual},
    [FLOAT] = {[INT] = compararMayorIgual, [DOUBLE] = compararMayorIgual, [CHAR] = compararMayorIgual, [FLOAT] = compararMayorIgual}};
Operacion tablaOperacionesMenorIgual[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = compararMenorIgual, [DOUBLE] = compararMenorIgual, [CHAR] = compararMenorIgual, [FLOAT] = compararMenorIgual},
    [DOUBLE] = {[INT] = compararMenorIgual, [DOUBLE] = compararMenorIgual, [CHAR] = compararMenorIgual, [FLOAT] = compararMenorIgual},
    [CHAR] = {[INT] = compararMenorIgual, [DOUBLE] = compararMenorIgual, [CHAR] = compararMenorIgual, [FLOAT] = compararMenorIgual},
    [FLOAT] = {[INT] = compararMenorIgual, [DOUBLE] = compararMenorIgual, [CHAR] = compararMenorIgual, [FLOAT] = compararMenorIgual}};

// Constructores de Nodos ------
AbstractExpresion *nuevoMayorQueExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "MayorQue";
    expr->tablaOperaciones = &tablaOperacionesMayorQue;
    return (AbstractExpresion *)expr;
}
AbstractExpresion *nuevoMenorQueExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "MenorQue";
    expr->tablaOperaciones = &tablaOperacionesMenorQue;
    return (AbstractExpresion *)expr;
}
AbstractExpresion *nuevoMayorIgualExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "MayorIgual";
    expr->tablaOperaciones = &tablaOperacionesMayorIgual;
    return (AbstractExpresion *)expr;
}
AbstractExpresion *nuevoMenorIgualExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "MenorIgual";
    expr->tablaOperaciones = &tablaOperacionesMenorIgual;
    return (AbstractExpresion *)expr;
}