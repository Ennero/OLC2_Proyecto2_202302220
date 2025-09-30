#ifndef COMPILADOR_H
#define COMPILADOR_H

#include <stdbool.h>
#include "ast/AbstractExpresion.h"
#include "context/context.h"

// Función principal para compilar el programa
bool compilar_programa(AbstractExpresion *raiz, Context *contexto_global, const char *ruta_archivo);

#endif // COMPILADOR_H
