#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "utils/java_num_format.h"

// Convierte un valor primitivo o String a su representación en cadena
Result interpretStringValueof(AbstractExpresion *self, Context *context)
{
    Result arg = self->hijos[0]->interpret(self->hijos[0], context);
    char buffer[1024];

    // Manejar nulo
    if (arg.valor == NULL)
    {
        snprintf(buffer, sizeof(buffer), "null");
    }
    else
    {
        switch (arg.tipo)
        {
        case INT:
            snprintf(buffer, sizeof(buffer), "%d", *(int *)arg.valor);
            break;
        case FLOAT:
            java_format_float(*(float *)arg.valor, buffer, sizeof(buffer));
            break;
        case DOUBLE:
            java_format_double(*(double *)arg.valor, buffer, sizeof(buffer));
            break;
        case BOOLEAN:
            snprintf(buffer, sizeof(buffer), "%s", (*(int *)arg.valor) ? "true" : "false");
            break;
        case CHAR:
        {
            // Convertir code point (int) a UTF-8
            int cp = *(int *)arg.valor;
            char utf8[5] = {0};
            if (cp <= 0x7F)
            {
                utf8[0] = (char)cp;
            }
            else if (cp <= 0x7FF)
            {
                utf8[0] = (char)(0xC0 | ((cp >> 6) & 0x1F));
                utf8[1] = (char)(0x80 | (cp & 0x3F));
            }
            else if (cp <= 0xFFFF)
            {
                utf8[0] = (char)(0xE0 | ((cp >> 12) & 0x0F));
                utf8[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
                utf8[2] = (char)(0x80 | (cp & 0x3F));
            }
            else
            {
                utf8[0] = (char)(0xF0 | ((cp >> 18) & 0x07));
                utf8[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
                utf8[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
                utf8[3] = (char)(0x80 | (cp & 0x3F));
            }
            snprintf(buffer, sizeof(buffer), "%s", utf8);
            break;
        }
        case STRING:
            snprintf(buffer, sizeof(buffer), "%s", (char *)arg.valor);
            break;
        default:
            snprintf(buffer, sizeof(buffer), "Object");
            break;
        }
    }

    free(arg.valor); // Liberamos el valor original del argumento
    return nuevoValorResultado(strdup(buffer), STRING);
}

// Constructor para nodo de String.valueOf
AbstractExpresion *nuevoStringValueofExpresion(AbstractExpresion *expr, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretStringValueof, "StringValueof", line, column);
    agregarHijo(nodo, expr);
    return nodo;
}