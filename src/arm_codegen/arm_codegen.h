#ifndef ARM_CODEGEN_H
#define ARM_CODEGEN_H

#include "ast/AbstractExpresion.h"

/**
 * Genera un archivo en ensamblador AArch64 a partir del AST provisto.
 *
 * @param programa    Raíz del AST del programa en JavaLang.
 * @param ruta_salida Ruta completa hacia el archivo .s que se desea generar.
 *
 * @return 0 si la generación fue exitosa, distinto de 0 si ocurrió algún error.
 */
int generar_arm_desde_ast(AbstractExpresion *programa, const char *ruta_salida);

#endif // ARM_CODEGEN_H
