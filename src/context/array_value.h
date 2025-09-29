// Manejo de instancias de arreglos (incluye soporte para arreglos irregulares).
#ifndef ARRAY_VALUE_H
#define ARRAY_VALUE_H

#include "result.h"

// Representa una instancia de un arreglo en memoria.
typedef struct ArrayValue
{
    TipoDato tipo_elemento_base; // El tipo primitivo final
    int dimensiones_total;       // Número total de dimensiones

    // Info de esta dimensión específica
    int tamano;      
    Result *valores; // Punteros a los 'Result'
    // Si es un arreglo multidimensional, el Result.tipo será ARRAY y Result.valor será otro struct ArrayValue.

} ArrayValue;

// Prototipos de funciones auxiliares
ArrayValue *nuevoArray(TipoDato tipo_base, int dimensiones, int tamano);

// Realiza una copia profunda del arreglo y sus elementos
ArrayValue *copiarArray(ArrayValue *original);

// Libera la memoria ocupada por un arreglo
void liberarArray(ArrayValue *arr);
Result getDefaultValueForType(TipoDato tipo);

#endif // ARRAY_VALUE_H