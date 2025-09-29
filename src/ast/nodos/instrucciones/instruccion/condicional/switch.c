#include "switch.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Función auxiliar para comparar dos resultados
int son_iguales(Result r1, Result r2)
{
    if (r1.tipo != r2.tipo)
        return 0;

    switch (r1.tipo)
    {
    case INT:
    case CHAR:
    case BOOLEAN:
        return *(int *)r1.valor == *(int *)r2.valor;
    case STRING:
        // Comparamos el contenido de los strings
        return strcmp((char *)r1.valor, (char *)r2.valor) == 0;
    default:
        return 0;
    }
}

// La función que interpreta una instrucción switch
Result interpretSwitchExpresion(AbstractExpresion *self, Context *context)
{
    // Evaluar la expresión del switch                  [    [0] para obtener inicio memoria
    Result switch_val = self->hijos[0]->interpret(self->hijos[0], context);

    // Verificar si hubo un error semántico
    if (has_semantic_error_been_found())
    {
        char description[256];
        snprintf(description, sizeof(description), "Error al evaluar la expresión del switch.");
        add_error_to_report("Semántico", "switch", description, self->line, self->column, context->nombre_completo);
        free(switch_val.valor);
        return nuevoValorResultadoVacio();
    }

    // Obtener la lista de casos y el caso por defecto
    AbstractExpresion *case_list = self->hijos[1];
    int case_encontrado_idx = -1;
    AbstractExpresion *default_case = NULL;
    Result resultado_final = nuevoValorResultadoVacio();

    // Buscar el primer 'case' que coincida
    for (size_t i = 0; i < case_list->numHijos; i++)
    {
        // Si es un 'default', lo guardamos para después
        AbstractExpresion *caso = case_list->hijos[i];

        // Si es un 'default', lo guardamos para después
        if (strcmp(caso->node_type, "DefaultCase") == 0)
        {
            default_case = caso;
            continue;
        }

        // Si es un case normalito, lo comparo
        Result case_val = caso->hijos[0]->interpret(caso->hijos[0], context);
        if (son_iguales(switch_val, case_val))
        {
            case_encontrado_idx = i;
            free(case_val.valor);
            break;
        }
        free(case_val.valor);
    }

    free(switch_val.valor);

    // Decidir desde dónde empezar a ejecutar
    int inicio_ejecucion = -1;

    // Si encontramos un case coincidente, empezamos desde ahí
    if (case_encontrado_idx != -1)
    {
        inicio_ejecucion = case_encontrado_idx;

        // Si no, pero hay un default, empezamos desde el default
    }
    else if (default_case != NULL)
    {
        for (size_t i = 0; i < case_list->numHijos; i++)
        {
            if (case_list->hijos[i] == default_case)
            {
                inicio_ejecucion = i;
                break;
            }
        }
    }

    // Si hay un punto de inicio, ejecutamos desde ahí hasta el final
    if (inicio_ejecucion != -1)
    {
        // Marcar región 'breakable' (pero no 'continuable') y recordar nivel inicial
        int before_depth = context ? context->breakable_depth : 0;
        if (context)
            context->breakable_depth = before_depth + 1;

        for (size_t i = inicio_ejecucion; i < case_list->numHijos; i++)
        {
            AbstractExpresion *caso_a_ejecutar = case_list->hijos[i];
            AbstractExpresion *sentencias = NULL;

            // Comprobamos si el nodo tiene sentencias antes de acceder a ellas
            if (strcmp(caso_a_ejecutar->node_type, "DefaultCase") == 0)
            {
                if (caso_a_ejecutar->numHijos > 0)
                    sentencias = caso_a_ejecutar->hijos[0];
            }
            else
            { // Es un nodo "Case"
                if (caso_a_ejecutar->numHijos > 1)
                    sentencias = caso_a_ejecutar->hijos[1];
            }

            // Si hay sentencias, las ejecutamos
            if (sentencias)
            {
                Result res_sentencia = sentencias->interpret(sentencias, context);
                if (res_sentencia.tipo == BREAK_T)
                {
                    // Salir del switch: restaurar nivel de profundidad a como estaba antes de entrar
                    if (context)
                        context->breakable_depth = before_depth;
                    break;
                }
                if (res_sentencia.tipo == CONTINUE_T || res_sentencia.tipo == RETURN_T)
                {
                    resultado_final = res_sentencia;
                    if (context)
                        context->breakable_depth = before_depth;
                    break;
                }
            }
            // Si 'sentencias' es NULL continuamos al siguiente case.
        }

        // Si terminamos sin break/return/continue explícito, restaurar al nivel previo
        if (context)
            context->breakable_depth = before_depth;
    }
    return resultado_final;
}

// El constructor para el nodo de instrucción switch
AbstractExpresion *nuevoSwitchExpresion(AbstractExpresion *expr, AbstractExpresion *case_list, int line, int column)
{
    SwitchExpresion *nodo = malloc(sizeof(SwitchExpresion));
    buildAbstractExpresion(&nodo->base, interpretSwitchExpresion, "SwitchStatement", line, column);
    agregarHijo((AbstractExpresion *)nodo, expr);
    agregarHijo((AbstractExpresion *)nodo, case_list);
    return (AbstractExpresion *)nodo;
}