#include "reasignacion.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/array_value.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

// La función que interpreta una reasignación
Result interpretReasignacion(AbstractExpresion *self, Context *context)
{
    // Obtener el símbolo de la tabla de símbolos
    ReasignacionExpresion *nodo = (ReasignacionExpresion *)self;
    Symbol *simbolo = buscarTablaSimbolos(context, nodo->nombre);

    // Verificar que el símbolo exista y sea una variable
    if (!simbolo || simbolo->clase != VARIABLE)
    {
        char description[256];
        snprintf(description, sizeof(description), "La variable '%s' no ha sido declarada.", nodo->nombre);
        add_error_to_report("Semántico", nodo->nombre, description, nodo->line, nodo->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Si es constante, no se puede reasignar
    if (simbolo->es_constante)
    {
        char description[256];
        snprintf(description, sizeof(description), "No se puede reasignar la constante 'final' '%s'.", nodo->nombre);
        add_error_to_report("Semantico", nodo->nombre, description, nodo->line, nodo->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Evaluar la nueva expresión para obtener el nuevo valor
    Result nuevo_valor = self->hijos[0]->interpret(self->hijos[0], context);

    // Verificar si hubo un error semántico durante la evaluación
    if (has_semantic_error_been_found())
    {
        free(nuevo_valor.valor);
        return nuevoValorResultadoVacio();
    }

    // Comprobar compatibilidad de tipos; permitir widening implícito y null para String/Array
    bool es_compatible = (simbolo->tipo == nuevo_valor.tipo);

    // Permitir asignación de null para String y Arreglo
    if (nuevo_valor.tipo == NULO && (simbolo->tipo == STRING || simbolo->tipo == ARRAY))
    {
        es_compatible = true;
    }
    if (!es_compatible)
    {
        // Caso especial: permitir int -> char (narrowing implícito estilo Java para char)
        if (simbolo->tipo == CHAR && nuevo_valor.tipo == INT)
        {
            int *p = malloc(sizeof(int));
            *p = (int)((unsigned char)(*(int *)nuevo_valor.valor));
            free(nuevo_valor.valor);
            nuevo_valor.valor = p;
            nuevo_valor.tipo = CHAR;
            es_compatible = true;
        }
        else if (can_widen(nuevo_valor.tipo, simbolo->tipo))
        {
            nuevo_valor = widen_to(nuevo_valor, simbolo->tipo);
            es_compatible = true;
        }
    }

    // Si no son compatibles, se reporta un error.
    if (!es_compatible)
    {
        char description[256];
        snprintf(description, sizeof(description), "Error de tipos: no se puede asignar un valor de tipo '%s' a la variable '%s' de tipo '%s'.",
                 labelTipoDato[nuevo_valor.tipo], nodo->nombre, labelTipoDato[simbolo->tipo]);
        add_error_to_report("Semántico", nodo->nombre, description, nodo->line, nodo->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Resolver alias: si este símbolo es un alias de otro (p.ej., parámetro String por referencia),
    // la escritura debe hacerse sobre el dueño real
    Symbol *target = simbolo;
    if (simbolo->clase == VARIABLE)
    {
        while (target->info.var.alias_of != NULL)
        {
            target = target->info.var.alias_of;
        }
    }

    // Se asigna el valor con manejo especial para arreglos (propiedad/borrowed)
    if (target->tipo == ARRAY)
    {
        ArrayValue *old_arr = (ArrayValue *)target->info.var.valor;
        int was_borrowed = target->info.var.borrowed;

        // No liberar el arreglo anterior si es prestado (borrowed)
        if (old_arr && !was_borrowed)
        {
            liberarArray(old_arr);
        }

        // Asignar el nuevo arreglo (clonar para mantener consistencia de propiedad si viene de temporal)
        if (nuevo_valor.valor != NULL)
        {
            target->info.var.valor = copiarArray((ArrayValue *)nuevo_valor.valor);
        }
        else
        {
            target->info.var.valor = NULL;
        }

        // Si antes era borrowed (p.ej., parámetro de función) y ahora le asignamos un nuevo arreglo,
        // el símbolo pasa a ser dueño del valor nuevo, por lo que removemos el flag borrowed.
        target->info.var.borrowed = 0;
    }
    else
    {
        // Primitivo o String
        if (target->info.var.valor)
        {
            free(target->info.var.valor);
        }
        target->info.var.valor = nuevo_valor.valor;
    }

    return nuevoValorResultadoVacio();
}

// El constructor para el nodo de reasignación
AbstractExpresion *nuevoReasignacionExpresion(char *nombre, AbstractExpresion *expresion, int line, int column)
{
    // Crear un nuevo nodo de reasignación
    ReasignacionExpresion *nodo = malloc(sizeof(ReasignacionExpresion));
    if (!nodo)
        return NULL;

    buildAbstractExpresion(&nodo->base, interpretReasignacion, "Reasignacion", line, column);
    nodo->nombre = nombre;
    nodo->line = line;
    nodo->column = column;

    agregarHijo((AbstractExpresion *)nodo, expresion);

    return (AbstractExpresion *)nodo;
}
