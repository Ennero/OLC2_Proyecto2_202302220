#ifndef ARITMETICAS_H
#define ARITMETICAS_H

#include "ast/nodos/expresiones/expresiones.h"

// Declaraciones de funciones para las operaciones aritméticas

// Suma (todo se maneja en suma.c)
extern Operacion tablaOperacionesSuma[TIPO_COUNT][TIPO_COUNT];

// Resta
Result restarIntInt(ExpresionLenguaje *self);
Result restarFloatFloat(ExpresionLenguaje *self);
Result restarDoubleDouble(ExpresionLenguaje *self);
Result restarIntFloat(ExpresionLenguaje *self);
Result restarFloatInt(ExpresionLenguaje *self);
Result restarIntDouble(ExpresionLenguaje *self);
Result restarDoubleInt(ExpresionLenguaje *self);
Result restarFloatDouble(ExpresionLenguaje *self);
Result restarDoubleFloat(ExpresionLenguaje *self);
extern Operacion tablaOperacionesResta[TIPO_COUNT][TIPO_COUNT];

// Multiplicación
Result multiplicarIntInt(ExpresionLenguaje *self);
Result multiplicarFloatFloat(ExpresionLenguaje *self);
Result multiplicarDoubleDouble(ExpresionLenguaje *self);
Result multiplicarIntFloat(ExpresionLenguaje *self);
Result multiplicarFloatInt(ExpresionLenguaje *self);
Result multiplicarIntDouble(ExpresionLenguaje *self);
Result multiplicarDoubleInt(ExpresionLenguaje *self);
Result multiplicarFloatDouble(ExpresionLenguaje *self);
Result multiplicarDoubleFloat(ExpresionLenguaje *self);
extern Operacion tablaOperacionesMultiplicacion[TIPO_COUNT][TIPO_COUNT];

// División
Result dividirIntInt(ExpresionLenguaje *self);
Result dividirFloatFloat(ExpresionLenguaje *self);
Result dividirDoubleDouble(ExpresionLenguaje *self);
Result dividirIntFloat(ExpresionLenguaje *self);
Result dividirFloatInt(ExpresionLenguaje *self);
Result dividirIntDouble(ExpresionLenguaje *self);
Result dividirDoubleInt(ExpresionLenguaje *self);
Result dividirFloatDouble(ExpresionLenguaje *self);
Result dividirDoubleFloat(ExpresionLenguaje *self);
extern Operacion tablaOperacionesDivision[TIPO_COUNT][TIPO_COUNT];

// Módulo
Result moduloIntInt(ExpresionLenguaje *self);
Result moduloFloatFloat(ExpresionLenguaje *self);
Result moduloDoubleDouble(ExpresionLenguaje *self);
Result moduloIntFloat(ExpresionLenguaje *self);
Result moduloFloatInt(ExpresionLenguaje *self);
Result moduloIntDouble(ExpresionLenguaje *self);
Result moduloDoubleInt(ExpresionLenguaje *self);
Result moduloFloatDouble(ExpresionLenguaje *self);
Result moduloDoubleFloat(ExpresionLenguaje *self);
extern Operacion tablaOperacionesModulo[TIPO_COUNT][TIPO_COUNT];

// Unario (Negación)
extern UnaryOperacion tablaOperacionesUnario[TIPO_COUNT];

#endif