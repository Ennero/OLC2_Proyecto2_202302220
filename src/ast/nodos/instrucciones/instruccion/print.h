#ifndef PRINT_H
#define PRINT_H

#include "ast/AbstractExpresion.h"
#include "context/context.h"
#include "context/result.h"
#include "output_buffer.h"

// Estructura para un nodo de impresión
typedef struct
{
    AbstractExpresion base;
} PrintExpresion;

Result interpretPrintExpresion(AbstractExpresion *, Context *);

#endif
