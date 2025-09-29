#ifndef BITWISE_H
#define BITWISE_H

#include "ast/nodos/expresiones/expresiones.h"

// Tablas de operaciones para los operadores binarios
extern Operacion tablaOperacionesBitwiseAnd[TIPO_COUNT][TIPO_COUNT];
extern Operacion tablaOperacionesBitwiseOr[TIPO_COUNT][TIPO_COUNT];
extern Operacion tablaOperacionesBitwiseXor[TIPO_COUNT][TIPO_COUNT];

// Tablas de operaciones para los operadores de desplazamiento
extern Operacion tablaOperacionesLeftShift[TIPO_COUNT][TIPO_COUNT];
extern Operacion tablaOperacionesRightShift[TIPO_COUNT][TIPO_COUNT];
extern Operacion tablaOperacionesUnsignedRightShift[TIPO_COUNT][TIPO_COUNT];

#endif // BITWISE_H