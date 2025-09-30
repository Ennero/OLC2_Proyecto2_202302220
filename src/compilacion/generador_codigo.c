#include "compilacion/generador_codigo.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "context/result.h"
#include "utils/java_num_format.h"

#define CAPACIDAD_INICIAL 16

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

// Duplica una cadena, devolviendo NULL si la entrada es NULL
static char *duplicar_cadena(const char *texto)
{
    if (!texto)
        return NULL;
    size_t longitud = strlen(texto);
    char *copia = (char *)malloc(longitud + 1);
    if (!copia)
        return NULL;
    memcpy(copia, texto, longitud + 1);
    return copia;
}

// Asegura que el arreglo de cuadruplos tenga capacidad para al menos un elemento más
static void asegurar_capacidad_cuadruplos(GeneradorCodigo *generador)
{
    if (generador->cantidad_cuadruplos < generador->capacidad_cuadruplos)
        return;
    size_t nueva_capacidad = generador->capacidad_cuadruplos == 0 ? CAPACIDAD_INICIAL : generador->capacidad_cuadruplos * 2;
    Cuadruplo *nuevos = (Cuadruplo *)realloc(generador->cuadruplos, nueva_capacidad * sizeof(Cuadruplo));
    
    // Si realloc falla, no cambiamos nada
    if (!nuevos)
        return;
    generador->cuadruplos = nuevos;
    generador->capacidad_cuadruplos = nueva_capacidad;
}

// Asegura que el arreglo de literales tenga capacidad para al menos un elemento más
static void asegurar_capacidad_literales(GeneradorCodigo *generador)
{
    if (generador->cantidad_literales < generador->capacidad_literales)
        return;
    size_t nueva_capacidad = generador->capacidad_literales == 0 ? CAPACIDAD_INICIAL : generador->capacidad_literales * 2;
    LiteralCadena *nuevos = (LiteralCadena *)realloc(generador->literales, nueva_capacidad * sizeof(LiteralCadena));
    if (!nuevos)
        return;
    generador->literales = nuevos;
    generador->capacidad_literales = nueva_capacidad;
}

// Asegura que el arreglo de textos (temporales o etiquetas) tenga capacidad para al menos un elemento más
static void asegurar_capacidad_textos(char ***arreglo, size_t *cantidad, size_t *capacidad)
{
    if (*cantidad < *capacidad)
        return;
    size_t nueva_capacidad = *capacidad == 0 ? CAPACIDAD_INICIAL : (*capacidad) * 2;
    char **nuevos = (char **)realloc(*arreglo, nueva_capacidad * sizeof(char *));
    if (!nuevos)
        return;
    *arreglo = nuevos;
    *capacidad = nueva_capacidad;
}

// Funciones públicas
GeneradorCodigo *crear_generador_codigo(void)
{
    GeneradorCodigo *generador = (GeneradorCodigo *)calloc(1, sizeof(GeneradorCodigo));
    return generador;
}

// Liberar recursos utilizados por el generador de código
void liberar_generador_codigo(GeneradorCodigo *generador)
{
    if (!generador)
        return;

    // Liberar cada cadena en los cuadruplos antes de liberar el arreglo
    for (size_t i = 0; i < generador->cantidad_cuadruplos; ++i)
    {
        free(generador->cuadruplos[i].argumento1);
        free(generador->cuadruplos[i].argumento2);
        free(generador->cuadruplos[i].resultado);
    }
    free(generador->cuadruplos);

    // Liberar cada literal de cadena antes de liberar el arreglo
    for (size_t i = 0; i < generador->cantidad_literales; ++i)
    {
        free(generador->literales[i].etiqueta);
        free(generador->literales[i].contenido);
    }
    free(generador->literales);

    // Liberar cada temporal y etiqueta antes de liberar los arreglos
    for (size_t i = 0; i < generador->cantidad_temporales; ++i)
    {
        free(generador->nombres_temporales[i]);
    }
    free(generador->nombres_temporales);

    // Liberar cada etiqueta antes de liberar el arreglo
    for (size_t i = 0; i < generador->cantidad_etiquetas; ++i)
    {
        free(generador->nombres_etiquetas[i]);
    }
    free(generador->nombres_etiquetas);

    free(generador);
}

// Emisión de cuádruplos
void agregar_cuadruplo(GeneradorCodigo *generador, OperacionCuadruplo operacion, const char *arg1, const char *arg2, const char *resultado)
{
    if (!generador)
        return;
    asegurar_capacidad_cuadruplos(generador);
    if (generador->capacidad_cuadruplos == 0)
        return;

    Cuadruplo *destino = &generador->cuadruplos[generador->cantidad_cuadruplos++];
    destino->operacion = operacion;
    destino->argumento1 = duplicar_cadena(arg1);
    destino->argumento2 = duplicar_cadena(arg2);
    destino->resultado = duplicar_cadena(resultado);
}

// Utilidades para crear temporales, etiquetas y literales
const char *crear_temporal(GeneradorCodigo *generador)
{
    if (!generador)
        return NULL;

    char nombre[32];
    snprintf(nombre, sizeof(nombre), "t%u", generador->contador_temporales++);
    char *copia = duplicar_cadena(nombre);
    if (!copia)
        return NULL;

    asegurar_capacidad_textos(&generador->nombres_temporales, &generador->cantidad_temporales, &generador->capacidad_temporales);
    if (generador->capacidad_temporales == 0)
    {
        free(copia);
        return NULL;
    }
    generador->nombres_temporales[generador->cantidad_temporales++] = copia;
    return copia;
}

// Crea una nueva etiqueta con el prefijo dado
const char *crear_etiqueta(GeneradorCodigo *generador, const char *prefijo)
{
    if (!generador)
        return NULL;
    if (!prefijo)
        prefijo = "L";

    char nombre[64];
    snprintf(nombre, sizeof(nombre), "%s%u", prefijo, generador->contador_etiquetas++);
    char *copia = duplicar_cadena(nombre);
    if (!copia)
        return NULL;

    asegurar_capacidad_textos(&generador->nombres_etiquetas, &generador->cantidad_etiquetas, &generador->capacidad_etiquetas);
    if (generador->capacidad_etiquetas == 0)
    {
        free(copia);
        return NULL;
    }
    generador->nombres_etiquetas[generador->cantidad_etiquetas++] = copia;
    return copia;
}

// Registra un literal de cadena y devuelve su etiqueta única
const char *registrar_literal_cadena(GeneradorCodigo *generador, const char *contenido)
{
    if (!generador || !contenido)
        return NULL;

    for (size_t i = 0; i < generador->cantidad_literales; ++i)
    {
        if (strcmp(generador->literales[i].contenido, contenido) == 0)
        {
            return generador->literales[i].etiqueta;
        }
    }

    asegurar_capacidad_literales(generador);
    if (generador->capacidad_literales == 0)
        return NULL;

    char etiqueta[64];
    snprintf(etiqueta, sizeof(etiqueta), "literal_cadena_%zu", generador->cantidad_literales);

    LiteralCadena *nuevo = &generador->literales[generador->cantidad_literales++];
    nuevo->etiqueta = duplicar_cadena(etiqueta);
    nuevo->contenido = duplicar_cadena(contenido);
    if (!nuevo->etiqueta || !nuevo->contenido)
        return NULL;

    return nuevo->etiqueta;
}

void liberar_resultado(Result *resultado)
{
    if (!resultado || !resultado->valor)
        return;

    switch (resultado->tipo)
    {
    case ARRAY:
    case BREAK_T:
    case CONTINUE_T:
    case RETURN_T:
        return;
    default:
        free(resultado->valor);
        resultado->valor = NULL;
        break;
    }
}

const char *registrar_literal_desde_resultado(GeneradorCodigo *generador, Result *resultado)
{
    if (!generador || !resultado)
        return NULL;

    const char *etiqueta = NULL;

    switch (resultado->tipo)
    {
    case INT:
    {
        int valor = resultado->valor ? *((int *)resultado->valor) : 0;
        char buffer[64];
        snprintf(buffer, sizeof(buffer), "%d", valor);
        etiqueta = registrar_literal_cadena(generador, buffer);
        break;
    }
    case FLOAT:
    {
        float valor = resultado->valor ? *((float *)resultado->valor) : 0.0f;
        char buffer[64];
        java_format_float(valor, buffer, sizeof(buffer));
        etiqueta = registrar_literal_cadena(generador, buffer);
        break;
    }
    case DOUBLE:
    {
        double valor = resultado->valor ? *((double *)resultado->valor) : 0.0;
        char buffer[64];
        java_format_double(valor, buffer, sizeof(buffer));
        etiqueta = registrar_literal_cadena(generador, buffer);
        break;
    }
    case BOOLEAN:
    {
        int valor = resultado->valor ? *((int *)resultado->valor) : 0;
        etiqueta = registrar_literal_cadena(generador, valor ? "true" : "false");
        break;
    }
    case CHAR:
    {
        int cp = resultado->valor ? *((int *)resultado->valor) : 0;
        char buffer[8];
        size_t bytes = utf8_encode_cp(cp, buffer);
        buffer[bytes] = '\0';
        etiqueta = registrar_literal_cadena(generador, buffer);
        break;
    }
    case STRING:
    {
        const char *texto = resultado->valor ? (const char *)resultado->valor : "null";
        etiqueta = registrar_literal_cadena(generador, texto);
        break;
    }
    case NULO:
        etiqueta = registrar_literal_cadena(generador, "null");
        break;
    default:
        etiqueta = NULL;
        break;
    }

    liberar_resultado(resultado);
    resultado->valor = NULL;
    resultado->tipo = NULO;

    return etiqueta;
}

// getters y setters -----------------------------------------------------------------------------
const Cuadruplo *obtener_cuadruplos(const GeneradorCodigo *generador, size_t *cantidad)
{
    if (!generador)
    {
        if (cantidad)
            *cantidad = 0;
        return NULL;
    }
    if (cantidad)
        *cantidad = generador->cantidad_cuadruplos;
    return generador->cuadruplos;
}

const LiteralCadena *obtener_literales(const GeneradorCodigo *generador, size_t *cantidad)
{
    if (!generador)
    {
        if (cantidad)
            *cantidad = 0;
        return NULL;
    }
    if (cantidad)
        *cantidad = generador->cantidad_literales;
    return generador->literales;
}
