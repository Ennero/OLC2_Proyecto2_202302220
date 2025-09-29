#ifndef LOGICAS_H
#define LOGICAS_H

#include "ast/nodos/expresiones/expresiones.h"

/* --- Operador Lógico AND (&&) --- */
Result logicoAndBooleano(ExpresionLenguaje* self);
extern Operacion tablaOperacionesAnd[TIPO_COUNT][TIPO_COUNT]; // Tablas de operaciones para AND

/* --- Operador Lógico OR (||) --- */
Result logicoOrBooleano(ExpresionLenguaje* self);
extern Operacion tablaOperacionesOr[TIPO_COUNT][TIPO_COUNT]; // Tablas de operaciones para OR

/* --- Operador Lógico NOT (!) --- */
Result logicoNotBooleano(Result res);
extern UnaryOperacion tablaOperacionesNot[TIPO_COUNT]; // Tablas de operaciones para NOT

#endif // LOGICAS_H