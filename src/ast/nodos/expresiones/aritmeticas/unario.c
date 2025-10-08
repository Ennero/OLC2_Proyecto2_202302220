#include "aritmeticas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

// Funciones de Negación ---------------
Result negarInt(Result res)
{
    int *val = malloc(sizeof(int));
    *val = -(*((int *)res.valor));
    free(res.valor);
    return nuevoValorResultado(val, INT);
}
Result negarFloat(Result res)
{
    float *val = malloc(sizeof(float));
    *val = -(*((float *)res.valor));
    free(res.valor);
    return nuevoValorResultado(val, FLOAT);
}
Result negarDouble(Result res)
{
    double *val = malloc(sizeof(double));
    *val = -(*((double *)res.valor));
    free(res.valor);
    return nuevoValorResultado(val, DOUBLE);
}

// Tabla de Operaciones
UnaryOperacion tablaOperacionesUnario[TIPO_COUNT] = {
    [INT] = negarInt,
    [FLOAT] = negarFloat,
    [DOUBLE] = negarDouble};

// Esta función para el nodo unario
Result interpretUnarioExpresion(AbstractExpresion *self, Context *context)
{
    // Interpretar la expresión hija
    Result res = self->hijos[0]->interpret(self->hijos[0], context);

    // Comprobar si el tipo es válido para la negación
    if (res.tipo >= TIPO_COUNT || tablaOperacionesUnario[res.tipo] == NULL)
    {
        char desc[256];
        sprintf(desc, "El operador unario '-' no se puede aplicar a un valor de tipo '%s'.", labelTipoDato[res.tipo]);
        add_error_to_report("Semantico", "-", desc, self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Llamar a la función de negación correcta
    return tablaOperacionesUnario[res.tipo](res);
}

// Constructor del Nodo
AbstractExpresion *nuevoUnarioExpresion(AbstractExpresion *expresion, int line, int column)
{
    AbstractExpresion *unarioExpresion = malloc(sizeof(AbstractExpresion));
    if (!unarioExpresion)
        return NULL;

    buildAbstractExpresion(unarioExpresion, interpretUnarioExpresion, "NegacionUnaria", line, column);
    agregarHijo(unarioExpresion, expresion);

    return unarioExpresion;
}