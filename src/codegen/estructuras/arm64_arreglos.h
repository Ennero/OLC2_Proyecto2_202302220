#ifndef ARM64_ARREGLOS_H
#define ARM64_ARREGLOS_H

#include <stdio.h>
#include "ast/AbstractExpresion.h"

int arm64_emitir_asignacion_arreglo(AbstractExpresion *node, FILE *ftext);
void arm64_emit_runtime_arreglo_helpers(FILE *ftext);

// Registro simple de arreglos (solo para codegen): nombre -> tipo base
void arm64_registrar_arreglo(const char *name, TipoDato base_tipo);

// 4 para int/char, 8 para string/punteros
int arm64_array_elem_size_for_var(const char *name);

// Tipo base almacenado
TipoDato arm64_array_elem_tipo_for_var(const char *name);

#endif // ARM64_ARREGLOS_H
