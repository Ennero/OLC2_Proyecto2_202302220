#include "logicas.h"
#include "ast/nodos/builders.h"
#include "ast/nodos/expresiones/expresiones.h"
#include "context/result.h"
#include <stdlib.h>

// Lógica AND 
Result logicoAndBooleano(ExpresionLenguaje* self) {
    int* res = malloc(sizeof(int));

    // Se realiza la operación AND lógica de C (&&)
    *res = (*((int*)self->izquierda.valor) && *((int*)self->derecha.valor));
    return nuevoValorResultado(res, BOOLEAN);
}

// Tabla de Operaciones 
Operacion tablaOperacionesAnd[TIPO_COUNT][TIPO_COUNT] = {
    [BOOLEAN][BOOLEAN] = logicoAndBooleano
};

//  Constructor del Nodo
AbstractExpresion* nuevoAndExpresion(AbstractExpresion* izquierda, AbstractExpresion* derecha, int line, int column) {
    ExpresionLenguaje* expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, izquierda, derecha, line, column);
    expr->base.node_type = "And";
    expr->tablaOperaciones = &tablaOperacionesAnd;
    return (AbstractExpresion*) expr;
}