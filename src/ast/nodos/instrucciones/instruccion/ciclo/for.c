#include "for.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

Result interpretForExpresion(AbstractExpresion *self, Context *context);

// Implementación del constructor
AbstractExpresion *nuevoForExpresion(AbstractExpresion *init, AbstractExpresion *cond, AbstractExpresion *update, AbstractExpresion *bloque, int line, int column)
{
    ForExpresion *nodo = malloc(sizeof(ForExpresion));
    if (!nodo)
        return NULL;

    buildAbstractExpresion(&nodo->base, interpretForExpresion, "ForStatement", line, column);

    // Los 4 hijos pueden ser NULL, representando las partes opcionales del for
    agregarHijo((AbstractExpresion *)nodo, init);
    agregarHijo((AbstractExpresion *)nodo, cond);
    agregarHijo((AbstractExpresion *)nodo, update);
    agregarHijo((AbstractExpresion *)nodo, bloque);

    return (AbstractExpresion *)nodo;
}

Result interpretForExpresion(AbstractExpresion *self, Context *context)
{
    AbstractExpresion *init_nodo = self->hijos[0];
    AbstractExpresion *cond_nodo = self->hijos[1];
    AbstractExpresion *update_nodo = self->hijos[2];
    AbstractExpresion *bloque_nodo = self->hijos[3];

    // Se crea un nuevo contexto para el for
    Context *for_context = nuevoContext(context, "for_loop");

    // Se ejecuta la inicialización solo una vez dentro del nuevo contexto
    if (init_nodo)
    {
        Result res_init = init_nodo->interpret(init_nodo, for_context);
        free(res_init.valor); // El resultado de la inicialización no se usa
    }

    while (1)
    {
        // Se evalúa la condición
        bool condicion_val = true; // Por defecto, un 'for' wa infinito
        if (cond_nodo)
        {
            Result res_cond = cond_nodo->interpret(cond_nodo, for_context);
            if (res_cond.tipo != BOOLEAN)
            {
                char desc[256];
                snprintf(desc, sizeof(desc), "Se esperaba una expresión booleana en la condición del for, pero se encontró un valor de tipo '%s'.", labelTipoDato[res_cond.tipo]);
                add_error_to_report("Semantico", "for", desc, self->line, self->column, context->nombre_completo);
                free(res_cond.valor);
                condicion_val = false;
            }
            else
            {
                condicion_val = *(int *)res_cond.valor;
                free(res_cond.valor);
            }
        }

        if (!condicion_val)
        {
            break; // Salir del bucle
        }

        // Marcar que estamos en un contexto que permite break/continue
        for_context->breakable_depth++;
        for_context->continuable_depth++;

        // Ejecuta el bloque del cuerpo
        Result res_bloque = bloque_nodo->interpret(bloque_nodo, for_context);

        // Si se encuentra un return, se propaga inmediatamente
        if (res_bloque.tipo == RETURN_T)
        {
            liberarContext(for_context); // Liberar el contexto antes de salir
            return res_bloque;
        }

        // Salir del contexto de control
        for_context->breakable_depth--;
        for_context->continuable_depth--;

        // Se guarda el tipo de señal que se recibió
        TipoDato tipo_señal = res_bloque.tipo;
        free(res_bloque.valor);

        if (tipo_señal == BREAK_T)
        {
            break; // Salir del bucle
        }
        if (tipo_señal == CONTINUE_T)
        {
            goto update_step; // Un 'continue' salta directamente al paso de actualización
        }

    update_step:; // Etiqueta para el 'continue'
        // Ejecutar la actualización
        if (update_nodo)
        {
            Result res_update = update_nodo->interpret(update_nodo, for_context);
            free(res_update.valor);
        }
    }

    // Liberar el contexto del 'for' al terminar el bucle
    liberarContext(for_context);

    return nuevoValorResultadoVacio();
}