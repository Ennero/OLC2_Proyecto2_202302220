#include "compilacion/generador_codigo.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define CAPACIDAD_INICIAL 16

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
