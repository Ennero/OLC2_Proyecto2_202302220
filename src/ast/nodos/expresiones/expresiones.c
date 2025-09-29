#include "ast/AbstractExpresion.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/result.h"
#include "expresiones.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

// Implementación del interpret para expresiones binarias
Result interpretExpresionLenguaje(AbstractExpresion *self, Context *context)
{
    ExpresionLenguaje *nodo = (ExpresionLenguaje *)self;

    Result izquierda = self->hijos[0]->interpret(self->hijos[0], context);
    Result derecha = self->hijos[1]->interpret(self->hijos[1], context);

    // Si hubo error en alguno de los lados, no continuar
    if (has_semantic_error_been_found())
    {
        // No liberar arreglos: normalmente son referencias prestadas desde la tabla de símbolos
        if (izquierda.tipo != ARRAY)
            free(izquierda.valor);
        if (derecha.tipo != ARRAY)
            free(derecha.valor);
        return nuevoValorResultadoVacio();
    }

    // Almacenamos los resultados temporalmente en el nodo para pasarlos a la función de operación
    nodo->izquierda = izquierda;
    nodo->derecha = derecha;

    // Buscar la operación en la tabla
    Operacion op = (*nodo->tablaOperaciones)[izquierda.tipo][derecha.tipo];

    // Si no existe, error
    if (op == NULL)
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "La operacion '%s' no esta definida entre los tipos %s y %s.", self->node_type, labelTipoDato[izquierda.tipo], labelTipoDato[derecha.tipo]);
        add_error_to_report("Semantico", self->node_type, desc, self->line, self->column, context->nombre_completo);
        free(izquierda.valor);
        free(derecha.valor);
        return nuevoValorResultadoVacio();
    }

    Result resultado_final = op(nodo);

    // No liberar arreglos: normalmente son referencias prestadas desde la tabla de símbolos
    if (izquierda.tipo != ARRAY)
        free(izquierda.valor);
    if (derecha.tipo != ARRAY)
        free(derecha.valor);

    return resultado_final;
}

// Función para interpretar expresiones
ExpresionLenguaje *nuevoExpresionLenguaje(Interpret funcionEspecifica, AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column)
{
    ExpresionLenguaje *nodo = malloc(sizeof(ExpresionLenguaje));
    if (!nodo)
        return NULL;

    buildAbstractExpresion(&nodo->base, funcionEspecifica, "ExpresionLenguaje", line, column);

    // Inicializar resultados a vacío
    if (izquierda)
        agregarHijo((AbstractExpresion *)nodo, izquierda);
    if (derecha)
        agregarHijo((AbstractExpresion *)nodo, derecha);

    return nodo;
}

// Funciones auxiliares para calcular resultados izquierdo y derecho
void calcularResultadoIzquierdo(ExpresionLenguaje *self, Context *context)
{
    self->izquierda = self->base.hijos[0]->interpret(self->base.hijos[0], context);
}

// Similar para el derecho
void calcularResultadoDerecho(ExpresionLenguaje *self, Context *context)
{
    self->derecha = self->base.hijos[1]->interpret(self->base.hijos[1], context);
}

// Calcular ambos resultados
void calcularResultados(ExpresionLenguaje *self, Context *context)
{
    calcularResultadoIzquierdo(self, context);
    calcularResultadoDerecho(self, context);
}