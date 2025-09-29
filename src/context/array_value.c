// Implementacion de utilidades para arreglos (creacion, copia profunda, liberacion).
#include "array_value.h"
#include <stdlib.h>
#include <string.h>

// Obtiene el valor por defecto para un tipo primitivo
Result getDefaultValueForType(TipoDato tipo)
{
    void *default_value = NULL;

    // Asignar valores por defecto según el tipo
    switch (tipo)
    {
    // Para los 3 tipos que usan 'int' como almacenamiento
    case INT:
    case CHAR:
    case BOOLEAN:
        default_value = malloc(sizeof(int));
        *(int *)default_value = 0;
        break;
    case FLOAT:
        default_value = malloc(sizeof(float));
        *(float *)default_value = 0.0f;
        break;
    case DOUBLE:
        default_value = malloc(sizeof(double));
        *(double *)default_value = 0.0;
        break;
    case STRING:
        default_value = NULL;
        break;
    default:
        break;
    }
    return nuevoValorResultado(default_value, tipo);
}

// Crea un ArrayValue para una dimension; si es la ultima dimension (dimensiones==1)
// inicializa cada elemento con el valor por defecto del tipo base
ArrayValue *nuevoArray(TipoDato tipo_base, int dimensiones, int tamano)
{
    ArrayValue *arr = malloc(sizeof(ArrayValue));
    arr->tipo_elemento_base = tipo_base;
    arr->dimensiones_total = dimensiones;
    arr->tamano = tamano;
    arr->valores = calloc(tamano, sizeof(Result));

    // Si es la última dimensión, inicializamos con valores por defecto del tipo base.
    if (dimensiones == 1)
    {
        for (int i = 0; i < tamano; i++)
        {
            arr->valores[i] = getDefaultValueForType(tipo_base);
        }
    }
    return arr;
}

// Libera recursivamente el arreglo y los valores contenidos
void liberarArray(ArrayValue *arr)
{
    // Verificar que el arreglo no sea NULL
    if (!arr)
        return;
    for (int i = 0; i < arr->tamano; i++)
    {
        // Si los elementos son sub-arreglos, liberarlos recursivamente.
        if (arr->valores[i].tipo == ARRAY)
        {
            liberarArray((ArrayValue *)arr->valores[i].valor);
        }
        else
        {
            // Si no, liberar el valor primitivo.
            free(arr->valores[i].valor);
        }
    }
    free(arr->valores);
    free(arr);
}

// Función auxiliar para obtener el tamaño de un tipo (evita duplicar código)
static size_t get_type_size_internal(TipoDato tipo)
{
    // Retorna el tamaño en bytes del tipo primitivo
    switch (tipo)
    {
    case INT:
    case BOOLEAN:
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

// Realiza una copia profunda de un ArrayValue
ArrayValue *copiarArray(ArrayValue *original)
{
    if (!original)
        return NULL;

    // Crear la estructura del nuevo arreglo
    ArrayValue *copia = nuevoArray(original->tipo_elemento_base, original->dimensiones_total, original->tamano);

    // Copiar cada elemento
    for (int i = 0; i < original->tamano; i++)
    {
        // Obtener el elemento original
        Result elem_original = original->valores[i];

        // Liberamos el valor por defecto que 'nuevoArray' puso en la copia
        free(copia->valores[i].valor);

        // Copiar el tipo
        copia->valores[i].tipo = elem_original.tipo;

        // Copiar el valor según el tipo
        if (elem_original.tipo == ARRAY)
        {
            // Si el elemento es otro arreglo, lo copiamos recursivamente
            copia->valores[i].valor = copiarArray((ArrayValue *)elem_original.valor);
        }
        else
        {
            // Si es un valor primitivo, hacemos una copia profunda de su valor
            if (elem_original.valor == NULL)
            {
                copia->valores[i].valor = NULL;
            }
            // Cadena necesita strdup
            else if (elem_original.tipo == STRING)
            {
                copia->valores[i].valor = strdup((char *)elem_original.valor);
            }
            // Para los tipos que usan int, float, double
            else
            {
                size_t size = get_type_size_internal(elem_original.tipo);
                copia->valores[i].valor = malloc(size);
                memcpy(copia->valores[i].valor, elem_original.valor, size);
            }
        }
    }
    return copia;
}