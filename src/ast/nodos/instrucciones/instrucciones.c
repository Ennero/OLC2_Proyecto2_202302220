#include "instrucciones.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/result.h"
#include "error_reporter.h"
#include "compilacion/generador_codigo.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// La función que genera código para una lista de instrucciones
static const char *generarInstruccionesExpresion(AbstractExpresion *self, GeneradorCodigo *generador, Context *context)
{
    (void)context;
    if (!self || !generador)
    {
        return NULL;
    }

    // Generar código para cada instrucción hija
    for (size_t i = 0; i < self->numHijos; ++i)
    {
        // Verificar el nodo hijo
        AbstractExpresion *nodo = self->hijos[i];
        if (nodo && nodo->generar)
        {
            nodo->generar(nodo, generador, context);
        }
    }
    return NULL;
}

// Función de interpretación para el nodo Instrucciones
Result interpretInstruccionesExpresion(AbstractExpresion *self, Context *context)
{
    // Detectar si hay FunctionDeclaration o MainFunction en los hijos
    bool has_fn_like = false;

    // Buscar en los hijos
    for (size_t i = 0; i < self->numHijos; ++i)
    {
        // Verificar el tipo del nodo hijo
        const char *t = self->hijos[i]->node_type;

        // Si encontramos FunctionDeclaration o MainFunction, marcamos la bandera
        if (t && (strcmp(t, "FunctionDeclaration") == 0 || strcmp(t, "MainFunction") == 0))
        {
            has_fn_like = true;
            break;
        }
    }

    // Resultado por defecto (vacío)
    Result res = nuevoValorResultadoVacio();

    // Si hay funciones, separamos en dos fases
    if (has_fn_like)
    {
        // Fase 1: solo Declaracion y FunctionDeclaration
        for (size_t i = 0; i < self->numHijos; ++i)
        {
            // Verificar el tipo del nodo hijo
            AbstractExpresion *nodo = self->hijos[i];

            // Verificar el tipo del nodo hijo
            const char *t = nodo->node_type;

            // Solo ejecutar Declaracion y FunctionDeclaration
            if (t && (strcmp(t, "Declaracion") == 0 || strcmp(t, "FunctionDeclaration") == 0))
            {
                // Libera solo temporales no-arreglo (los arreglos son manejados por el contexto)
                if (res.valor && res.tipo != ARRAY && res.tipo != BREAK_T && res.tipo != CONTINUE_T && res.tipo != RETURN_T)
                {
                    free(res.valor);
                    res = nuevoValorResultadoVacio();
                }
                res = nodo->interpret(nodo, context);
                if (has_semantic_error_been_found())
                {
                    return res;
                }
            }
        }

        // Fase 2: ejecutar el resto
        for (size_t i = 0; i < self->numHijos; ++i)
        {
            // Verificar el tipo del nodo hijo
            AbstractExpresion *nodo = self->hijos[i];
            const char *t = nodo->node_type;

            // Ejecutar todo excepto Declaracion y FunctionDeclaration (porque se ejecutaron en la fase 1)
            if (!(t && (strcmp(t, "Declaracion") == 0 || strcmp(t, "FunctionDeclaration") == 0)))
            {
                // Libera solo temporales no-arreglo (los arreglos son manejados por el contexto)
                if (res.valor && res.tipo != ARRAY && res.tipo != BREAK_T && res.tipo != CONTINUE_T && res.tipo != RETURN_T)
                {
                    free(res.valor);
                    res = nuevoValorResultadoVacio();
                }
                // Ejecutar la instrucción
                res = nodo->interpret(nodo, context);
                if (res.tipo == BREAK_T || res.tipo == CONTINUE_T || res.tipo == RETURN_T)
                {
                    return res;
                }
                // Verificar si hubo un error semántico
                if (has_semantic_error_been_found())
                {
                    return res; // error ya reportado
                }
            }
        }
    }
    // Si no hay funciones, ejecutar secuencialmente
    else
    {
        // Ejecución secuencial dentro de bloques normales
        for (size_t i = 0; i < self->numHijos; ++i)
        {
            // Libera solo temporales no-arreglo (los arreglos son manejados por el contexto)
            if (res.valor && res.tipo != ARRAY && res.tipo != BREAK_T && res.tipo != CONTINUE_T && res.tipo != RETURN_T)
            {
                free(res.valor);
                res = nuevoValorResultadoVacio();
            }

            // Ejecutar la instrucción
            res = self->hijos[i]->interpret(self->hijos[i], context);
            if (res.tipo == BREAK_T || res.tipo == CONTINUE_T || res.tipo == RETURN_T)
            {
                return res;
            }
            if (has_semantic_error_been_found())
            {
                return res; // error ya reportado
            }
        }
    }

    // Liberar el resultado temporal si no es un arreglo o una señal de control
    if (res.valor && res.tipo != ARRAY && res.tipo != BREAK_T && res.tipo != CONTINUE_T && res.tipo != RETURN_T)
    {
        free(res.valor);
    }
    return nuevoValorResultadoVacio();
}

// Constructor para el nodo Instrucciones
AbstractExpresion *nuevoInstruccionesExpresion()
{
    // Crear un nuevo nodo de instrucciones
    InstruccionesExpresion *nodo = malloc(sizeof(InstruccionesExpresion));
    if (!nodo)
        return NULL;
    // Inicializar la estructura base
    buildAbstractExpresion(&nodo->base, interpretInstruccionesExpresion, "Instrucciones", 0, 0);
    nodo->base.generar = generarInstruccionesExpresion;

    return (AbstractExpresion *)nodo;
}
