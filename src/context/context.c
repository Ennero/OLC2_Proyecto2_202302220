// Implementacion del sistema de contextos (ambitos) y gestion de simbolos
#include "context.h"
#include "symbol_reporter.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "array_value.h"

// Crea un contexto (ambito). Si 'anterior' es NULL, se asume contexto global.
Context *nuevoContext(Context *anterior, const char *nombre_contexto)
{
    Context *nuevo = malloc(sizeof(Context));
    if (!nuevo)
        return NULL;

    // Inicializar campos
    nuevo->anterior = anterior;
    nuevo->ultimoSymbol = NULL;

    // Logica para el puntero raiz y el contador
    if (anterior)
    {
        nuevo->raiz = anterior->raiz;
        // Heredar contadores de control
        nuevo->breakable_depth = anterior->breakable_depth;
        nuevo->continuable_depth = anterior->continuable_depth;
    }
    else
    {
        nuevo->raiz = nuevo;
        nuevo->proximo_id_bloque = 1;
        // Inicializar contadores de control
        nuevo->breakable_depth = 0;
        nuevo->continuable_depth = 0;
    }
    // Construir nombre completo del contexto
    if (anterior && anterior->nombre_completo)
    {

        // Calcular el tamaño necesario para el nuevo nombre
        size_t len_padre = strlen(anterior->nombre_completo);
        size_t len_nuevo = strlen(nombre_contexto);

        // Reservar la memoria
        nuevo->nombre_completo = malloc(len_padre + len_nuevo + 2); // +2 para '_' y '\0'

        // Escribir en la memoria reservada
        if (nuevo->nombre_completo)
        {
            sprintf(nuevo->nombre_completo, "%s_%s", anterior->nombre_completo, nombre_contexto);
        }
    }
    else
    {
        // Para el contexto global, strdup ya reserva la memoria
        nuevo->nombre_completo = strdup(nombre_contexto);
    }

    return nuevo;
}

// Libera un contexto y todos sus simbolos asociados (variables y funciones)
void liberarContext(Context *context)
{
    if (!context)
        return;

    // Liberar todos los simbolos en este contexto
    Symbol *actual = context->ultimoSymbol;
    while (actual)
    {
        Symbol *temp = actual->anterior;

        // Si el simbolo es una VARIABLE, liberar su valor si no es prestado
        if (actual->clase == VARIABLE)
        {
            // No liberar si es un alias a otra variable o si es prestado
            if (!actual->info.var.borrowed && actual->info.var.alias_of == NULL)
            {
                if (actual->tipo == ARRAY && actual->info.var.valor != NULL)
                {
#ifdef DEBUG_MEM
                    fprintf(stderr, "[DEBUG free] liberarContext: liberarArray %p (sym=%s)\n", actual->info.var.valor, actual->nombre);
#endif
                    liberarArray((ArrayValue *)actual->info.var.valor);
                }
                else if (actual->info.var.valor != NULL)
                {
#ifdef DEBUG_MEM
                    fprintf(stderr, "[DEBUG free] liberarContext: free %p (sym=%s tipo=%s)\n", actual->info.var.valor, actual->nombre, labelTipoDato[actual->tipo]);
#endif
                    free(actual->info.var.valor);
                }
            }
        }

        // Si el simbolo es una FUNCION, liberar los nombres de sus parametros
        if (actual->clase == FUNCION)
        {
            for (size_t i = 0; i < actual->info.func.num_parametros; i++)
            {
                free(actual->info.func.parametros[i].nombre);
            }
            free(actual->info.func.parametros);
        }

        // Liberar el nombre del simbolo y la estructura Symbol
        free(actual->nombre);
        free(actual);
        actual = temp;
    }

    free(context->nombre_completo);
    free(context);
}

// Crea un simbolo de variable
Symbol *nuevoVariable(char *nombre, void *valor, TipoDato tipo, int es_constante)
{
    Symbol *nuevo = malloc(sizeof(Symbol));
    if (!nuevo)
        return NULL;
    // Duplicar el nombre para que el AST y la tabla de simbolos no compartan memoria.
    // Evita usar punteros liberados cuando el mismo nodo AST se re-ejecuta (por ejemplo, en for anidados).
    nuevo->nombre = strdup(nombre);
    nuevo->tipo = tipo;
    nuevo->clase = VARIABLE;
    nuevo->info.var.valor = valor;
    nuevo->info.var.borrowed = 0;
    nuevo->info.var.alias_of = NULL;
    nuevo->es_constante = es_constante;
    nuevo->line = 0;
    nuevo->column = 0;
    nuevo->anterior = NULL;
    return nuevo;
}

// Busca un simbolo en la lista enlazada del ambito actual
Symbol *buscarSymbol(Symbol *actual, char *nombre)
{
    while (actual)
    {
        if (strcmp(actual->nombre, nombre) == 0)
        {
            return actual;
        }
        actual = actual->anterior;
    }
    return NULL;
}

// Busca un simbolo en el contexto actual y en los anteriores (encadenamiento de ambitos)
Symbol *buscarTablaSimbolos(Context *actual, char *nombre)
{
    while (actual)
    {
        Symbol *symbolEncontrado = buscarSymbol(actual->ultimoSymbol, nombre);
        if (symbolEncontrado)
        {
            return symbolEncontrado;
        }
        actual = actual->anterior;
    }
    return NULL;
}

// Inserta un simbolo en el contexto actual; reporta y rechaza duplicados en el mismo ambito
void agregarSymbol(Context *actual, Symbol *symbol, int line, int column)
{

    // buscarSymbol solo busca en el ambito (contexto) actual.
    if (buscarSymbol(actual->ultimoSymbol, symbol->nombre))
    {
        char description[256];
        if (symbol->clase == FUNCION)
        {
            snprintf(description, sizeof(description), "La funcion '%s' ya ha sido declarada en este ambito.", symbol->nombre);
        }
        else
        {
            snprintf(description, sizeof(description), "La variable '%s' ya ha sido declarada en este ambito.", symbol->nombre);
        }

        // Reporte de error semantico formal.
        add_error_to_report("Semantico", symbol->nombre, description, line, column, actual->nombre_completo);

        // Liberar memoria del símbolo rechazado según su clase
        if (symbol->clase == VARIABLE)
        {
            if (symbol->info.var.valor)
            {
                if (symbol->tipo == ARRAY)
                {
                    liberarArray((ArrayValue *)symbol->info.var.valor);
                }
                else
                {
                    free(symbol->info.var.valor);
                }
            }

            // Liberar el nombre del símbolo
        }
        else if (symbol->clase == FUNCION)
        {
            // Liberar parametros alocados y sus nombres
            if (symbol->info.func.parametros)
            {
                for (size_t i = 0; i < symbol->info.func.num_parametros; i++)
                {
                    free(symbol->info.func.parametros[i].nombre);
                }
                free(symbol->info.func.parametros);
            }
        }
        free(symbol->nombre);
        free(symbol);
        return;
    }

    // Asignar linea y columna para reportes futuros
    symbol->line = line;
    symbol->column = column;

    // Añadir el símbolo al reporte de símbolos
    add_symbol_to_report(symbol, actual->nombre_completo);

    // Insertar al inicio de la lista enlazada
    symbol->anterior = actual->ultimoSymbol;
    actual->ultimoSymbol = symbol;
}
