#include "aritmeticas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "utils/java_num_format.h"
#include "context/array_value.h"

// Funciones de Suma Numérica -----------------
Result sumarIntInt(ExpresionLenguaje *self)
{
    int *res = malloc(sizeof(int));
    *res = *((int *)self->izquierda.valor) + *((int *)self->derecha.valor);
    return nuevoValorResultado(res, INT);
}
Result sumarFloatFloat(ExpresionLenguaje *self)
{
    float *res = malloc(sizeof(float));
    *res = *((float *)self->izquierda.valor) + *((float *)self->derecha.valor);
    return nuevoValorResultado(res, FLOAT);
}
Result sumarDoubleDouble(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((double *)self->izquierda.valor) + *((double *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result sumarIntFloat(ExpresionLenguaje *self)
{
    float *res = malloc(sizeof(float));
    *res = (float)(*((int *)self->izquierda.valor)) + *((float *)self->derecha.valor);
    return nuevoValorResultado(res, FLOAT);
}
Result sumarFloatInt(ExpresionLenguaje *self)
{
    float *res = malloc(sizeof(float));
    *res = *((float *)self->izquierda.valor) + (float)(*((int *)self->derecha.valor));
    return nuevoValorResultado(res, FLOAT);
}
Result sumarIntDouble(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = (double)(*((int *)self->izquierda.valor)) + *((double *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result sumarDoubleInt(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((double *)self->izquierda.valor) + (double)(*((int *)self->derecha.valor));
    return nuevoValorResultado(res, DOUBLE);
}
Result sumarFloatDouble(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = (double)(*((float *)self->izquierda.valor)) + *((double *)self->derecha.valor);
    return nuevoValorResultado(res, DOUBLE);
}
Result sumarDoubleFloat(ExpresionLenguaje *self)
{
    double *res = malloc(sizeof(double));
    *res = *((double *)self->izquierda.valor) + (double)(*((float *)self->derecha.valor));
    return nuevoValorResultado(res, DOUBLE);
}

// FUNCIONES DE CONCATENACIÓN
Result concatenarStringString(ExpresionLenguaje *self)
{
    const char *s1 = (const char *)self->izquierda.valor;
    const char *s2 = (const char *)self->derecha.valor;
    if (!s1)
        s1 = "null";
    if (!s2)
        s2 = "null";
    char *res = malloc(strlen(s1) + strlen(s2) + 1);
    strcpy(res, s1);
    strcat(res, s2);
    return nuevoValorResultado(res, STRING);
}
Result concatenarStringInt(ExpresionLenguaje *self)
{
    char s2_buffer[64];
    sprintf(s2_buffer, "%d", *(int *)self->derecha.valor);
    const char *s1 = (const char *)self->izquierda.valor;
    if (!s1)
        s1 = "null";
    char *res = malloc(strlen(s1) + strlen(s2_buffer) + 1);
    strcpy(res, s1);
    strcat(res, s2_buffer);
    return nuevoValorResultado(res, STRING);
}
Result concatenarStringDouble(ExpresionLenguaje *self)
{
    char s2_buffer[64];

    // Java-like Double.toString
    java_format_double(*(double *)self->derecha.valor, s2_buffer, sizeof(s2_buffer));
    const char *s1 = (const char *)self->izquierda.valor;
    if (!s1)
        s1 = "null";
    char *res = malloc(strlen(s1) + strlen(s2_buffer) + 1);
    strcpy(res, s1);
    strcat(res, s2_buffer);
    return nuevoValorResultado(res, STRING);
}
Result concatenarStringFloat(ExpresionLenguaje *self)
{
    char s2_buffer[64];

    // Parecido a como es en java
    java_format_float(*(float *)self->derecha.valor, s2_buffer, sizeof(s2_buffer));
    const char *s1 = (const char *)self->izquierda.valor;
    if (!s1)
        s1 = "null";
    char *res = malloc(strlen(s1) + strlen(s2_buffer) + 1);
    strcpy(res, s1);
    strcat(res, s2_buffer);
    return nuevoValorResultado(res, STRING);
}
Result concatenarStringChar(ExpresionLenguaje *self)
{
    const char *s1 = (const char *)self->izquierda.valor;
    if (!s1)
        s1 = "null";
    char c2 = (char)(*(int *)self->derecha.valor);
    char *res = malloc(strlen(s1) + 2);
    sprintf(res, "%s%c", s1, c2);
    return nuevoValorResultado(res, STRING);
}
Result concatenarStringBoolean(ExpresionLenguaje *self)
{

    // Para debuguear ---
#ifdef DEBUG_PRINT
    printf("DEBUG [suma]: La función de concatenar String+Boolean recibió:\n");
    printf("DEBUG [suma]: Lado Izquierdo (String): '%s'\n", (char *)self->izquierda.valor);
    if (self->derecha.valor)
    {
        printf("DEBUG [suma]: Lado Derecho (Boolean): %s\n", (*(int *)self->derecha.valor) ? "true" : "false");
    }
    else
    {
        printf("DEBUG [suma]: Lado Derecho (Boolean): NULL\n");
    }
#endif
    // Para debuguear ---

    const char *s1 = (const char *)self->izquierda.valor;
    if (!s1)
        s1 = "null";
    const char *s2_texto = (*(int *)self->derecha.valor) ? "true" : "false";
    char *res = malloc(strlen(s1) + strlen(s2_texto) + 1);
    strcpy(res, s1);
    strcat(res, s2_texto);
    return nuevoValorResultado(res, STRING);
}
Result concatenarIntString(ExpresionLenguaje *self)
{
    char s1_buffer[64];
    sprintf(s1_buffer, "%d", *(int *)self->izquierda.valor);
    const char *s2 = (const char *)self->derecha.valor;
    if (!s2)
        s2 = "null";
    char *res = malloc(strlen(s1_buffer) + strlen(s2) + 1);
    strcpy(res, s1_buffer);
    strcat(res, s2);
    return nuevoValorResultado(res, STRING);
}
Result concatenarDoubleString(ExpresionLenguaje *self)
{
    char s1_buffer[64];

    // Java-like Double.toString
    java_format_double(*(double *)self->izquierda.valor, s1_buffer, sizeof(s1_buffer));
    const char *s2 = (const char *)self->derecha.valor;
    if (!s2)
        s2 = "null";
    char *res = malloc(strlen(s1_buffer) + strlen(s2) + 1);
    strcpy(res, s1_buffer);
    strcat(res, s2);
    return nuevoValorResultado(res, STRING);
}
Result concatenarFloatString(ExpresionLenguaje *self)
{
    char s1_buffer[64];

    // Java-like Float.toString
    java_format_float(*(float *)self->izquierda.valor, s1_buffer, sizeof(s1_buffer));
    const char *s2 = (const char *)self->derecha.valor;
    if (!s2)
        s2 = "null";
    char *res = malloc(strlen(s1_buffer) + strlen(s2) + 1);
    strcpy(res, s1_buffer);
    strcat(res, s2);
    return nuevoValorResultado(res, STRING);
}
Result concatenarCharString(ExpresionLenguaje *self)
{
    const char *s2 = (const char *)self->derecha.valor;
    if (!s2)
        s2 = "null";
    char c1 = (char)(*(int *)self->izquierda.valor);
    char *res = malloc(strlen(s2) + 2);
    sprintf(res, "%c%s", c1, s2);
    return nuevoValorResultado(res, STRING);
}
Result concatenarBooleanString(ExpresionLenguaje *self)
{
    const char *s1_texto = (*(int *)self->izquierda.valor) ? "true" : "false";
    const char *s2 = (const char *)self->derecha.valor;
    if (!s2)
        s2 = "null";
    char *res = malloc(strlen(s1_texto) + strlen(s2) + 1);
    strcpy(res, s1_texto);
    strcat(res, s2);
    return nuevoValorResultado(res, STRING);
}

// String + Array
Result concatenarStringArray(ExpresionLenguaje *self)
{
    const char *s1 = (const char *)self->izquierda.valor;
    if (!s1)
        s1 = "null";
    ArrayValue *av = (ArrayValue *)self->derecha.valor;
    char arrbuf[96];
    if (!av)
    {
        snprintf(arrbuf, sizeof(arrbuf), "null");
    }
    else
    {
        snprintf(arrbuf, sizeof(arrbuf), "[array %s,%dD]", labelTipoDato[av->tipo_elemento_base], av->dimensiones_total);
    }
    char *res = malloc(strlen(s1) + strlen(arrbuf) + 1);
    strcpy(res, s1);
    strcat(res, arrbuf);
    return nuevoValorResultado(res, STRING);
}

// Array + String
Result concatenarArrayString(ExpresionLenguaje *self)
{
    ArrayValue *av = (ArrayValue *)self->izquierda.valor;
    const char *s2 = (const char *)self->derecha.valor;
    if (!s2)
        s2 = "null";
    char arrbuf[96];
    if (!av)
    {
        snprintf(arrbuf, sizeof(arrbuf), "null");
    }
    else
    {
        snprintf(arrbuf, sizeof(arrbuf), "[array %s,%dD]", labelTipoDato[av->tipo_elemento_base], av->dimensiones_total);
    }
    char *res = malloc(strlen(arrbuf) + strlen(s2) + 1);
    strcpy(res, arrbuf);
    strcat(res, s2);
    return nuevoValorResultado(res, STRING);
}

// TABLA DE OPERACIONES DE SUMA
Operacion tablaOperacionesSuma[TIPO_COUNT][TIPO_COUNT] = {
    [BOOLEAN] = {[STRING] = concatenarBooleanString},
    [CHAR] = {[CHAR] = sumarIntInt, [INT] = sumarIntInt, [FLOAT] = sumarFloatInt, [DOUBLE] = sumarDoubleInt, [STRING] = concatenarCharString},
    [INT] = {[CHAR] = sumarIntInt, [INT] = sumarIntInt, [FLOAT] = sumarIntFloat, [DOUBLE] = sumarIntDouble, [STRING] = concatenarIntString},
    [FLOAT] = {[CHAR] = sumarFloatInt, [INT] = sumarFloatInt, [FLOAT] = sumarFloatFloat, [DOUBLE] = sumarFloatDouble, [STRING] = concatenarFloatString},
    [DOUBLE] = {[CHAR] = sumarDoubleInt, [INT] = sumarDoubleInt, [FLOAT] = sumarDoubleFloat, [DOUBLE] = sumarDoubleDouble, [STRING] = concatenarDoubleString},
    [STRING] = {[BOOLEAN] = concatenarStringBoolean, [CHAR] = concatenarStringChar, [INT] = concatenarStringInt, [FLOAT] = concatenarStringFloat, [DOUBLE] = concatenarStringDouble, [STRING] = concatenarStringString, [ARRAY] = concatenarStringArray},
    [ARRAY] = {[STRING] = concatenarArrayString}};

// Constructor
AbstractExpresion *nuevoSumaExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column)
{
    ExpresionLenguaje *sumaExpresion = nuevoExpresionLenguaje(interpretExpresionLenguaje, izquierda, derecha, line, column);
    sumaExpresion->base.node_type = "Suma";
    sumaExpresion->tablaOperaciones = &tablaOperacionesSuma;
    return (AbstractExpresion *)sumaExpresion;
}