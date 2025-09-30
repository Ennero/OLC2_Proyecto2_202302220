#include "llamada.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/array_value.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Función auxiliar para obtener el tamaño en bytes de un tipo base
static size_t get_type_size(TipoDato tipo)
{
    switch (tipo)
    {
    case INT:
    case BOOLEAN:
    case CHAR:
        return sizeof(int);
    case FLOAT:
        return sizeof(float);
    case DOUBLE:
        return sizeof(double);
    default:
        return 0; // STRING es un puntero; se maneja diferente
    }
}

// Función de interpretación para el nodo LlamadaFuncion
Result interpretLlamadaFuncion(AbstractExpresion *self, Context *context)
{
    LlamadaFuncionNode *nodo = (LlamadaFuncionNode *)self;
    char *nombre_func = nodo->nombre;
    // El primer hijo (si existe) es la lista de argumentos
    AbstractExpresion *argumentos_nodo = (self->numHijos > 0) ? self->hijos[0] : NULL;

    // Buscar la función en la tabla de símbolos
    Symbol *func_symbol = buscarTablaSimbolos(context, nombre_func);

    // Si no es función o no existe, error
    if (!func_symbol || func_symbol->clase != FUNCION)
    {
        char desc[100];
        sprintf(desc, "La función '%s' no ha sido declarada.", nombre_func);
        add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Validar número de argumentos
    size_t num_args = argumentos_nodo ? argumentos_nodo->numHijos : 0;
    if (num_args != func_symbol->info.func.num_parametros)
    {
        char desc[160];
        sprintf(desc, "La funcion '%s' esperaba %zu argumentos, pero recibio %zu.",
                nombre_func, func_symbol->info.func.num_parametros, num_args);
        add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Evaluar los argumentos
    Result *argumentos_evaluados = malloc(sizeof(Result) * num_args);
    for (size_t i = 0; i < num_args; i++)
    {
        argumentos_evaluados[i] = argumentos_nodo->hijos[i]->interpret(argumentos_nodo->hijos[i], context);
    }

    // Crear un nuevo contexto para la función
    Context *func_context = nuevoContext(context, nombre_func);
    int has_param_error = 0;

    // Enlazar argumentos a parámetros en el contexto de la función
    for (size_t i = 0; i < num_args; i++)
    {
        // Obtener el parámetro correspondiente
        Parametro param = func_symbol->info.func.parametros[i];
        Result arg = argumentos_evaluados[i];

        // Validacion de tipos de parametro
        if (param.dimensiones == 0) // Si no tiene dimensiones, es escalar (primitivo o string)
        {
            // Permitir widening implícito en escalares numéricos
            if (param.tipo != arg.tipo)
            {
                // Caso especial: permitir int -> char
                if (param.tipo == CHAR && arg.tipo == INT)
                {
                    int *p = malloc(sizeof(int));
                    *p = (int)((unsigned char)(*(int *)arg.valor));
                    free(arg.valor);
                    arg.valor = p;
                    arg.tipo = CHAR;
                    argumentos_evaluados[i] = arg;
                }
                else if (can_widen(arg.tipo, param.tipo))
                {
                    // Convertir el argumento al tipo del parámetro
                    argumentos_evaluados[i] = widen_to(arg, param.tipo);
                    arg = argumentos_evaluados[i];
                }
                else
                {
                    char desc[200];
                    sprintf(desc, "Tipo de argumento %zu incompatible: se esperaba %s y se recibio %s.",
                            i + 1, labelTipoDato[param.tipo], labelTipoDato[arg.tipo]);
                    add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);
                    has_param_error = 1;
                }
            }
        }
        // Ahora si el parámetro es arreglo
        else
        {
            // Si el argumento no es un arreglo, error
            if (arg.tipo != ARRAY)
            {
                char desc[200];
                sprintf(desc, "Tipo de argumento %zu incompatible: se esperaba arreglo de %s y se recibio %s.",
                        i + 1, labelTipoDato[param.tipo], labelTipoDato[arg.tipo]);
                add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);
                has_param_error = 1;
            }
            // Ahora si sí es arreglo, validar tipo base y dimensiones
            else
            {
                // Extraer info del arreglo
                ArrayValue *av = (ArrayValue *)arg.valor;

                // Si no coincide tipo base o dimensiones, error
                if (av->tipo_elemento_base != param.tipo || av->dimensiones_total != param.dimensiones)
                {
                    char desc[240];
                    sprintf(desc, "Dimensiones/tipo base incompatibles en argumento %zu: esperado %s[%dD], recibido %s[%dD].",
                            i + 1, labelTipoDato[param.tipo], param.dimensiones,
                            labelTipoDato[av->tipo_elemento_base], av->dimensiones_total);
                    add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);
                    has_param_error = 1;
                }
            }
        }

        // Enlace del argumento al contexto de la funcion
        void *valor_bind = NULL;
        TipoDato tipo_variable = (param.dimensiones == 0) ? param.tipo : ARRAY;
        Symbol *sym_param = NULL;

        // Reglas:
        // - Arreglos: por referencia (borrowed)
        // - String: si el argumento es un identificador del llamador -> alias; si es expresión temporal -> copia
        // - Primitivos: copia por valor
        if (tipo_variable == ARRAY)
        {
            valor_bind = arg.valor; // por referencia
            sym_param = nuevoVariable(param.nombre, valor_bind, tipo_variable, 0);
            sym_param->info.var.borrowed = 1; // no liberar en el contexto de la funcion
        }
        else if (tipo_variable == STRING)
        {
            // Intentar detectar si el argumento fue un Identificador (para aliasing)
            // Si el nodo de argumento es un Identificador, hacemos alias al símbolo del llamador
            Symbol *caller_sym = NULL;
            if (argumentos_nodo && i < argumentos_nodo->numHijos && argumentos_nodo->hijos[i] &&
                strcmp(argumentos_nodo->hijos[i]->node_type, "Identificador") == 0)
            {
                char *nombre_id = ((IdentificadorExpresion *)argumentos_nodo->hijos[i])->nombre;
                caller_sym = buscarTablaSimbolos(context, nombre_id);
            }

            if (caller_sym && caller_sym->clase == VARIABLE && caller_sym->tipo == STRING)
            {
                // Resolver alias en cadena hasta el dueño real
                Symbol *owner = caller_sym;
                while (owner->clase == VARIABLE && owner->info.var.alias_of != NULL)
                {
                    owner = owner->info.var.alias_of;
                }
                // Crear símbolo parámetro sin ser dueño del valor y marcando alias_of al dueño real
                sym_param = nuevoVariable(param.nombre, owner->info.var.valor, tipo_variable, 0);
                sym_param->info.var.alias_of = owner;
            }
            else
            {
                // Si no es identificador o no es variable STRING, hacer copia del string
                valor_bind = arg.valor ? strdup((char *)arg.valor) : NULL;
                sym_param = nuevoVariable(param.nombre, valor_bind, tipo_variable, 0);
            }
        }
        else
        {
            // Primitivos: copia por valor
            size_t size = get_type_size(param.tipo);
            valor_bind = malloc(size);
            memcpy(valor_bind, arg.valor, size);
            sym_param = nuevoVariable(param.nombre, valor_bind, tipo_variable, 0);
        }
        // Agregar el símbolo al contexto de la función
        agregarSymbol(func_context, sym_param, 0, 0);
    }

    // Liberar los resultados de los argumentos (si no son arreglos, que se pasan por referencia)
    for (size_t i = 0; i < num_args; i++)
    {
        // Liberar temporales de argumentos evaluados que sean copias
        if (argumentos_evaluados[i].tipo == ARRAY)
        {
            // No liberar: el arreglo pertenece al llamador o al heap; el parámetro es borrowed
        }
        else if (argumentos_evaluados[i].tipo == STRING)
        {
            // Si creamos alias para STRING, no duplicamos; pero 'argumentos_evaluados' contiene copia desde el identificador
            // interpretIdentificador duplica el string, así que podemos liberar aquí sin afectar al llamador
            if (argumentos_evaluados[i].valor)
                free(argumentos_evaluados[i].valor);
        }
        else
        {
            if (argumentos_evaluados[i].valor)
                free(argumentos_evaluados[i].valor);
        }
    }
    free(argumentos_evaluados);

    // Si se detectaron errores en los parametros, abortar la llamada
    if (has_param_error)
    {
        liberarContext(func_context);
        return nuevoValorResultadoVacio();
    }

    // Ejecutar el cuerpo de la función
    Result res_cuerpo = func_symbol->info.func.cuerpo->interpret(func_symbol->info.func.cuerpo, func_context);

    // Si la función retornó algo, validar tipo de retorno
    if (res_cuerpo.tipo == RETURN_T)
    {
        // Extraer el resultado real del puntero
        Result *res_final_ptr = (Result *)res_cuerpo.valor;
        Result res_final = *res_final_ptr;
        free(res_final_ptr);

        // Validar tipo de retorno
        if (func_symbol->info.func.tipo_retorno == NULO)
        {
            // Funcion void
            if (res_final.tipo != NULO)
            {
                char desc[160];
                sprintf(desc, "La funcion void '%s' no debe retornar un valor.", nombre_func);
                add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);
                // descartamos el valor retornado para mantener consistencia
                free(res_final.valor);
                liberarContext(func_context);
                return nuevoValorResultadoVacio();
            }
            liberarContext(func_context);
            return nuevoValorResultadoVacio();
        }
        else
        {
            // Verificación de tipo de retorno considerando arreglos
            int ret_dims = func_symbol->info.func.retorno_dimensiones;
            if (ret_dims == 0)
            {
                // Permitir widening implícito del retorno escalar
                TipoDato esperado = func_symbol->info.func.tipo_retorno;
                if (res_final.tipo != esperado)
                {
                    // Caso especial: permitir int -> char en retorno
                    if (esperado == CHAR && res_final.tipo == INT)
                    {
                        int *p = malloc(sizeof(int));
                        *p = (int)((unsigned char)(*(int *)res_final.valor));
                        free(res_final.valor);
                        res_final.valor = p;
                        res_final.tipo = CHAR;
                    }
                    else if (can_widen(res_final.tipo, esperado))
                    {
                        res_final = widen_to(res_final, esperado);
                    }
                    else
                    {
                        char desc[200];
                        sprintf(desc, "Tipo de retorno incompatible en '%s': se esperaba %s y se recibio %s.",
                                nombre_func,
                                labelTipoDato[esperado],
                                labelTipoDato[res_final.tipo]);
                        add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);
                        if (res_final.valor)
                        {
                            free(res_final.valor);
                        }
                        liberarContext(func_context);
                        return nuevoValorResultadoVacio();
                    }
                }
                liberarContext(func_context);
                return res_final;
            }
            else
            {
                // Esperamos un arreglo de base 'tipo_retorno' y dimensiones 'ret_dims'
                if (res_final.tipo != ARRAY)
                {
                    char desc[200];
                    sprintf(desc, "Tipo de retorno incompatible en '%s': se esperaba arreglo de %s y se recibio %s.",
                            nombre_func, labelTipoDato[func_symbol->info.func.tipo_retorno], labelTipoDato[res_final.tipo]);
                    add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);

                    // liberar si corresponde
                    if (res_final.tipo != ARRAY && res_final.valor)
                        free(res_final.valor);
                    liberarContext(func_context);
                    return nuevoValorResultadoVacio();
                }

                // Validar tipo base y dimensiones del arreglo retornado
                ArrayValue *av = (ArrayValue *)res_final.valor;
                // Si no coincide tipo base o dimensiones, error
                if (!av || av->tipo_elemento_base != func_symbol->info.func.tipo_retorno || av->dimensiones_total != ret_dims)
                {
                    char desc[240];
                    sprintf(desc, "Tipo de retorno incompatible en '%s': esperado %s[%dD], recibido %s[%dD].",
                            nombre_func,
                            labelTipoDato[func_symbol->info.func.tipo_retorno], ret_dims,
                            av ? labelTipoDato[av->tipo_elemento_base] : "?",
                            av ? av->dimensiones_total : -1);

                    // Reportar error
                    add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);
                    int owned_by_context_err = 0;

                    // Ver si el arreglo pertenece a una variable del contexto de la función
                    if (res_final.valor != NULL)
                    {
                        for (Symbol *s = func_context->ultimoSymbol; s != NULL; s = s->anterior)
                        {
                            if (s->clase == VARIABLE && s->tipo == ARRAY && s->info.var.valor == res_final.valor)
                            {
                                owned_by_context_err = 1;
                                break;
                            }
                        }
                    }
                    // Liberar si no pertenece al contexto de la función
                    if (!owned_by_context_err && av)
                    {
                        liberarArray(av);
                    }
                    liberarContext(func_context);
                    return nuevoValorResultadoVacio();
                }
                // Si el arreglo retornado es una variable del contexto de la función toca devolver una copia profunda para evitar use-after-free
                int owned_by_context = 0;
                if (res_final.valor != NULL)
                {
                    // Ver si el arreglo pertenece a una variable del contexto de la función
                    for (Symbol *s = func_context->ultimoSymbol; s != NULL; s = s->anterior)
                    {
                        // Si encontramos el símbolo y su valor es el arreglo retornado
                        if (s->clase == VARIABLE && s->tipo == ARRAY && s->info.var.valor == res_final.valor)
                        {
                            owned_by_context = 1;
                            break;
                        }
                    }
                }

                // Si pertenece al contexto de la función, hacemos una copia profunda para devolver
                if (owned_by_context)
                {
                    ArrayValue *copia = copiarArray(av);
                    // El original será liberado al liberar el contexto de la función
                    liberarContext(func_context);
                    return nuevoValorResultado(copia, ARRAY);
                }
                else
                {
                    // Transferimos ownership del temporal al llamador
                    liberarContext(func_context);
                    return res_final;
                }
            }
        }
    }

    // Si la funcion no tuvo return:
    // Si es void (NULO), esta bien y devuelve vacio;
    if (func_symbol->info.func.tipo_retorno == NULO)
    {
        liberarContext(func_context);
        return nuevoValorResultadoVacio();
    }
    // Si no es void, reportamos error de falta de retorno.
    else
    {
        char desc[160];
        sprintf(desc, "La funcion '%s' debe retornar un valor de tipo %s.", nombre_func, labelTipoDato[func_symbol->info.func.tipo_retorno]);
        add_error_to_report("Semantico", nombre_func, desc, self->line, self->column, context->nombre_completo);
        liberarContext(func_context);
        return nuevoValorResultadoVacio();
    }
}

// Constructor del nodo LlamadaFuncion
AbstractExpresion *nuevoLlamadaFuncion(char *nombre, AbstractExpresion *args, int line, int column)
{
    LlamadaFuncionNode *nodo = malloc(sizeof(LlamadaFuncionNode));
    buildAbstractExpresion(&nodo->base, interpretLlamadaFuncion, "FunctionCall", line, column);
    nodo->nombre = nombre;
    if (args)
    {
        agregarHijo((AbstractExpresion *)nodo, args);
    }
    return (AbstractExpresion *)nodo;
}