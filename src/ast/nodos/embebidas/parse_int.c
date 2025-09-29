#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <errno.h>
#include <limits.h>

// Convierte un String a int, manejando errores
Result interpretParseInt(AbstractExpresion *self, Context *context)
{
    // Interpreta el argumento
    Result arg = self->hijos[0]->interpret(self->hijos[0], context);

    // Valida que el argumento sea un String
    if (arg.tipo != STRING)
    {
        add_error_to_report("Semantico", "Integer.parseInt", "El argumento debe ser de tipo String.", self->line, self->column, context->nombre_completo);
        free(arg.valor);
        return nuevoValorResultadoVacio();
    }

    char *endptr;
    errno = 0; // Reiniciar el indicador de error
    long val = strtol((char *)arg.valor, &endptr, 10);

    // Verifica errores de conversión
    if (errno == ERANGE || val > INT_MAX || val < INT_MIN)
    {
        add_error_to_report("Semantico", "Integer.parseInt", "El número está fuera del rango de un entero.", self->line, self->column, context->nombre_completo);
        free(arg.valor);
        return nuevoValorResultadoVacio();
    }

    // Si no se consumió todo el string, o no se pudo convertir nada
    if (endptr == (char *)arg.valor || *endptr != '\0')
    {
        add_error_to_report("Semantico", "Integer.parseInt", "El string no tiene un formato de entero válido.", self->line, self->column, context->nombre_completo);
        free(arg.valor);
        return nuevoValorResultadoVacio();
    }

    // Si todo está bien, crear el resultado
    free(arg.valor); // Se libera el string original
    int *resultado = malloc(sizeof(int));
    *resultado = (int)val;
    return nuevoValorResultado(resultado, INT);
}

// Constructor para nodo de Integer.parseInt
AbstractExpresion *nuevoParseIntExpresion(AbstractExpresion *expr, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretParseInt, "ParseInt", line, column);
    agregarHijo(nodo, expr);
    return nodo;
}