#include "identificadores.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include "context/array_value.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Función auxiliar para obtener el tamaño en bytes de nuestros tipos de datos
static size_t get_type_size(TipoDato tipo)
{
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

// Función de interpretación para el nodo Identificador
Result interpretIdentificadorExpresion(AbstractExpresion *self, Context *context)
{
    IdentificadorExpresion *nodo = (IdentificadorExpresion *)self;
    Symbol *simbolo = buscarTablaSimbolos(context, nodo->nombre);

    // Si no existe, error
    if (!simbolo)
    {
        char description[256];
        snprintf(description, sizeof(description), "La variable '%s' no ha sido declarada.", nodo->nombre);
        add_error_to_report("Semantico", nodo->nombre, description, nodo->line, nodo->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Si la variable es un arreglo, devolvemos la referencia al arreglo
    if (simbolo->tipo == ARRAY)
    {
        return nuevoValorResultado(simbolo->info.var.valor, ARRAY);
    }

    // Si el valor es NULL, devolvemos NULL del tipo adecuado
    if (simbolo->info.var.valor == NULL)
    {
        return nuevoValorResultado(NULL, simbolo->tipo);
    }

    // Devolvemos una copia del valor, protegiendo la tabla de símbolos.
    if (simbolo->tipo == STRING)
    {
        return nuevoValorResultado(strdup((char *)simbolo->info.var.valor), STRING);
    }
    else
    {
        size_t size = get_type_size(simbolo->tipo);
        void *valor_copiado = malloc(size);
        if (!valor_copiado)
            return nuevoValorResultadoVacio();

        memcpy(valor_copiado, simbolo->info.var.valor, size);
        return nuevoValorResultado(valor_copiado, simbolo->tipo);
    }
}

// Función constructora para el nodo Identificador
AbstractExpresion *nuevoIdentificadorExpresion(char *nombre, int line, int column)
{
    IdentificadorExpresion *nodo = malloc(sizeof(IdentificadorExpresion));
    if (!nodo)
        return NULL;

    buildAbstractExpresion(&nodo->base, interpretIdentificadorExpresion, "Identificador", line, column);
    nodo->nombre = nombre;
    nodo->line = line;
    nodo->column = column;

    return (AbstractExpresion *)nodo;
}