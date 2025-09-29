#include "ast/nodos/builders.h"
#include "error_reporter.h"
#include <stdlib.h>

// El 'break' simplemente devuelve un resultado especial
Result interpretBreakExpresion(AbstractExpresion *self, Context *context)
{
    // Validar que estemos dentro de un contexto que permita 'break'
    if (context && context->breakable_depth > 0)
    {
        return nuevoValorResultado(NULL, BREAK_T);
    }

    // Si no estamos dentro de un bucle o switch, reportar error semántico
    const char *ctx_name = context ? context->nombre_completo : "global";
    add_error_to_report("Semantico", "break",
                        "La sentencia 'break' solo puede usarse dentro de bucles o en un 'switch'.",
                        self->line, self->column, ctx_name);
    return nuevoValorResultadoVacio();
}

AbstractExpresion *nuevoBreakExpresion(int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretBreakExpresion, "BreakStatement", line, column);
    return nodo;
}