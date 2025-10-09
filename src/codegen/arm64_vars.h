#ifndef ARM64_VARS_H
#define ARM64_VARS_H
#include "context/result.h"
#include <stdio.h>

typedef struct VarEntry {
    char *name;
    TipoDato tipo;
    int offset;
    struct VarEntry *next;
} VarEntry;

VarEntry *vars_buscar(const char *name);
VarEntry *vars_agregar(const char *name, TipoDato tipo, int size_bytes, FILE *ftext);
int vars_local_bytes(void);
void vars_epilogo(FILE *ftext);
void vars_reset(void);

#endif // ARM64_VARS_H
