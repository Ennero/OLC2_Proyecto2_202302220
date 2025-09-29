#include "if.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

// La función que interpreta una instrucción if
Result interpretIfExpresion(AbstractExpresion *self, Context *context)
{
    // Interpretar la condición
    Result res_cond = self->hijos[0]->interpret(self->hijos[0], context);

    // Comprobaciones de error semántico y de tipo (esto ya estaba bien)
    if (has_semantic_error_been_found())
    {
        char description[256];
        snprintf(description, sizeof(description), "Error al evaluar la condición del if.");
        add_error_to_report("Semántico", "if", description, self->line, self->column, context->nombre_completo);
        free(res_cond.valor);
        return nuevoValorResultadoVacio();
    }

    // Si el tipo no es booleano, reportar error
    if (res_cond.tipo != BOOLEAN)
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "Se esperaba una expresión booleana en la condición del if, pero se encontró un valor de tipo '%s'.", labelTipoDato[res_cond.tipo]);
        add_error_to_report("Semantico", "if", desc, self->line, self->column, context->nombre_completo);
        free(res_cond.valor);
        return nuevoValorResultadoVacio();
    }

    // Extraer el valor booleano y liberar el resultado temporal
    int condicion_val = *(int *)res_cond.valor;
    free(res_cond.valor);

    Result resultado_bloque = nuevoValorResultadoVacio();

    // Ejecutar el bloque correspondiente si la condición se cumple
    if (condicion_val)
    {
        // El hijo 1 es el bloque del 'if'
        resultado_bloque = self->hijos[1]->interpret(self->hijos[1], context);
    }
    // Si la condición es falsa y hay un bloque 'else' o 'else if'
    else if (self->numHijos > 2 && self->hijos[2] != NULL)
    {
        // El hijo 2 es el bloque 'else'
        resultado_bloque = self->hijos[2]->interpret(self->hijos[2], context);
    }

    // El 'if' como sentencia toma posesión del resultado del bloque.
    if (resultado_bloque.tipo == BREAK_T ||
        resultado_bloque.tipo == CONTINUE_T ||
        resultado_bloque.tipo == RETURN_T)
    {
        // Propaga la señal
        return resultado_bloque;
    }

    // Si el resultado del bloque no fue una señal, su valor ya no es necesario.
    free(resultado_bloque.valor);

    return nuevoValorResultadoVacio();
}

// Constructor para el nodo IF
AbstractExpresion *nuevoIfExpresion(AbstractExpresion *condicion, AbstractExpresion *bloque_if, AbstractExpresion *bloque_else, int line, int column)
{
    IfExpresion *nodo = malloc(sizeof(IfExpresion));
    if (!nodo)
        return NULL;

    buildAbstractExpresion(&nodo->base, interpretIfExpresion, "IfStatement", line, column);

    agregarHijo((AbstractExpresion *)nodo, condicion);
    agregarHijo((AbstractExpresion *)nodo, bloque_if);

    // El bloque else es opcional
    if (bloque_else)
    {
        agregarHijo((AbstractExpresion *)nodo, bloque_else);
    }

    return (AbstractExpresion *)nodo;
}