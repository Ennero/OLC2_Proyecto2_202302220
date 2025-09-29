#ifndef INSTRUCCIONES_H
#define INSTRUCCIONES_H

#include "ast/AbstractExpresion.h"

// Estructura para un nodo que contiene una lista de instrucciones
typedef struct
{
    AbstractExpresion base;
} InstruccionesExpresion;

// Prototipo/declaración del constructor
AbstractExpresion *nuevoInstruccionesExpresion();

#endif // INSTRUCCIONES_H