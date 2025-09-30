#include "primitivos.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/result.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "compilacion/generador_codigo.h"
#include "utils/java_num_format.h"

static size_t utf8_encode_cp(int cp, char *out);
static int parse_unicode_escape_decimal(const char *digits, size_t maxlen);
static char *process_string_escapes(const char *input);
static int parse_char_literal(const char *literal);
static void normalizar_literal(const char *origen, char *destino, size_t tamano, const char *sufijos_finales);

// La función que interpreta un valor primitivo
static const char *generarPrimitivoExpresion(AbstractExpresion *self, GeneradorCodigo *generador, Context *context)
{
    (void)context;
    if (!self || !generador)
        return NULL;

    PrimitivoExpresion *nodo = (PrimitivoExpresion *)self;

    // Manejo especial para literales de cadena
    switch (nodo->tipo)
    {
    case STRING:
    {
        char *contenido = process_string_escapes(nodo->valor);
        const char *etiqueta = registrar_literal_cadena(generador, contenido ? contenido : "");
        free(contenido);
        return etiqueta;
    }
    case INT:
    {
        char normalizado[256];
        normalizar_literal(nodo->valor, normalizado, sizeof(normalizado), NULL);
        char *endptr = NULL;
        long valor = strtol(normalizado, &endptr, 0);
        if (endptr && *endptr != '\0')
        {
            return registrar_literal_cadena(generador, nodo->valor);
        }

        char buffer[64];
        snprintf(buffer, sizeof(buffer), "%ld", valor);
        return registrar_literal_cadena(generador, buffer);
    }
    case DOUBLE:
    {
        char buffer[256];
        char normalizado[256];
        normalizar_literal(nodo->valor, normalizado, sizeof(normalizado), "fFdD");
        char *endptr = NULL;
        double valor = strtod(normalizado, &endptr);
        if (endptr && *endptr != '\0')
        {
            return registrar_literal_cadena(generador, nodo->valor);
        }
        java_format_double(valor, buffer, sizeof(buffer));
        return registrar_literal_cadena(generador, buffer);
    }
    case FLOAT:
    {
        char buffer[256];
        char normalizado[256];
        normalizar_literal(nodo->valor, normalizado, sizeof(normalizado), "fF");
        char *endptr = NULL;
        float valor = strtof(normalizado, &endptr);
        if (endptr && *endptr != '\0')
        {
            return registrar_literal_cadena(generador, nodo->valor);
        }
        java_format_float(valor, buffer, sizeof(buffer));
        return registrar_literal_cadena(generador, buffer);
    }
    case BOOLEAN:
        return registrar_literal_cadena(generador, (strcmp(nodo->valor, "true") == 0) ? "true" : "false");
    case CHAR:
    {
        int cp = parse_char_literal(nodo->valor);
        char buffer[8];
        size_t bytes = utf8_encode_cp(cp, buffer);
        buffer[bytes] = '\0';
        return registrar_literal_cadena(generador, buffer);
    }
    case NULO:
        return registrar_literal_cadena(generador, "null");
    default:
        break;
    }

    return NULL;
}

// Codifica un code point Unicode en UTF-8
static size_t utf8_encode_cp(int cp, char *out)
{

    // Si el code point es inválido, devolvemos el carácter de reemplazo U+FFFD
    if (cp <= 0x7F)
    {
        out[0] = (char)cp;
        return 1;
    }

    // Codificación UTF-8 de 2 bytes
    else if (cp <= 0x7FF)
    {
        out[0] = (char)(0xC0 | ((cp >> 6) & 0x1F));
        out[1] = (char)(0x80 | (cp & 0x3F));
        return 2;
    }

    // Codificación UTF-8 de 3 bytes
    else if (cp <= 0xFFFF)
    {
        out[0] = (char)(0xE0 | ((cp >> 12) & 0x0F));
        out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[2] = (char)(0x80 | (cp & 0x3F));
        return 3;
    }

    // Codificación UTF-8 de 4 bytes
    else
    {
        out[0] = (char)(0xF0 | ((cp >> 18) & 0x07));
        out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
        out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[3] = (char)(0x80 | (cp & 0x3F));
        return 4;
    }
}

// Función auxiliar para convertir secuencias de escape Unicode decimal
static int parse_unicode_escape_decimal(const char *digits, size_t maxlen)
{
    // Copiar hasta 5 dígitos o hasta maxlen disponible
    size_t n = 0;
    while (n < maxlen && n < 5 && digits[n] >= '0' && digits[n] <= '9')
        n++;
    char buf[6];
    if (n == 0)
        return 0; // sin dígitos válidos
    memcpy(buf, digits, n);
    buf[n] = '\0';
    long val = strtol(buf, NULL, 10);
    if (val < 0)
        val = 0;
    if (val > 0x10FFFF)
        val = 0x10FFFF;
    return (int)val;
}

// Normaliza literales numéricos eliminando guiones bajos y sufijos finales opcionales
static void normalizar_literal(const char *origen, char *destino, size_t tamano, const char *sufijos_finales)
{
    if (!destino || tamano == 0)
        return;

    destino[0] = '\0';
    if (!origen)
        return;

    size_t j = 0;
    for (size_t i = 0; origen[i] != '\0' && j + 1 < tamano; ++i)
    {
        char c = origen[i];
        if (c == '_')
            continue;

        if (sufijos_finales && sufijos_finales[0] != '\0' && strchr(sufijos_finales, c) && origen[i + 1] == '\0')
            continue;

        destino[j++] = c;
    }
    destino[j] = '\0';
}

// Función auxiliar para procesar las secuencias de escape en cadenas y devolver UTF-8 válido
static char *process_string_escapes(const char *input)
{
    size_t len = strlen(input);
    // Reservamos len*4 + 1 (peor caso UTF-8
    char *output = malloc(len * 4 + 1);
    if (!output)
        return NULL;

    size_t i = 0, j = 0;

    // Procesar cada carácter
    while (i < len)
    {
        if (input[i] == '\\' && i + 1 < len)
        {
            i++;
            switch (input[i])
            {
            case 'n':
                output[j++] = '\n';
                break;
            case 't':
                output[j++] = '\t';
                break;
            case 'r':
                output[j++] = '\r';
                break;
            case '\\':
                output[j++] = '\\';
                break;
            case '\"':
                output[j++] = '\"';
                break;
            case '\'':
                output[j++] = '\'';
                break;
            case 'u':
            {
                // Leer de 1 a 5 dígitos decimales
                size_t remain = len - (i + 1);
                int unicode_val = parse_unicode_escape_decimal(&input[i + 1], remain);
                // Codificar como UTF-8 válido
                char tmp[4];
                size_t n = utf8_encode_cp(unicode_val, tmp);
                for (size_t k = 0; k < n; k++)
                    output[j++] = tmp[k];
                // Avanzar i por la cantidad de dígitos consumidos
                size_t consumed = 0;
                while (consumed < remain && consumed < 5 && input[i + 1 + consumed] >= '0' && input[i + 1 + consumed] <= '9')
                    consumed++;
                i += consumed;
            }
            break;
            default:
                output[j++] = '\\';
                output[j++] = input[i];
                break;
            }
        }
        else
        {
            output[j++] = input[i];
        }
        i++;
    }
    output[j] = '\0';
    return output;
}

static int parse_char_literal(const char *literal)
{
    if (!literal)
        return 0;

    size_t n = strlen(literal);
    if (n >= 2 && literal[0] == '\\')
    {
        switch (literal[1])
        {
        case 'n':
            return '\n';
        case 't':
            return '\t';
        case 'r':
            return '\r';
        case '\\':
            return '\\';
        case '"':
            return '"';
        case '\'':
            return '\'';
        case 'u':
        {
            int val = parse_unicode_escape_decimal(literal + 2, n - 2);
            if (val < 0)
                val = 0;
            if (val > 0x10FFFF)
                val = 0x10FFFF;
            return val;
        }
        default:
            return (unsigned char)literal[1];
        }
    }

    if (n > 0)
        return (unsigned char)literal[0];

    return 0;
}

// Funcion de interpretación para el nodo Primitivo
Result interpretPrimitivoExpresion(AbstractExpresion *self, Context *context)
{
    (void)context;
    PrimitivoExpresion *nodo = (PrimitivoExpresion *)self;

    // Dependiendo del tipo, convertimos el valor almacenado en cadena al tipo adecuado
    switch (nodo->tipo)
    {
    case NULO:
    {
        return nuevoValorResultado(NULL, NULO);
    }
    case INT:
    {
        int *valor = malloc(sizeof(int));
        if (strncmp(nodo->valor, "0x", 2) == 0 || strncmp(nodo->valor, "0X", 2) == 0)
        {
            *valor = (int)strtol(nodo->valor, NULL, 16);
        }
        else
        {
            *valor = (int)strtol(nodo->valor, NULL, 10);
        }
        return nuevoValorResultado(valor, INT);
    }
    case FLOAT:
    {
        float *v = malloc(sizeof(float));
        *v = atof(nodo->valor);
        return nuevoValorResultado(v, FLOAT);
    }
    case DOUBLE:
    {
        double *v = malloc(sizeof(double));
        *v = atof(nodo->valor);
        return nuevoValorResultado(v, DOUBLE);
    }
    case BOOLEAN:
    {
        int *v = malloc(sizeof(int));
        *v = strcmp(nodo->valor, "true") == 0;
        return nuevoValorResultado(v, BOOLEAN);
    }
    case CHAR:
    {
        int *valor = malloc(sizeof(int));
        *valor = parse_char_literal(nodo->valor);
        return nuevoValorResultado(valor, CHAR);
    }
    case STRING:
    {
        return nuevoValorResultado(process_string_escapes(nodo->valor), STRING);
    }
    default:
        return nuevoValorResultadoVacio();
    }
}

// Constructor del nodo Primitivo
AbstractExpresion *nuevoPrimitivoExpresion(char *v, TipoDato tipo, int line, int column)
{
    PrimitivoExpresion *nodo = malloc(sizeof(PrimitivoExpresion));
    if (!nodo)
        return NULL;
    buildAbstractExpresion(&nodo->base, interpretPrimitivoExpresion, "Primitivo", line, column);
    nodo->base.generar = generarPrimitivoExpresion;
    nodo->valor = v;
    nodo->tipo = tipo;
    return (AbstractExpresion *)nodo;
}