#include "ast/nodos/expresiones/expresiones.h"
#include "ast/nodos/builders.h"
#include "context/result.h"
#include "context/array_value.h"
#include <stdlib.h>
#include <string.h>

// El resultado es siempre un booleano
static Result compararNumeros(ExpresionLenguaje *self, int negate)
{
    int *res = malloc(sizeof(int));

    // Se compara con double para evitar duplicar código
    double v1 = 0.0;
    double v2 = 0.0;

    // Obtener valores numéricos
    switch (self->izquierda.tipo)
    {
    case INT:
        v1 = (double)(*(int *)self->izquierda.valor);
        break;
    case CHAR:
        v1 = (double)(*(int *)self->izquierda.valor);
        break;
    case FLOAT:
        v1 = (double)(*(float *)self->izquierda.valor);
        break;
    case DOUBLE:
        v1 = *((double *)self->izquierda.valor);
        break;
    default:
        v1 = 0.0;
        break;
    }

    // Obtener valores numéricos
    switch (self->derecha.tipo)
    {
    case INT:
        v2 = (double)(*(int *)self->derecha.valor);
        break;
    case CHAR:
        v2 = (double)(*(int *)self->derecha.valor);
        break;
    case FLOAT:
        v2 = (double)(*(float *)self->derecha.valor);
        break;
    case DOUBLE:
        v2 = *((double *)self->derecha.valor);
        break;
    default:
        v2 = 0.0;
        break;
    }
    *res = (v1 == v2);
    if (negate)
        *res = !(*res);
    return nuevoValorResultado(res, BOOLEAN);
}

// Comparador de cadenas
static Result compararStrings(ExpresionLenguaje *self, int negate)
{
    // El resultado es siempre un booleano
    int *res = malloc(sizeof(int));
    // Soportar null-safety: "null" es distinto de cualquier cadena, pero si ambos son NULL es igual
    if (self->izquierda.valor == NULL || self->derecha.valor == NULL)
    {
        *res = (self->izquierda.valor == NULL && self->derecha.valor == NULL);
    }
    else
    {
        *res = (strcmp((char *)self->izquierda.valor, (char *)self->derecha.valor) == 0);
    }
    if (negate)
        *res = !(*res);
    return nuevoValorResultado(res, BOOLEAN);
}

// Comparador de arreglos por referencia (como en Java con ==)
static Result compararArraysRefer(ExpresionLenguaje *self, int negate)
{
    int *res = malloc(sizeof(int));
    ArrayValue *a1 = (ArrayValue *)self->izquierda.valor;
    ArrayValue *a2 = (ArrayValue *)self->derecha.valor;
    *res = (a1 == a2);
    if (negate)
        *res = !(*res);
    return nuevoValorResultado(res, BOOLEAN);
}

// Wrappers sin parámetro extra para usar en las tablas de operaciones
static Result compararArraysIgual(ExpresionLenguaje *self) { return compararArraysRefer(self, 0); }
static Result compararArraysDiferente(ExpresionLenguaje *self) { return compararArraysRefer(self, 1); }

// Comparador de booleanos
static Result compararBooleanos(ExpresionLenguaje *self, int negate)
{
    int *res = malloc(sizeof(int));
    *res = (*(int *)self->izquierda.valor == *(int *)self->derecha.valor);
    if (negate)
        *res = !(*res);
    return nuevoValorResultado(res, BOOLEAN);
}

// Funciones wrapper para no duplicar código
static Result compararIgual(ExpresionLenguaje *self) { return compararNumeros(self, 0); }
static Result compararBooleanosIgual(ExpresionLenguaje *self) { return compararBooleanos(self, 0); }

static Result compararStringsIgual(ExpresionLenguaje *self) { return compararStrings(self, 0); }

static Result compararDiferente(ExpresionLenguaje *self) { return compararNumeros(self, 1); }
static Result compararBooleanosDiferente(ExpresionLenguaje *self) { return compararBooleanos(self, 1); }
static Result compararStringsDiferente(ExpresionLenguaje *self) { return compararStrings(self, 1); }

Operacion tablaOperacionesIgual[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = compararIgual, [DOUBLE] = compararIgual, [CHAR] = compararIgual, [FLOAT] = compararIgual},
    [DOUBLE] = {[INT] = compararIgual, [DOUBLE] = compararIgual, [CHAR] = compararIgual, [FLOAT] = compararIgual},
    [CHAR] = {[INT] = compararIgual, [DOUBLE] = compararIgual, [CHAR] = compararIgual, [FLOAT] = compararIgual},
    [FLOAT] = {[INT] = compararIgual, [DOUBLE] = compararIgual, [CHAR] = compararIgual, [FLOAT] = compararIgual},
    [STRING] = {[STRING] = compararStringsIgual, [NULO] = compararStringsIgual},
    [BOOLEAN] = {[BOOLEAN] = compararBooleanosIgual},
    [ARRAY] = {[ARRAY] = compararArraysIgual, [NULO] = compararArraysIgual},
    [NULO] = {[STRING] = compararStringsIgual, [NULO] = compararStringsIgual, [ARRAY] = compararArraysIgual}};

Operacion tablaOperacionesDiferente[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = compararDiferente, [DOUBLE] = compararDiferente, [CHAR] = compararDiferente, [FLOAT] = compararDiferente},
    [DOUBLE] = {[INT] = compararDiferente, [DOUBLE] = compararDiferente, [CHAR] = compararDiferente, [FLOAT] = compararDiferente},
    [CHAR] = {[INT] = compararDiferente, [DOUBLE] = compararDiferente, [CHAR] = compararDiferente, [FLOAT] = compararDiferente},
    [FLOAT] = {[INT] = compararDiferente, [DOUBLE] = compararDiferente, [CHAR] = compararDiferente, [FLOAT] = compararDiferente},
    [STRING] = {[STRING] = compararStringsDiferente, [NULO] = compararStringsDiferente},
    [BOOLEAN] = {[BOOLEAN] = compararBooleanosDiferente},
    [ARRAY] = {[ARRAY] = compararArraysDiferente, [NULO] = compararArraysDiferente},
    [NULO] = {[STRING] = compararStringsDiferente, [NULO] = compararStringsDiferente, [ARRAY] = compararArraysDiferente}};

// Constructores de Nodos ------
AbstractExpresion *nuevoIgualExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "IgualIgual";
    expr->tablaOperaciones = &tablaOperacionesIgual;
    return (AbstractExpresion *)expr;
}

AbstractExpresion *nuevoDiferenteExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "Diferente";
    expr->tablaOperaciones = &tablaOperacionesDiferente;
    return (AbstractExpresion *)expr;
}