#include "while.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

// Prototipo de la función de interpretación
Result interpretWhileExpresion(AbstractExpresion *self, Context *context);

// Implementación del constructor
AbstractExpresion *nuevoWhileExpresion(AbstractExpresion *condicion, AbstractExpresion *bloque, int line, int column)
{
    // Creamos el nodo 'while'
    WhileExpresion *nodo = malloc(sizeof(WhileExpresion));
    if (!nodo)
        return NULL;

    // Inicializamos la parte base del nodo
    buildAbstractExpresion(&nodo->base, interpretWhileExpresion, "WhileStatement", line, column);

    // Agrego los dos hijos del nodo while
    agregarHijo((AbstractExpresion *)nodo, condicion);
    agregarHijo((AbstractExpresion *)nodo, bloque);

    return (AbstractExpresion *)nodo;
}

// Implementación de la función de interpretación
Result interpretWhileExpresion(AbstractExpresion *self, Context *context)
{
    // Extraemos los nodos de condición y bloque
    AbstractExpresion *condicion_nodo = self->hijos[0];
    AbstractExpresion *bloque_nodo = self->hijos[1];

    // Bucle while
    while (1)
    {
        // Evalua la condición
        Result res_cond = condicion_nodo->interpret(condicion_nodo, context);

        if (has_semantic_error_been_found())
        {
            free(res_cond.valor);
            return nuevoValorResultadoVacio();
        }

        // Verifica que la condición sea booleana
        if (res_cond.tipo != BOOLEAN)
        {
            char desc[256];
            snprintf(desc, sizeof(desc), "Se esperaba una expresión booleana en la condición del while, pero se encontró un valor de tipo '%s'.", labelTipoDato[res_cond.tipo]);
            add_error_to_report("Semantico", "while", desc, self->line, self->column, context->nombre_completo);
            free(res_cond.valor);
            return nuevoValorResultadoVacio();
        }

        // Convierte el valor de la condición a entero (0 o 1)
        int condicion_val = *(int *)res_cond.valor;
        free(res_cond.valor);

        // Si la condición es falsa, el bucle termina
        if (!condicion_val)
        {
            break;
        }

        // Marcar que estamos en un contexto que permite break/continue
        if (context)
        {
            context->breakable_depth++;
            context->continuable_depth++;
        }

        // Ejecutar el bloque
        Result res_bloque = bloque_nodo->interpret(bloque_nodo, context);

        if (has_semantic_error_been_found())
        {
            free(res_bloque.valor);
            return nuevoValorResultadoVacio();
        }

        // Salimos del contexto break/continue
        if (context)
        {
            context->breakable_depth--;
            context->continuable_depth--;
        }

        // Si hay un return, lo propagamos hacia arriba inmediatamente.
        if (res_bloque.tipo == RETURN_T)
        {
            return res_bloque;
        }

        // Guardamos el tipo de señal que recibimos
        TipoDato tipo_señal = res_bloque.tipo;

        free(res_bloque.valor);

        // Ahora se actúa según la señal (si la hubo).
        if (tipo_señal == BREAK_T)
        {
            break; // Salimos del bucle while.
        }
        if (tipo_señal == CONTINUE_T)
        {
            continue; // Vamos a la siguiente iteración.
        }
        // Si no hubo señal se sigue en la iteración.
    }

    return nuevoValorResultadoVacio();
}