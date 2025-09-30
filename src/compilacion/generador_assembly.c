#include "compilacion/generador_assembly.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>

// Función auxiliar para escribir cadenas ASCII con escapes
static void escribir_cadena_ascii(FILE *archivo, const char *contenido)
{
    // Escribir la cadena con escapes para caracteres especiales
    fputc('"', archivo);
    for (const unsigned char *p = (const unsigned char *)contenido; *p; ++p)
    {
        unsigned char c = *p;
        switch (c)
        {
        case '\n':
            fputs("\\n", archivo);
            break;
        case '\t':
            fputs("\\t", archivo);
            break;
        case '\r':
            fputs("\\r", archivo);
            break;
        case '\\':
            fputs("\\\\", archivo);
            break;
        case '"':
            fputs("\\\"", archivo);
            break;
        case '\0':
            break;
        default:
            if (isprint(c))
            {
                fputc((int)c, archivo);
            }
            else
            {
                fprintf(archivo, "\\x%02X", c);
            }
            break;
        }
    }
    fputc('"', archivo);
}

// Escribir la sección .data con literales de cadena
static void escribir_seccion_datos(FILE *archivo, const GeneradorCodigo *generador)
{
    size_t cantidad_literales = 0;
    const LiteralCadena *literales = obtener_literales(generador, &cantidad_literales);

    fprintf(archivo, ".data\n\n");

    // Escribir cada literal de cadena
    for (size_t i = 0; i < cantidad_literales; ++i)
    {
        const LiteralCadena *literal = &literales[i];
        fprintf(archivo, "%s:\n    .ascii ", literal->etiqueta);
        escribir_cadena_ascii(archivo, literal->contenido ? literal->contenido : "");
        fprintf(archivo, "\nlongitud_%s = . - %s\n\n", literal->etiqueta, literal->etiqueta);
    }
}

// Escribir la sección .text con el código ensamblador
static void escribir_seccion_texto(FILE *archivo, const GeneradorCodigo *generador)
{
    size_t cantidad_cuadruplos = 0;
    const Cuadruplo *cuadruplos = obtener_cuadruplos(generador, &cantidad_cuadruplos);

    fprintf(archivo, ".text\n\n.global _start\n\n_start:\n\n");

    // Procesar cada cuádruplo
    for (size_t i = 0; i < cantidad_cuadruplos; ++i)
    {
        const Cuadruplo *cuadruplo = &cuadruplos[i];

        // Generar código según la operación del cuádruplo
        switch (cuadruplo->operacion)
        {
        case CUAD_OPERACION_IMPRIMIR_CADENA:
            if (cuadruplo->argumento1)
            {
                fprintf(archivo,
                        "    mov x0, #1\n"
                        "    ldr x1, =%s\n"
                        "    mov x2, #longitud_%s\n"
                        "    mov x8, #64\n"
                        "    svc #0\n\n",
                        cuadruplo->argumento1,
                        cuadruplo->argumento1);
            }
            break;
        case CUAD_OPERACION_FIN_PROGRAMA:
            break;
        default:
            break;
        }
    }

    // Código para salir del programa (uso de syscall exit)
    fprintf(archivo,
            "    mov x0, #0\n"
            "    mov x8, #93\n"
            "    svc #0\n");
}

// Función principal para generar el archivo de ensamblador AArch64
bool generar_archivo_aarch64(const GeneradorCodigo *generador, const char *ruta_archivo)
{
    // Validar parámetros
    if (!generador || !ruta_archivo)
        return false;

    // Abrir el archivo de salida
    FILE *archivo = fopen(ruta_archivo, "w");
    if (!archivo)
        return false;

    // Escribir las secciones .data y .text
    escribir_seccion_datos(archivo, generador);
    fprintf(archivo, "\n");
    escribir_seccion_texto(archivo, generador);

    fclose(archivo);
    return true;
}
