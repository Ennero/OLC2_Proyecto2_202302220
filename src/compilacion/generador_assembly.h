#ifndef GENERADOR_ASSEMBLY_H
#define GENERADOR_ASSEMBLY_H

#include <stdbool.h>
#include "compilacion/generador_codigo.h"

// Función principal para generar el archivo de ensamblador AArch64
bool generar_archivo_aarch64(const GeneradorCodigo *generador, const char *ruta_archivo);

#endif // GENERADOR_ASSEMBLY_H
