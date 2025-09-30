#ifndef GENERADOR_CODIGO_H
#define GENERADOR_CODIGO_H

#include "compilacion/cuadruplos.h"
#include <stddef.h>
#include <stdbool.h>

// Adelanto de la estructura de contexto para evitar dependencias circulares.
typedef struct Context Context;

// Estructura para manejar literales de cadena únicos.
typedef struct
{
    char *etiqueta;
    char *contenido;
} LiteralCadena;

// Gestiona la acumulación de cuádruplos, literales y temporales.
typedef struct GeneradorCodigo
{
    Cuadruplo *cuadruplos;
    size_t cantidad_cuadruplos;
    size_t capacidad_cuadruplos;

    LiteralCadena *literales;
    size_t cantidad_literales;
    size_t capacidad_literales;

    char **nombres_temporales;
    size_t cantidad_temporales;
    size_t capacidad_temporales;

    char **nombres_etiquetas;
    size_t cantidad_etiquetas;
    size_t capacidad_etiquetas;

    unsigned int contador_temporales;
    unsigned int contador_etiquetas;
} GeneradorCodigo;

GeneradorCodigo *crear_generador_codigo(void);
void liberar_generador_codigo(GeneradorCodigo *generador);

// Emisión de cuádruplos
void agregar_cuadruplo(GeneradorCodigo *generador, OperacionCuadruplo operacion, const char *arg1, const char *arg2, const char *resultado);

// Utilidades para crear temporales, etiquetas y literales
const char *crear_temporal(GeneradorCodigo *generador);
const char *crear_etiqueta(GeneradorCodigo *generador, const char *prefijo);
const char *registrar_literal_cadena(GeneradorCodigo *generador, const char *contenido);

// Acceso sólo lectura
const Cuadruplo *obtener_cuadruplos(const GeneradorCodigo *generador, size_t *cantidad);
const LiteralCadena *obtener_literales(const GeneradorCodigo *generador, size_t *cantidad);

#endif // GENERADOR_CODIGO_H
