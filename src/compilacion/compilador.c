#include "compilacion/compilador.h"
#include "compilacion/generador_codigo.h"
#include "compilacion/generador_assembly.h"

// Función principal para compilar el programa
bool compilar_programa(AbstractExpresion *raiz, Context *contexto_global, const char *ruta_archivo)
{
    if (!raiz || !ruta_archivo)
        return false;

    // Crear el generador de código
    GeneradorCodigo *generador = crear_generador_codigo();
    if (!generador)
        return false;

    // Generar código a partir del AST
    if (raiz->generar)
    {
        raiz->generar(raiz, generador, contexto_global);
    }

    // Agregar un cuadruplo final de fin de programa
    agregar_cuadruplo(generador, CUAD_OPERACION_FIN_PROGRAMA, NULL, NULL, NULL);

    // Generar el archivo de salida
    bool exito = generar_archivo_aarch64(generador, ruta_archivo);

    // Liberar el generador de código
    liberar_generador_codigo(generador);
    return exito;
}
