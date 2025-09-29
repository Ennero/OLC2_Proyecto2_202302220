#ifndef WHILE_H
#define WHILE_H

#include "ast/AbstractExpresion.h"

typedef struct
{
    AbstractExpresion base;
} WhileExpresion;

AbstractExpresion *nuevoWhileExpresion(AbstractExpresion *condicion, AbstractExpresion *bloque, int line, int column);

#endif // WHILE_H