#include "print.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/result.h"
#include "output_buffer.h"
#include <stdlib.h>
#include <stdio.h>
#include "utils/java_num_format.h"
#include "output_buffer.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

// Función para convertir un valor a string para imprimir
static void result_to_string(Result res, char *buffer, size_t size)
{
    if (res.valor == NULL)
    {
        snprintf(buffer, size, "null");
        return;
    }
    switch (res.tipo)
    {
    case INT:
        snprintf(buffer, size, "%d", *(int *)res.valor);
        break;
    case FLOAT:
        // Aplicación de formato similar a Java
        java_format_float(*(float *)res.valor, buffer, size);
        break;
    case DOUBLE:
        // Aplicación de formato similar a Java
        java_format_double(*(double *)res.valor, buffer, size);
        break;
    case BOOLEAN:
        snprintf(buffer, size, "%s", *(int *)res.valor ? "true" : "false");
        break;
    case CHAR:
    {
        // El valor es un code point (int), imprimir como UTF-8
        int cp = *(int *)res.valor;
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
        snprintf(buffer, size, "%s", utf8);
        break;
    }
    case STRING:
        snprintf(buffer, size, "%s", (char *)res.valor);
        break;
    default:
        snprintf(buffer, size, "Tipo de dato desconocido");
        break;
    }
}

// La función que interpreta una instrucción de impresión
Result interpretPrintExpresion(AbstractExpresion *self, Context *context)
{
    // El primer hijo es la lista de expresiones a imprimir
    AbstractExpresion *listaExpresiones = self->hijos[0];
    for (size_t i = 0; i < listaExpresiones->numHijos; ++i)
    {
        Result res = listaExpresiones->hijos[i]->interpret(listaExpresiones->hijos[i], context);

        // --- DEBUGGING PRINT ---
#ifdef DEBUG_PRINT
        printf("DEBUG [print]: Recibido para imprimir -> Tipo: %s, Puntero a Valor: %p\n", labelTipoDato[res.tipo], res.valor);
        if (res.valor)
        {
            if (res.tipo == BOOLEAN)
                printf("DEBUG [print]: Valor Booleano es: %s\n", (*(int *)res.valor) ? "true" : "false");
            if (res.tipo == STRING)
                printf("DEBUG [print]: Valor String es: '%s'\n", (char *)res.valor);
        }
#endif
        // --------------------------

        // Si hubo un error semántico, salir
        if (has_semantic_error_been_found())
        {
            // Liberar solo temporales de primitivos/strings; nunca arreglos (referencias no-propietarias)
            if (res.valor && res.tipo != ARRAY)
                free(res.valor);
            return nuevoValorResultadoVacio();
        }

        // Convertir el resultado a string y agregarlo al buffer de salida
        char print_buffer[1024];
        result_to_string(res, print_buffer, sizeof(print_buffer));
        append_to_output(print_buffer);

        // Si no es el último elemento, agregar un espacio
        if (i < listaExpresiones->numHijos - 1)
            append_to_output(" ");

        // Mejor aqui no libero arreglos para evitar errores de doble liberación
        if (res.valor && res.tipo != ARRAY)
            free(res.valor);
    }
    // Al final, agregar un salto de línea
    append_to_output("\n");
    return nuevoValorResultadoVacio();
}

// El constructor para el nodo de impresión
AbstractExpresion *nuevoPrintExpresion(AbstractExpresion *listaExpresiones, int line, int column)
{
    // Crear un nuevo nodo de impresión
    PrintExpresion *nodo = malloc(sizeof(PrintExpresion));
    if (!nodo)
        return NULL;
    buildAbstractExpresion(&nodo->base, interpretPrintExpresion, "Print", line, column);

    if (listaExpresiones)
        agregarHijo((AbstractExpresion *)nodo, listaExpresiones);
    return (AbstractExpresion *)nodo;
}
