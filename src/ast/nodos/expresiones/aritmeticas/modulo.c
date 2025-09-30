#include "aritmeticas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <math.h>
#include "compilacion/generador_codigo.h"

// Funciones de Módulo Numérico -----------------
Result moduloIntInt(ExpresionLenguaje *self)
{
    int divisor = *((int *)self->derecha.valor);
    if (divisor == 0)
    {
        add_error_to_report("Semántico", "%", "Módulo por cero.", self->base.line, self->base.column, NULL);
        return nuevoValorResultadoVacio();
    }
    int *res = malloc(sizeof(int));
    *res = *((int *)self->izquierda.valor) % divisor;
    return nuevoValorResultado(res, INT);
}
Result moduloFloatFloat(ExpresionLenguaje *self)
{
    float divisor = *((float *)self->derecha.valor);
    if (divisor == 0.0f)
    {
        add_error_to_report("Semántico", "%", "Módulo por cero.", self->base.line, self->base.column, NULL);
        return nuevoValorResultadoVacio();
    }
    float *res = malloc(sizeof(float));
    *res = fmodf(*((float *)self->izquierda.valor), divisor);
    return nuevoValorResultado(res, FLOAT);
}
Result moduloDoubleDouble(ExpresionLenguaje *self)
{
    double divisor = *((double *)self->derecha.valor);
    if (divisor == 0.0)
    {
        add_error_to_report("Semántico", "%", "Módulo por cero.", self->base.line, self->base.column, NULL);
        return nuevoValorResultadoVacio();
    }
    double *res = malloc(sizeof(double));
    *res = fmod(*((double *)self->izquierda.valor), divisor);
    return nuevoValorResultado(res, DOUBLE);
}
Result moduloIntFloat(ExpresionLenguaje *self)
{
    float divisor = *((float *)self->derecha.valor);
    if (divisor == 0.0f)
    {
        add_error_to_report("Semántico", "%", "Módulo por cero.", self->base.line, self->base.column, NULL);
        return nuevoValorResultadoVacio();
    }
    float *res = malloc(sizeof(float));
    *res = fmodf((float)(*((int *)self->izquierda.valor)), divisor);
    return nuevoValorResultado(res, FLOAT);
}
Result moduloFloatInt(ExpresionLenguaje *self)
{
    int divisor = *((int *)self->derecha.valor);
    if (divisor == 0)
    {
        add_error_to_report("Semántico", "%", "Módulo por cero.", self->base.line, self->base.column, NULL);
        return nuevoValorResultadoVacio();
    }
    float *res = malloc(sizeof(float));
    *res = fmodf(*((float *)self->izquierda.valor), (float)divisor);
    return nuevoValorResultado(res, FLOAT);
}
Result moduloIntDouble(ExpresionLenguaje *self)
{
    double divisor = *((double *)self->derecha.valor);
    if (divisor == 0.0)
    {
        add_error_to_report("Semántico", "%", "Módulo por cero.", self->base.line, self->base.column, NULL);
        return nuevoValorResultadoVacio();
    }
    double *res = malloc(sizeof(double));
    *res = fmod((double)(*((int *)self->izquierda.valor)), divisor);
    return nuevoValorResultado(res, DOUBLE);
}
Result moduloDoubleInt(ExpresionLenguaje *self)
{
    int divisor = *((int *)self->derecha.valor);
    if (divisor == 0)
    {
        add_error_to_report("Semántico", "%", "Módulo por cero.", self->base.line, self->base.column, NULL);
        return nuevoValorResultadoVacio();
    }
    double *res = malloc(sizeof(double));
    *res = fmod(*((double *)self->izquierda.valor), (double)divisor);
    return nuevoValorResultado(res, DOUBLE);
}
Result moduloFloatDouble(ExpresionLenguaje *self)
{
    double divisor = *((double *)self->derecha.valor);
    if (divisor == 0.0)
    {
        add_error_to_report("Semántico", "%", "Módulo por cero.", self->base.line, self->base.column, NULL);
        return nuevoValorResultadoVacio();
    }
    double *res = malloc(sizeof(double));
    *res = fmod((double)(*((float *)self->izquierda.valor)), divisor);
    return nuevoValorResultado(res, DOUBLE);
}
Result moduloDoubleFloat(ExpresionLenguaje *self)
{
    float divisor = *((float *)self->derecha.valor);
    if (divisor == 0.0f)
    {
        add_error_to_report("Semántico", "%", "Módulo por cero.", self->base.line, self->base.column, NULL);
        return nuevoValorResultadoVacio();
    }
    double *res = malloc(sizeof(double));
    *res = fmod(*((double *)self->izquierda.valor), (double)divisor);
    return nuevoValorResultado(res, DOUBLE);
}

// Tabla de Operaciones --------------------------
Operacion tablaOperacionesModulo[TIPO_COUNT][TIPO_COUNT] = {
    [INT][INT] = moduloIntInt,
    [FLOAT][FLOAT] = moduloFloatFloat,
    [DOUBLE][DOUBLE] = moduloDoubleDouble,
    [INT][FLOAT] = moduloIntFloat,
    [FLOAT][INT] = moduloFloatInt,
    [INT][DOUBLE] = moduloIntDouble,
    [DOUBLE][INT] = moduloDoubleInt,
    [FLOAT][DOUBLE] = moduloFloatDouble,
    [DOUBLE][FLOAT] = moduloDoubleFloat,

    [CHAR][CHAR] = moduloIntInt,
    [CHAR][INT] = moduloIntInt,
    [INT][CHAR] = moduloIntInt,
    [CHAR][FLOAT] = moduloFloatInt,
    [FLOAT][CHAR] = moduloFloatInt,
    [CHAR][DOUBLE] = moduloDoubleInt,
    [DOUBLE][CHAR] = moduloDoubleInt};

static const char *generarModuloExpresion(AbstractExpresion *self, GeneradorCodigo *generador, Context *context)
{
    if (!self || !generador)
        return NULL;

    if (!expresion_es_constante_aritmetica(self))
        return NULL;

    Result resultado = interpretExpresionLenguaje(self, context);
    return registrar_literal_desde_resultado(generador, &resultado);
}

// Constructor del Nodo
AbstractExpresion *nuevoModuloExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, izquierda, derecha, line, column);
    expr->base.node_type = "Modulo";
    expr->tablaOperaciones = &tablaOperacionesModulo;
    expr->base.generar = generarModuloExpresion;
    return (AbstractExpresion *)expr;
}