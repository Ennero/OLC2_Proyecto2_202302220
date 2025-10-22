#ifndef ARM64_VARS_H
#define ARM64_VARS_H
#include "context/result.h"
#include <stdio.h>

// Entrada de variable local en la lista enlazada
typedef struct VarEntry
{
    char *name;
    TipoDato tipo;
    int offset;
    int is_const;

    // Marca si esta variable local almacena una referencia (puntero a puntero) al valor real.
    int is_ref;
    struct VarEntry *next;
} VarEntry;

VarEntry *vars_buscar(const char *name);
VarEntry *vars_agregar(const char *name, TipoDato tipo, int size_bytes, FILE *ftext);

// Versión extendida que permite marcar constantes
VarEntry *vars_agregar_ext(const char *name, TipoDato tipo, int size_bytes, int is_const, FILE *ftext);
int vars_local_bytes(void);
void vars_epilogo(FILE *ftext);
void vars_reset(void);

// Manejo de bloques/alcances
void vars_push_scope(FILE *ftext);
void vars_pop_scope(FILE *ftext);

#endif // ARM64_VARS_H
