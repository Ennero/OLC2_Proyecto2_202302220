#include "aritmeticas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include <stdlib.h>

// Funciones de Multiplicación Numérica -----------------
Result multiplicarIntInt(ExpresionLenguaje *self)
{
    int *res = malloc(sizeof(int));
    *res = *((int *)self->izquierda.valor) * *((int *)self->derecha.valor);
    return nuevoValorResultado(res, INT);
}
Result multiplicarFloatFloat(ExpresionLenguaje *self)
{
    float *res = malloc(sizeof(float));
    *res = *((float *)self->izquierda.valor) * *((float *)self->derecha.valor);
    return nuevoValorResultado(res, FLOAT);
}
Result multiplicarDoubleDouble(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((double *)self->izquierda.valor) * *((double *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result multiplicarIntFloat(ExpresionLenguaje *self)
{
    float *res = malloc(sizeof(float));
    *res = (float)(*((int *)self->izquierda.valor)) * *((float *)self->derecha.valor);
    return nuevoValorResultado(res, FLOAT);
}
Result multiplicarFloatInt(ExpresionLenguaje *self)
{
    float *res = malloc(sizeof(float));
    *res = *((float *)self->izquierda.valor) * (float)(*((int *)self->derecha.valor));
    return nuevoValorResultado(res, FLOAT);
}
Result multiplicarIntDouble(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = (double)(*((int *)self->izquierda.valor)) * *((double *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result multiplicarDoubleInt(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((double *)self->izquierda.valor) * (double)(*((int *)self->derecha.valor));
    return nuevoValorResultado(res, DOUBLE);
}
Result multiplicarFloatDouble(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = (double)(*((float *)self->izquierda.valor)) * *((double *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result multiplicarDoubleFloat(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((double *)self->izquierda.valor) * (double)(*((float *)self->derecha.valor));
    return nuevoValorResultado(res, DOUBLE);
}

// Tabla de Operaciones --------------------------
Operacion tablaOperacionesMultiplicacion[TIPO_COUNT][TIPO_COUNT] = {
    [INT][INT] = multiplicarIntInt,
    [FLOAT][FLOAT] = multiplicarFloatFloat,
    [DOUBLE][DOUBLE] = multiplicarDoubleDouble,
    [INT][FLOAT] = multiplicarIntFloat,
    [FLOAT][INT] = multiplicarFloatInt,
    [INT][DOUBLE] = multiplicarIntDouble,
    [DOUBLE][INT] = multiplicarDoubleInt,
    [FLOAT][DOUBLE] = multiplicarFloatDouble,
    [DOUBLE][FLOAT] = multiplicarDoubleFloat,

    [CHAR][CHAR] = multiplicarIntInt,
    [CHAR][INT] = multiplicarIntInt,
    [INT][CHAR] = multiplicarIntInt,
    [CHAR][FLOAT] = multiplicarFloatInt,
    [FLOAT][CHAR] = multiplicarFloatInt,
    [CHAR][DOUBLE] = multiplicarDoubleInt,
    [DOUBLE][CHAR] = multiplicarDoubleInt};

// Constructor del Nodo
AbstractExpresion *nuevoMultiplicacionExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, izquierda, derecha, line, column);
    expr->base.node_type = "Multiplicacion";
    expr->tablaOperaciones = &tablaOperacionesMultiplicacion;
    return (AbstractExpresion *)expr;
}