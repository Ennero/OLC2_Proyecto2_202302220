#ifndef POSTFIX_NODE_H
#define POSTFIX_NODE_H

#include "ast/AbstractExpresion.h"

// Devuelve el token del operador del nodo Postfix (TOKEN_INCREMENTO o TOKEN_DECREMENTO)
// Retorna 0 si no es un nodo válido.
int postfix_get_op(AbstractExpresion *self);

#endif // POSTFIX_NODE_H
