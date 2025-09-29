#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include <stdlib.h> 
#include <errno.h> 

// Convierte un String a double, manejando errores (obviamente xd)
Result interpretParseDouble(AbstractExpresion *self, Context *context)
{
    Result arg = self->hijos[0]->interpret(self->hijos[0], context);

    // Validar que sea un String
    if (arg.tipo != STRING)
    {
        add_error_to_report("Semantico", "Double.parseDouble", "El argumento debe ser de tipo String.", self->line, self->column, context->nombre_completo);
        free(arg.valor);
        return nuevoValorResultadoVacio();
    }

    char *endptr;
    errno = 0;
    double val = strtod((char *)arg.valor, &endptr);

    // Verificar errores de conversión
    if (errno == ERANGE)
    {
        add_error_to_report("Semantico", "Double.parseDouble", "El número está fuera del rango de un double.", self->line, self->column, context->nombre_completo);
        free(arg.valor);
        return nuevoValorResultadoVacio();
    }

    // Si no se consumió todo el string, o no se pudo convertir nada
    if (endptr == (char *)arg.valor || *endptr != '\0')
    {
        add_error_to_report("Semantico", "Double.parseDouble", "El string no tiene un formato de double válido.", self->line, self->column, context->nombre_completo);
        free(arg.valor);
        return nuevoValorResultadoVacio();
    }

    free(arg.valor);
    double *resultado = malloc(sizeof(double));
    *resultado = val;
    return nuevoValorResultado(resultado, DOUBLE);
}

// Constructor para nodo de Double.parseDouble
AbstractExpresion *nuevoParseDoubleExpresion(AbstractExpresion *expr, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretParseDouble, "ParseDouble", line, column);
    agregarHijo(nodo, expr);
    return nodo;
}