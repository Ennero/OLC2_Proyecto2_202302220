#include "print.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/result.h"
#include "error_reporter.h"
#include "compilacion/generador_codigo.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "utils/java_num_format.h"

static size_t utf8_encode_cp(int cp, char *out)
{
    if (cp <= 0x7F)
    {
        out[0] = (char)cp;
        return 1;
    }
    else if (cp <= 0x7FF)
    {
        out[0] = (char)(0xC0 | ((cp >> 6) & 0x1F));
        out[1] = (char)(0x80 | (cp & 0x3F));
        return 2;
    }
    else if (cp <= 0xFFFF)
    {
        out[0] = (char)(0xE0 | ((cp >> 12) & 0x0F));
        out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[2] = (char)(0x80 | (cp & 0x3F));
        return 3;
    }
    else
    {
        out[0] = (char)(0xF0 | ((cp >> 18) & 0x07));
        out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
        out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[3] = (char)(0x80 | (cp & 0x3F));
        return 4;
    }
}

static void limpiar_cache_literals(PrintExpresion *nodo)
{
    if (!nodo)
        return;

    for (size_t i = 0; i < nodo->literal_count; ++i)
    {
        free(nodo->literal_cache ? nodo->literal_cache[i] : NULL);
    }

    if (nodo->literal_cache)
    {
        memset(nodo->literal_cache, 0, sizeof(char *) * nodo->literal_capacity);
    }

    nodo->literal_count = 0;
}

static bool asegurar_capacidad_literals(PrintExpresion *nodo, size_t requerida)
{
    if (!nodo)
        return false;

    if (requerida <= nodo->literal_capacity)
        return true;

    size_t nueva_capacidad = nodo->literal_capacity ? nodo->literal_capacity : 4;
    while (nueva_capacidad < requerida)
    {
        nueva_capacidad *= 2;
    }

    char **nueva_memoria = realloc(nodo->literal_cache, nueva_capacidad * sizeof(char *));
    if (!nueva_memoria)
        return false;

    // Inicializar nuevo espacio a NULL
    for (size_t i = nodo->literal_capacity; i < nueva_capacidad; ++i)
    {
        nueva_memoria[i] = NULL;
    }

    nodo->literal_cache = nueva_memoria;
    nodo->literal_capacity = nueva_capacidad;
    return true;
}

static bool agregar_literal_cache(PrintExpresion *nodo, char *texto)
{
    if (!nodo)
        return false;

    if (!asegurar_capacidad_literals(nodo, nodo->literal_count + 1))
    {
        free(texto);
        return false;
    }

    nodo->literal_cache[nodo->literal_count++] = texto;
    return true;
}

static void destruir_literal_cache(PrintExpresion *nodo)
{
    if (!nodo)
        return;

    limpiar_cache_literals(nodo);
    free(nodo->literal_cache);
    nodo->literal_cache = NULL;
    nodo->literal_capacity = 0;
    nodo->literal_count = 0;
}

static void liberarPrintExpresion(AbstractExpresion *self)
{
    if (!self)
        return;

    destruir_literal_cache((PrintExpresion *)self);
}

static char *formatear_resultado_para_literal(const Result *resultado)
{
    if (!resultado)
        return NULL;

    switch (resultado->tipo)
    {
    case INT:
    {
        int valor = resultado->valor ? *((int *)resultado->valor) : 0;
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%d", valor);
        return strdup(buffer);
    }
    case FLOAT:
    {
        float valor = resultado->valor ? *((float *)resultado->valor) : 0.0f;
        char buffer[64];
        java_format_float(valor, buffer, sizeof(buffer));
        return strdup(buffer);
    }
    case DOUBLE:
    {
        double valor = resultado->valor ? *((double *)resultado->valor) : 0.0;
        char buffer[64];
        java_format_double(valor, buffer, sizeof(buffer));
        return strdup(buffer);
    }
    case BOOLEAN:
    {
        int valor = resultado->valor ? *((int *)resultado->valor) : 0;
        return strdup(valor ? "true" : "false");
    }
    case CHAR:
    {
        int cp = resultado->valor ? *((int *)resultado->valor) : 0;
        char buffer[8];
        size_t bytes = utf8_encode_cp(cp, buffer);
        buffer[bytes] = '\0';
        return strdup(buffer);
    }
    case STRING:
    {
        const char *texto = resultado->valor ? (const char *)resultado->valor : "";
        return strdup(texto);
    }
    case NULO:
        return strdup("null");
    default:
        break;
    }

    return NULL;
}

// La función que interpreta una instrucción de impresión
Result interpretPrintExpresion(AbstractExpresion *self, Context *context)
{
    PrintExpresion *nodo = (PrintExpresion *)self;
    limpiar_cache_literals(nodo);

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

        char *literal = formatear_resultado_para_literal(&res);
        agregar_literal_cache(nodo, literal);

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

    PrintExpresion *nodo = (PrintExpresion *)self;
    AbstractExpresion *listaExpresiones = self->hijos[0];
    if (!listaExpresiones)
        return NULL;

    for (size_t i = 0; i < listaExpresiones->numHijos; ++i)
    {
        AbstractExpresion *expr = listaExpresiones->hijos[i];
        if (!expr)
            continue;

        const char *operador = expr->generar ? expr->generar(expr, generador, context) : NULL;
        if (!operador && nodo && i < nodo->literal_count)
        {
            const char *texto = nodo->literal_cache ? nodo->literal_cache[i] : NULL;
            if (texto)
            {
                operador = registrar_literal_cadena(generador, texto);
            }
        }
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
    nodo->literal_cache = NULL;
    nodo->literal_count = 0;
    nodo->literal_capacity = 0;
    buildAbstractExpresion(&nodo->base, interpretPrintExpresion, "Print", line, column);
    nodo->base.generar = generarPrintExpresion;
    nodo->base.cleanup = liberarPrintExpresion;

    if (listaExpresiones)
        agregarHijo((AbstractExpresion *)nodo, listaExpresiones);
    return (AbstractExpresion *)nodo;
}
