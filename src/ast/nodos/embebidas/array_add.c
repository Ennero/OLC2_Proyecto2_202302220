#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/array_value.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <string.h>

// Implementa el método de instancia .add (arreglo.add(valor))
Result interpretArrayAdd(AbstractExpresion *self, Context *context)
{
    // Hijo 0: arreglo, Hijo 1: nuevo elemento
    Result arr_res = self->hijos[0]->interpret(self->hijos[0], context);
    Result elem_res = self->hijos[1]->interpret(self->hijos[1], context);

    // Validar que el primer argumento sea un arreglo
    if (arr_res.tipo != ARRAY)
    {
        add_error_to_report("Semantico", ".add", "El primer argumento debe ser un arreglo.", self->line, self->column, context->nombre_completo);
        free(arr_res.valor);
        free(elem_res.valor);
        return nuevoValorResultadoVacio();
    }

    // Validar compatibilidad de tipos
    ArrayValue *arr_original = (ArrayValue *)arr_res.valor;

    int tipos_compatibles = 0; // Esto será como un booleano

    // Si el elemento a añadir es un arreglo
    if (elem_res.tipo == ARRAY)
    {
        ArrayValue *elem_arr = (ArrayValue *)elem_res.valor;
        // Los tipos base deben ser iguales Y el contenedor debe tener una dimensión más.
        if (arr_original->tipo_elemento_base == elem_arr->tipo_elemento_base &&
            arr_original->dimensiones_total == elem_arr->dimensiones_total + 1)
        {
            tipos_compatibles = 1;
        }
    }
    // Si el elemento a añadir es un primitivo
    else
    {
        // Solo es válido si el contenedor es un arreglo de 1D y los tipos base coinciden.
        if (arr_original->dimensiones_total == 1 &&
            arr_original->tipo_elemento_base == elem_res.tipo)
        {
            tipos_compatibles = 1;
        }
    }

    // Si no son compatibles, reportar error
    if (!tipos_compatibles)
    {
        add_error_to_report("Semantico", ".add", "El tipo del nuevo elemento es incompatible con el tipo del arreglo.", self->line, self->column, context->nombre_completo);
        if (elem_res.tipo != ARRAY)
            free(elem_res.valor); // liberar solo temporales primitivos
        return nuevoValorResultadoVacio();
    }

    // Crear un nuevo arreglo con tamaño +1
    int nuevo_tamano = arr_original->tamano + 1;
    ArrayValue *arr_nuevo = nuevoArray(arr_original->tipo_elemento_base, arr_original->dimensiones_total, nuevo_tamano);

    // Se copian los elementos antiguos
    for (int i = 0; i < arr_original->tamano; i++)
    {
        free(arr_nuevo->valores[i].valor); // Liberar el valor por defecto

        // Se realiza una copia profunda del elemento para evitar compartir punteros.
        if (arr_original->valores[i].tipo == ARRAY)
        {
            arr_nuevo->valores[i] = nuevoValorResultado(copiarArray(arr_original->valores[i].valor), ARRAY);
        }
        else
        {
            // Copia de primitivos
            arr_nuevo->valores[i].tipo = arr_original->valores[i].tipo;

            // Copia según el tipo
            if (arr_original->valores[i].tipo == STRING)
            {
                arr_nuevo->valores[i].valor = strdup((char *)arr_original->valores[i].valor);
            }

            // Primitivos numéricos y booleanos
            else
            {
                size_t size = sizeof(int); // Para INT, CHAR, BOOLEAN
                if (arr_original->valores[i].tipo == FLOAT)
                    size = sizeof(float);
                if (arr_original->valores[i].tipo == DOUBLE)
                    size = sizeof(double);
                arr_nuevo->valores[i].valor = malloc(size);
                memcpy(arr_nuevo->valores[i].valor, arr_original->valores[i].valor, size);
            }
        }
    }

    // Añadir el nuevo elemento al final
    free(arr_nuevo->valores[nuevo_tamano - 1].valor);
    if (elem_res.tipo == ARRAY)
    {
        // Copia profunda para evitar aliasing con variables existentes
        ArrayValue *copia = copiarArray((ArrayValue *)elem_res.valor);
        arr_nuevo->valores[nuevo_tamano - 1] = nuevoValorResultado(copia, ARRAY);
    }
    else
    {
        // Transferir propiedad de primitivos directamente
        arr_nuevo->valores[nuevo_tamano - 1] = elem_res;
    }

    // No liberar el arreglo original aquí
    return nuevoValorResultado(arr_nuevo, ARRAY);
}

// Constructor para nodo de .add (ArrayAdd)
AbstractExpresion *nuevoArrayAddExpresion(AbstractExpresion *arr_expr, AbstractExpresion *elem_expr, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretArrayAdd, "ArrayAdd", line, column);
    agregarHijo(nodo, arr_expr);
    agregarHijo(nodo, elem_expr);
    return nodo;
}