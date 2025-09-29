#ifndef AST_GRAPHER_H
#define AST_GRAPHER_H

#include "ast/AbstractExpresion.h"

// Función principal para generar el gráfico del AST
void generate_ast_graph(AbstractExpresion *root, const char *output_filename);

#endif
