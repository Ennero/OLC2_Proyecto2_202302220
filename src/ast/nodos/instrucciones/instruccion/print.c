#include "print.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/result.h"
#include "error_reporter.h"
#include "compilacion/generador_codigo.h"
#include <stdlib.h>
#include <stdio.h>

// La función que interpreta una instrucción de impresión
Result interpretPrintExpresion(AbstractExpresion *self, Context *context)
{
    AbstractExpresion *listaExpresiones = self->hijos[0];
    for (size_t i = 0; i < listaExpresiones->numHijos; ++i)
    {
        Result res = listaExpresiones->hijos[i]->interpret(listaExpresiones->hijos[i], context);

#ifdef DEBUG_PRINT
        printf("DEBUG [print]: Recibido para imprimir -> Tipo: %s, Puntero a Valor: %p\n", labelTipoDato[res.tipo], res.valor);
#endif

        if (has_semantic_error_been_found())
        {
            if (res.valor && res.tipo != ARRAY)
                free(res.valor);
            return nuevoValorResultadoVacio();
        }

        if (res.valor && res.tipo != ARRAY)
        {
            free(res.valor);
        }
    }
    return nuevoValorResultadoVacio();
}

static const char *generarPrintExpresion(AbstractExpresion *self, GeneradorCodigo *generador, Context *context)
{
    (void)context;
    if (!self || !generador || self->numHijos == 0)
    {
        return NULL;
    }

    AbstractExpresion *listaExpresiones = self->hijos[0];
    if (!listaExpresiones)
        return NULL;

    for (size_t i = 0; i < listaExpresiones->numHijos; ++i)
    {
        AbstractExpresion *expr = listaExpresiones->hijos[i];
        if (!expr)
            continue;

        const char *operador = expr->generar ? expr->generar(expr, generador, context) : NULL;
        if (operador)
        {
            agregar_cuadruplo(generador, CUAD_OPERACION_IMPRIMIR_CADENA, operador, NULL, NULL);
        }
    }

    const char *salto_linea = registrar_literal_cadena(generador, "\n");
    if (salto_linea)
    {
        agregar_cuadruplo(generador, CUAD_OPERACION_IMPRIMIR_CADENA, salto_linea, NULL, NULL);
    }

    return NULL;
}

// El constructor para el nodo de impresión
AbstractExpresion *nuevoPrintExpresion(AbstractExpresion *listaExpresiones, int line, int column)
{
    // Crear un nuevo nodo de impresión
    PrintExpresion *nodo = malloc(sizeof(PrintExpresion));
    if (!nodo)
        return NULL;
    buildAbstractExpresion(&nodo->base, interpretPrintExpresion, "Print", line, column);
    nodo->base.generar = generarPrintExpresion;

    if (listaExpresiones)
        agregarHijo((AbstractExpresion *)nodo, listaExpresiones);
    return (AbstractExpresion *)nodo;
}
