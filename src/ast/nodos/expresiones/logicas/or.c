#include "logicas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include <stdlib.h>

// Logica de OR
Result logicoOrBooleano(ExpresionLenguaje *self)
{
    int *res = malloc(sizeof(int));

    // Se realiza la operación OR lógica de C (||)
    *res = (*((int *)self->izquierda.valor) || *((int *)self->derecha.valor));
    return nuevoValorResultado(res, BOOLEAN);
}

// Tabla de Operaciones
Operacion tablaOperacionesOr[TIPO_COUNT][TIPO_COUNT] = {
    [BOOLEAN][BOOLEAN] = logicoOrBooleano};

// Constructor del Nodo del AST
AbstractExpresion *nuevoOrExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, izquierda, derecha, line, column);
    expr->base.node_type = "Or";
    expr->tablaOperaciones = &tablaOperacionesOr;
    return (AbstractExpresion *)expr;
}