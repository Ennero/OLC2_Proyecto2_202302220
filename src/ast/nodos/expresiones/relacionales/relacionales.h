#ifndef RELACIONALES_H
#define RELACIONALES_H

#include "ast/AbstractExpresion.h"

// Constructores para cada operación relacional
AbstractExpresion *nuevoIgualExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoDiferenteExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoMenorQueExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoMayorQueExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoMenorIgualExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoMayorIgualExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);

#endif // RELACIONALES_H