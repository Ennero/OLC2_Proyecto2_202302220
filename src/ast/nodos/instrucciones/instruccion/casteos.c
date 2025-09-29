#include "casteos.h"
#include "ast/nodos/builders.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Prototipo de la función de interpretación
Result interpretCasteoExpresion(AbstractExpresion *self, Context *context);

// Implementación de la función de interpretación con todas las conversiones numéricas
Result interpretCasteoExpresion(AbstractExpresion *self, Context *context)
{
    CasteoExpresion *nodo_casteo = (CasteoExpresion *)self;
    AbstractExpresion *expresion_a_castear = self->hijos[0];
    Result res_origen = expresion_a_castear->interpret(expresion_a_castear, context);

    // Si es nulo o hubo un error, retornar inmediatamente
    if (res_origen.valor == NULL)
    {
        return res_origen;
    }

    // Manejar los tipos de origen y destino
    TipoDato tipo_origen = res_origen.tipo;
    TipoDato tipo_destino = nodo_casteo->tipo_destino;

    // Si los tipos son iguales, no se necesita casteo
    if (tipo_origen == tipo_destino)
        return res_origen;

    // Obtener el valor numérico del tipo de origen (promocionándolo a double)
    double valor_numerico_original = 0.0;

    // Dependiendo del tipo de origen, extraer el valor
    switch (tipo_origen)
    {
    // Int y char son lo mismo en almacenamiento
    case INT:
    case CHAR:
        valor_numerico_original = (double)(*(int *)res_origen.valor);
        break;
    case FLOAT:
        valor_numerico_original = (double)(*(float *)res_origen.valor);
        break;
    case DOUBLE:
        valor_numerico_original = *(double *)res_origen.valor;
        break;
    default:
        goto error;
    }

    // Realizar el casteo al tipo de destino
    switch (tipo_destino)
    {
    case INT:
    {
        int *valor_nuevo = malloc(sizeof(int));
        *valor_nuevo = (int)valor_numerico_original;
        free(res_origen.valor); // Liberamos la memoria del valor original
        return nuevoValorResultado(valor_nuevo, INT);
    }
    case CHAR:
    {
        int *valor_nuevo = malloc(sizeof(int));
        *valor_nuevo = (int)valor_numerico_original;
        free(res_origen.valor); // Liberamos la memoria del valor original
        return nuevoValorResultado(valor_nuevo, CHAR);
    }
    case FLOAT:
    {
        float *valor_nuevo = malloc(sizeof(float));
        *valor_nuevo = (float)valor_numerico_original;
        free(res_origen.valor); // Liberamos la memoria del valor original
        return nuevoValorResultado(valor_nuevo, FLOAT);
    }
    case DOUBLE:
    {
        double *valor_nuevo = malloc(sizeof(double));
        *valor_nuevo = valor_numerico_original;
        free(res_origen.valor); // Liberamos la memoria del valor original
        return nuevoValorResultado(valor_nuevo, DOUBLE);
    }
    default:
        goto error;
    }

// Si llegamos aquí, hubo un error de casteo
error:;
    char description[256];
    sprintf(description, "Casteo explícito del tipo '%s' a '%s' no está permitido.", labelTipoDato[tipo_origen], labelTipoDato[tipo_destino]);
    add_error_to_report("Semantico", "casteo", description, self->line, self->column, context->nombre_completo);
    free(res_origen.valor); // Liberamos la memoria del valor original incluso si hay error
    return nuevoValorResultadoVacio();
}

// Implementación del constructor
AbstractExpresion *nuevoCasteoExpresion(TipoDato tipo_destino, AbstractExpresion *expresion, int line, int column)
{
    // Crear el nodo de casteo
    CasteoExpresion *nodo = malloc(sizeof(CasteoExpresion));
    if (!nodo)
    {
        perror("No se pudo alocar memoria para CasteoExpresion");
        return NULL;
    }

    // Inicializar la parte base del nodo
    buildAbstractExpresion(&nodo->base, interpretCasteoExpresion, "Casteo", line, column);
    nodo->tipo_destino = tipo_destino;
    agregarHijo((AbstractExpresion *)nodo, expresion);
    return (AbstractExpresion *)nodo;
}