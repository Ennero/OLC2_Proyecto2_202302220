#include "logicas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

// Logica de NOT
Result logicoNotBooleano(Result res)
{
    int *val = malloc(sizeof(int));

    // Se aplica la negación lógica de C (!)
    *val = !(*((int *)res.valor));
    free(res.valor);
    return nuevoValorResultado(val, BOOLEAN);
}

// Tabla de Operaciones
UnaryOperacion tablaOperacionesNot[TIPO_COUNT] = {
    [BOOLEAN] = logicoNotBooleano};

// Interpretador para el Nodo NOT
Result interpretNotExpresion(AbstractExpresion *self, Context *context)
{
    // Interpretar la expresión hija
    Result res = self->hijos[0]->interpret(self->hijos[0], context);

    // Comprobar si el tipo es BOOLEAN
    if (res.tipo != BOOLEAN)
    {
        char desc[256];
        sprintf(desc, "El operador unario '!' no se puede aplicar a un valor de tipo '%s'.", labelTipoDato[res.tipo]);
        add_error_to_report("Semantico", "!", desc, self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Llama a la función de negación correcta
    return tablaOperacionesNot[res.tipo](res);
}

// Constructor del Nodo
AbstractExpresion *nuevoNotExpresion(AbstractExpresion *expresion, int line, int column)
{
    AbstractExpresion *notExpresion = malloc(sizeof(AbstractExpresion));
    if (!notExpresion)
        return NULL;

    buildAbstractExpresion(notExpresion, interpretNotExpresion, "Not", line, column);
    agregarHijo(notExpresion, expresion);

    return notExpresion;
}