#include "aritmeticas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include "compilacion/generador_codigo.h"
#include <stdlib.h>

// Funciones de Resta Numérica -----------------
Result restarIntInt(ExpresionLenguaje *self)
{
    int *res = malloc(sizeof(int));
    *res = *((int *)self->izquierda.valor) - *((int *)self->derecha.valor);
    return nuevoValorResultado(res, INT);
}
Result restarFloatFloat(ExpresionLenguaje *self)
{
    float *res = malloc(sizeof(float));
    *res = *((float *)self->izquierda.valor) - *((float *)self->derecha.valor);
    return nuevoValorResultado(res, FLOAT);
}
Result restarDoubleDouble(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((double *)self->izquierda.valor) - *((double *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result restarIntFloat(ExpresionLenguaje *self)
{
    float *res = malloc(sizeof(float));
    *res = *((int *)self->izquierda.valor) - *((float *)self->derecha.valor);
    return nuevoValorResultado(res, FLOAT);
}
Result restarFloatInt(ExpresionLenguaje *self)
{
    float *res = malloc(sizeof(float));
    *res = *((float *)self->izquierda.valor) - *((int *)self->derecha.valor);
    return nuevoValorResultado(res, FLOAT);
}
Result restarIntDouble(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((int *)self->izquierda.valor) - *((double *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result restarDoubleInt(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((double *)self->izquierda.valor) - *((int *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result restarFloatDouble(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((float *)self->izquierda.valor) - *((double *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result restarDoubleFloat(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((double *)self->izquierda.valor) - *((float *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}

// Tabla de Operaciones
Operacion tablaOperacionesResta[TIPO_COUNT][TIPO_COUNT] = {
    [INT][INT] = restarIntInt,
    [FLOAT][FLOAT] = restarFloatFloat,
    [DOUBLE][DOUBLE] = restarDoubleDouble,
    [INT][FLOAT] = restarIntFloat,
    [FLOAT][INT] = restarFloatInt,
    [INT][DOUBLE] = restarIntDouble,
    [DOUBLE][INT] = restarDoubleInt,
    [FLOAT][DOUBLE] = restarFloatDouble,
    [DOUBLE][FLOAT] = restarDoubleFloat,

    [CHAR][CHAR] = restarIntInt,
    [CHAR][INT] = restarIntInt,
    [INT][CHAR] = restarIntInt,
    [CHAR][FLOAT] = restarFloatInt,
    [FLOAT][CHAR] = restarFloatInt,
    [CHAR][DOUBLE] = restarDoubleInt,
    [DOUBLE][CHAR] = restarDoubleInt};

static const char *generarRestaExpresion(AbstractExpresion *self, GeneradorCodigo *generador, Context *context)
{
    if (!self || !generador)
        return NULL;

    if (!expresion_es_constante_aritmetica(self))
        return NULL;

    Result resultado = interpretExpresionLenguaje(self, context);
    return registrar_literal_desde_resultado(generador, &resultado);
}

// Constructor del Nodo
AbstractExpresion *nuevoRestaExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column)
{
    ExpresionLenguaje *restaExpresion = nuevoExpresionLenguaje(interpretExpresionLenguaje, izquierda, derecha, line, column);
    restaExpresion->base.node_type = "Resta";
    restaExpresion->tablaOperaciones = &tablaOperacionesResta;
    restaExpresion->base.generar = generarRestaExpresion;
    return (AbstractExpresion *)restaExpresion;
}