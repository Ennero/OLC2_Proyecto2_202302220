#include "bloque.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "array_value.h"
#include <stdlib.h>
#include <stdio.h>

// La función que interpreta un bloque de sentencias
Result interpretBloqueExpresion(AbstractExpresion *self, Context *context)
{
    // Genera el nombre para el nuevo bloque
    char nombre_buffer[32];
    sprintf(nombre_buffer, "bloque%d", context->raiz->proximo_id_bloque);
    context->raiz->proximo_id_bloque++;

    // Crear el nuevo contexto para este bloque
    Context *nuevo_contexto = nuevoContext(context, nombre_buffer);

    // Interpretar las sentencias y CAPTURAR su resultado
    Result res_bloque = nuevoValorResultadoVacio(); // Valor por defecto si el bloque está vacío

    // Interpretar las sentencias hijas
    if (self->numHijos > 0 && self->hijos != NULL && self->hijos[0] != NULL)
    {
        res_bloque = self->hijos[0]->interpret(self->hijos[0], nuevo_contexto);
    }

    // Si el bloque está propagando un return y el valor retornado es un ARRAY clonar el arreglo ANTES de liberar el contexto
    if (res_bloque.tipo == RETURN_T && res_bloque.valor)
    {
        // Verificar si el valor es un ArrayValue
        Result *wrapped = (Result *)res_bloque.valor;
        if (wrapped->tipo == ARRAY && wrapped->valor)
        {
            // Verificar si el arreglo es "propiedad" del bloque (fue declarado ahí)
            int owned_by_block = 0;

            // Buscar en los símbolos del contexto del bloque
            for (Symbol *s = nuevo_contexto->ultimoSymbol; s != NULL; s = s->anterior)
            {
                // Verificar si el símbolo es una variable de tipo arreglo
                if (s->clase == VARIABLE && s->tipo == ARRAY && s->info.var.valor == wrapped->valor)
                {
                    owned_by_block = 1;
                    break;
                }
            }
            // Si el arreglo es "propiedad" del bloque, hacer una copia profunda
            if (owned_by_block)
            {
                ArrayValue *copia = copiarArray((ArrayValue *)wrapped->valor);
                
                // El original será liberado al liberar el contexto del bloque
                wrapped->valor = copia;
            }
        }
    }

    // Liberar el nuevo contexto
    liberarContext(nuevo_contexto);

    // Devolver el resultado capturado del bloque.
    return res_bloque;
}

// El constructor del nodo de bloque
AbstractExpresion *nuevoBloqueExpresion(AbstractExpresion *lSentencia, int line, int column)
{
    BloqueExpresion *nodo = malloc(sizeof(BloqueExpresion));
    if (!nodo)
        return NULL;

    // Inicializar la parte base del nodo
    buildAbstractExpresion(&nodo->base, interpretBloqueExpresion, "Bloque", line, column);

    // Agregar la lista de sentencias como hijo, si existe
    if (lSentencia)
    {
        agregarHijo((AbstractExpresion *)nodo, lSentencia);
    }
    return (AbstractExpresion *)nodo;
}