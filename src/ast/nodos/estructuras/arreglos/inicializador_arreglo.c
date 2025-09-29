#include "inicializador_arreglo.h"
#include "ast/nodos/builders.h"
#include "context/array_value.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <string.h>

// Función recursiva para construir el ArrayValue a partir del inicializador
ArrayValue *construirDesdeInicializador(DeclaracionVariable *decl_node, Context *context, AbstractExpresion *current_list, TipoDato tipo_esperado, int dimension_esperada)
{
    if (!current_list)
        return NULL;

    int tamano = current_list->numHijos;
    ArrayValue *arr = nuevoArray(tipo_esperado, dimension_esperada, tamano);

    // Validación: si no se pudo crear el arreglo, retornar NULL
    for (int i = 0; i < tamano; i++)
    {
        AbstractExpresion *elemento_nodo = current_list->hijos[i];

        // Si el elemento es otro inicializador, llamada recursiva
        if (strcmp(elemento_nodo->node_type, "ArrayInitializer") == 0)
        {
            arr->valores[i].tipo = ARRAY;

            // La llamada recursiva sigue pasando el mismo decl_node
            arr->valores[i].valor = construirDesdeInicializador(decl_node, context, elemento_nodo->hijos[0], tipo_esperado, dimension_esperada - 1);
        }
        // Si es una expresión, evaluarla y asignar el valor
        else
        {
            Result res_elemento = elemento_nodo->interpret(elemento_nodo, context);
            // Validar tipo
            if (res_elemento.tipo != tipo_esperado)
            {
                add_error_to_report("Semantico", "{}", "Tipo incompatible en la lista de inicialización del arreglo.", decl_node->line, decl_node->column, context->nombre_completo);
                free(res_elemento.valor);
                liberarArray(arr);
                return NULL;
            }
            free(arr->valores[i].valor);
            arr->valores[i] = res_elemento;
        }
    }
    return arr;
}

// Interpretación del nodo inicializador de arreglos
Result interpretInicializadorArreglo(AbstractExpresion *self, Context *context)
{
    (void)context;
    return nuevoValorResultado(self, NULO);
}

// Constructor del nodo inicializador de arreglos
AbstractExpresion *nuevoInicializadorArreglo(AbstractExpresion *lista_exp, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretInicializadorArreglo, "ArrayInitializer", line, column);
    if (lista_exp)
    {
        agregarHijo(nodo, lista_exp);
    }
    return nodo;
}