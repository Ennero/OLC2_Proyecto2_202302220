#include "result.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

// Etiquetas para los tipos de datos
char *labelTipoDato[TIPO_COUNT] = {
    [BOOLEAN] = "boolean",
    [CHAR] = "char",
    [INT] = "int",
    [FLOAT] = "float",
    [DOUBLE] = "double",
    [STRING] = "string",
    [ARRAY] = "array",
    [BREAK_T] = "<break>",
    [CONTINUE_T] = "<continue>",
    [RETURN_T] = "<return>",
    [NULO] = "null"};

// Crear un nuevo valor de resultado
Result nuevoValorResultado(void *valor, TipoDato tipo)
{
    Result resultado;
    resultado.tipo = tipo;
    resultado.valor = valor;
    return resultado;
}

// Crear un nuevo valor de resultado vacío
Result nuevoValorResultadoVacio()
{
    Result resultado;
    resultado.tipo = NULO;
    resultado.valor = NULL;
    return resultado;
}

// Determinar el tipo resultante de dos valores
TipoDato tipoResultante(Result valor1, Result valor2)
{
    // Si alguno es NULO, el resultado es NULO
    if (valor1.tipo >= valor2.tipo)
    {
        return valor1.tipo;
    }
    else
    {
        return valor2.tipo;
    }
}

// REGLAS DE WIDENING
int can_widen(TipoDato from, TipoDato to)
{
    if (from == to)
        return 1;

    // No se permite widening hacia/desde STRING, ARRAY
    if (from == STRING || to == STRING || from == ARRAY || to == ARRAY ||
        from == BREAK_T || from == CONTINUE_T || from == RETURN_T ||
        to == BREAK_T || to == CONTINUE_T || to == RETURN_T ||
        from == NULO)
        return 0;

    // boolean no se convierte implícitamente a numérico
    if (from == BOOLEAN || to == BOOLEAN)
        return 0;

    // char e int comparten almacenamiento (int)
    if (from == CHAR && to == INT)
        return 1;

    // Cadena de widening numérico
    if ((from == INT || from == CHAR) && (to == FLOAT || to == DOUBLE))
        return 1;
    if (from == FLOAT && to == DOUBLE)
        return 1;
    if (from == INT && to == DOUBLE)
        return 1;

    return 0;
}

static size_t get_primitive_size(TipoDato tipo)
{
    switch (tipo)
    {
    case INT:
    case CHAR:
        return sizeof(int);
    case FLOAT:
        return sizeof(float);
    case DOUBLE:
        return sizeof(double);
    default:
        return 0;
    }
}

Result widen_to(Result src, TipoDato to)
{
    if (src.tipo == to)
        return src;

    if (!can_widen(src.tipo, to))
        return src; // no-op si no es permitido

    // Extraer como double para precisión, luego asignar
    double val = 0.0;
    switch (src.tipo)
    {
    case INT:
    case CHAR:
        val = (double)(*(int *)src.valor);
        break;
    case FLOAT:
        val = (double)(*(float *)src.valor);
        break;
    case DOUBLE:
        val = *(double *)src.valor;
        break;
    default:
        return src;
    }

    // Crear el nuevo contenedor
    void *nuevo = NULL;
    switch (to)
    {
    case INT:
    case CHAR:
    {
        int *p = malloc(sizeof(int));
        *p = (int)val;
        nuevo = p;
        break;
    }
    case FLOAT:
    {
        float *p = malloc(sizeof(float));
        *p = (float)val;
        nuevo = p;
        break;
    }
    case DOUBLE:
    {
        double *p = malloc(sizeof(double));
        *p = (double)val;
        nuevo = p;
        break;
    }
    default:
        return src;
    }

    // Liberar el valor anterior si existía y era primitivo
    size_t old_size = get_primitive_size(src.tipo);
    if (old_size > 0 && src.valor)
    {
        free(src.valor);
    }

    return nuevoValorResultado(nuevo, to);
}