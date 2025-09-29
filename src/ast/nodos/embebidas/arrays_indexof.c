#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/array_value.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <string.h>

// Función auxiliar para comparar dos valores de tipo Result
static int arrays_deep_equals(ArrayValue *a, ArrayValue *b)
{
    // Mismo puntero o ambos nulos
    if (a == b)
        return 1;
    if (!a || !b)
        return 0;
    if (a->tipo_elemento_base != b->tipo_elemento_base || a->dimensiones_total != b->dimensiones_total || a->tamano != b->tamano)
        return 0;

    // Comparar elemento por elemento
    for (int i = 0; i < a->tamano; i++)
    {
        Result va = a->valores[i];
        Result vb = b->valores[i];

        // Mismo tipo
        if (va.tipo != vb.tipo)
            return 0;

        // Comparar según el tipo
        if (va.tipo == ARRAY)
        {
            ArrayValue *sa = (ArrayValue *)va.valor;
            ArrayValue *sb = (ArrayValue *)vb.valor;
            if (!arrays_deep_equals(sa, sb))
                return 0;
        }

        // Tipos primitivos y String
        else
        {
            if (va.valor == NULL || vb.valor == NULL)
            {
                if (va.valor != vb.valor)
                    return 0;
            }
            else
            {
                // Comparar según el tipo
                switch (va.tipo)
                {
                case INT:
                case BOOLEAN:
                case CHAR:
                    if (*(int *)va.valor != *(int *)vb.valor)
                    {
                        return 0;
                    }
                    break;
                case FLOAT:
                    if (*(float *)va.valor != *(float *)vb.valor)
                    {
                        return 0;
                    }
                    break;
                case DOUBLE:
                    if (*(double *)va.valor != *(double *)vb.valor)
                    {
                        return 0;
                    }
                    break;
                case STRING:
                    if (strcmp((char *)va.valor, (char *)vb.valor) != 0)
                    {
                        return 0;
                    }
                    break;
                default:
                    return 0;
                }
            }
        }
    }
    return 1;
}

// Compara dos Result y devuelve 1 si son iguales, 0 si no
static int sonValoresIguales(Result r1, Result r2)
{
    // Mismo tipo
    if (r1.tipo != r2.tipo)
        return 0;
    // Ambos nulos o mismo puntero
    if (r1.valor == NULL || r2.valor == NULL)
        return r1.valor == r2.valor;

    // Comparar según el tipo
    switch (r1.tipo)
    {
    case INT:
    case BOOLEAN:
    case CHAR:
        return *(int *)r1.valor == *(int *)r2.valor;
    case FLOAT:
        return *(float *)r1.valor == *(float *)r2.valor;
    case DOUBLE:
        return *(double *)r1.valor == *(double *)r2.valor;
    case STRING:
        return strcmp((char *)r1.valor, (char *)r2.valor) == 0;
    case ARRAY:
        return arrays_deep_equals((ArrayValue *)r1.valor, (ArrayValue *)r2.valor);
    default:
        return 0;
    }
}

// Implementa Arrays.indexOf(arr, val)
Result interpretArraysIndexof(AbstractExpresion *self, Context *context)
{
    Result arr_res = self->hijos[0]->interpret(self->hijos[0], context);
    Result val_res = self->hijos[1]->interpret(self->hijos[1], context);

    // Validar que el primer argumento sea un arreglo
    if (arr_res.tipo != ARRAY)
    {
        add_error_to_report("Semantico", "Arrays.indexOf", "El primer argumento debe ser un arreglo.", self->line, self->column, context->nombre_completo);
        free(arr_res.valor);
        free(val_res.valor);
        return nuevoValorResultadoVacio();
    }

    // Buscar el valor en el arreglo
    ArrayValue *arr = (ArrayValue *)arr_res.valor;
    int *indice_encontrado = malloc(sizeof(int));
    *indice_encontrado = -1; // Valor por defecto si no se encuentra

    // Recorrer el arreglo y comparar cada elemento con val_res
    for (int i = 0; i < arr->tamano; i++)
    {
        if (sonValoresIguales(arr->valores[i], val_res))
        {
            *indice_encontrado = i;
            break; // Terminar la búsqueda al encontrar la primera coincidencia
        }
    }

    // No liberar 'arr'
    if (val_res.tipo != ARRAY)
    {
        free(val_res.valor);
    }

    return nuevoValorResultado(indice_encontrado, INT);
}

// Constructor para nodo de Arrays.indexOf
AbstractExpresion *nuevoArraysIndexofExpresion(AbstractExpresion *arr_expr, AbstractExpresion *val_expr, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretArraysIndexof, "ArraysIndexof", line, column);
    agregarHijo(nodo, arr_expr);
    agregarHijo(nodo, val_expr);
    return nodo;
}