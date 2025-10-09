#ifndef ARM64_PRINT_H
#define ARM64_PRINT_H
#include "ast/AbstractExpresion.h"
#include <stdio.h>

int expresion_es_cadena(AbstractExpresion *node);
void emitir_imprimir_cadena(AbstractExpresion *node, FILE *ftext);
// Evalúa una expresión string y deja su puntero en x1. Devuelve 1 si pudo, 0 si no.
int emitir_eval_string_ptr(AbstractExpresion *node, FILE *ftext);

// Embedded helpers
void emitir_parse_int(AbstractExpresion *arg, FILE *ftext);
void emitir_parse_float(AbstractExpresion *arg, FILE *ftext);
void emitir_parse_double(AbstractExpresion *arg, FILE *ftext);
void emitir_string_valueof(AbstractExpresion *arg, FILE *ftext);

#endif // ARM64_PRINT_H
