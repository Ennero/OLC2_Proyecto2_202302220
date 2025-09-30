#ifndef PRINT_H
#define PRINT_H

#include "ast/AbstractExpresion.h"
#include "context/context.h"
#include "context/result.h"
#include "output_buffer.h"
#include <stddef.h>

// Estructura para un nodo de impresión
typedef struct
{
    AbstractExpresion base;
    char **literal_cache;
    size_t literal_count;
    size_t literal_capacity;
} PrintExpresion;

Result interpretPrintExpresion(AbstractExpresion *, Context *);

#endif
