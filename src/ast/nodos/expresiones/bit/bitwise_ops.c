#include "bitwise.h"
#include "ast/nodos/builders.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

// Función para operaciones binarias
static Result bitwiseOperacion(ExpresionLenguaje *self, char op)
{
    int v1 = *(int *)self->izquierda.valor;
    int v2 = *(int *)self->derecha.valor;
    int *res_val = malloc(sizeof(int));

    // Realiza la operación bit a bit correspondiente
    switch (op)
    {
    case '&':
        *res_val = v1 & v2;
        break;
    case '|':
        *res_val = v1 | v2;
        break;
    case '^':
        *res_val = v1 ^ v2;
        break;
    }
    return nuevoValorResultado(res_val, INT); // Siempre será INT
}

// Wrappers para cada operador
static Result opBitwiseAnd(ExpresionLenguaje *self) { return bitwiseOperacion(self, '&'); }
static Result opBitwiseOr(ExpresionLenguaje *self) { return bitwiseOperacion(self, '|'); }
static Result opBitwiseXor(ExpresionLenguaje *self) { return bitwiseOperacion(self, '^'); }

// Operaciones de desplazamiento -----------
static Result opLeftShift(ExpresionLenguaje *self)
{
    int v1 = *(int *)self->izquierda.valor;
    int v2 = *(int *)self->derecha.valor;
    int *res_val = malloc(sizeof(int));
    *res_val = v1 << v2;
    return nuevoValorResultado(res_val, INT);
}

static Result opRightShift(ExpresionLenguaje *self)
{
    int v1 = *(int *)self->izquierda.valor;
    int v2 = *(int *)self->derecha.valor;
    int *res_val = malloc(sizeof(int));
    *res_val = v1 >> v2;
    return nuevoValorResultado(res_val, INT);
}

static Result opUnsignedRightShift(ExpresionLenguaje *self)
{
    int v1 = *(int *)self->izquierda.valor;
    int v2 = *(int *)self->derecha.valor;
    int *res_val = malloc(sizeof(int));

    // Para simular >>>, casteamos el operando izquierdo a unsigned antes de desplazar
    *res_val = (unsigned int)v1 >> v2;
    return nuevoValorResultado(res_val, INT);
}

// Tablas de Operaciones ----------------------------------
Operacion tablaOperacionesBitwiseAnd[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = opBitwiseAnd, [CHAR] = opBitwiseAnd},
    [CHAR] = {[INT] = opBitwiseAnd, [CHAR] = opBitwiseAnd}};

Operacion tablaOperacionesBitwiseOr[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = opBitwiseOr, [CHAR] = opBitwiseOr},
    [CHAR] = {[INT] = opBitwiseOr, [CHAR] = opBitwiseOr}};

Operacion tablaOperacionesBitwiseXor[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = opBitwiseXor, [CHAR] = opBitwiseXor},
    [CHAR] = {[INT] = opBitwiseXor, [CHAR] = opBitwiseXor}};

Operacion tablaOperacionesLeftShift[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = opLeftShift, [CHAR] = opLeftShift},
    [CHAR] = {[INT] = opLeftShift, [CHAR] = opLeftShift}};

Operacion tablaOperacionesRightShift[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = opRightShift, [CHAR] = opRightShift},
    [CHAR] = {[INT] = opRightShift, [CHAR] = opRightShift}};

Operacion tablaOperacionesUnsignedRightShift[TIPO_COUNT][TIPO_COUNT] = {
    [INT] = {[INT] = opUnsignedRightShift, [CHAR] = opUnsignedRightShift},
    [CHAR] = {[INT] = opUnsignedRightShift, [CHAR] = opUnsignedRightShift}};

// Operador NOT (~)
Result interpretBitwiseNotExpresion(AbstractExpresion *self, Context *context)
{
    Result res = self->hijos[0]->interpret(self->hijos[0], context);

    // Validar que el tipo sea INT o CHAR
    if (res.tipo != INT && res.tipo != CHAR)
    {
        char desc[256];
        sprintf(desc, "El operador unario '~' no se puede aplicar a un valor de tipo '%s'.", labelTipoDato[res.tipo]);
        add_error_to_report("Semantico", "~", desc, self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    int *val = malloc(sizeof(int));
    *val = ~(*(int *)res.valor); // Aplicar el NOT bit a bit
    free(res.valor);

    // El resultado siempre es INT
    return nuevoValorResultado(val, INT);
}

// Constructores de Nodos ------------------------------
AbstractExpresion *nuevoBitwiseAndExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "BitwiseAnd";
    expr->tablaOperaciones = &tablaOperacionesBitwiseAnd;
    return (AbstractExpresion *)expr;
}
AbstractExpresion *nuevoBitwiseOrExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "BitwiseOr";
    expr->tablaOperaciones = &tablaOperacionesBitwiseOr;
    return (AbstractExpresion *)expr;
}
AbstractExpresion *nuevoBitwiseXorExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "BitwiseXor";
    expr->tablaOperaciones = &tablaOperacionesBitwiseXor;
    return (AbstractExpresion *)expr;
}
AbstractExpresion *nuevoBitwiseNotExpresion(AbstractExpresion *expresion, int line, int column)
{
    AbstractExpresion *notExpresion = malloc(sizeof(AbstractExpresion));
    if (!notExpresion)
        return NULL;

    buildAbstractExpresion(notExpresion, interpretBitwiseNotExpresion, "BitwiseNot", line, column);
    agregarHijo(notExpresion, expresion);

    return notExpresion;
}
// Constructores para los operadores de desplazamiento
AbstractExpresion *nuevoLeftShiftExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "LeftShift";
    expr->tablaOperaciones = &tablaOperacionesLeftShift;
    return (AbstractExpresion *)expr;
}
AbstractExpresion *nuevoRightShiftExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "RightShift";
    expr->tablaOperaciones = &tablaOperacionesRightShift;
    return (AbstractExpresion *)expr;
}
AbstractExpresion *nuevoUnsignedRightShiftExpresion(AbstractExpresion *i, AbstractExpresion *d, int line, int column)
{
    ExpresionLenguaje *expr = nuevoExpresionLenguaje(interpretExpresionLenguaje, i, d, line, column);
    expr->base.node_type = "UnsignedRightShift";
    expr->tablaOperaciones = &tablaOperacionesUnsignedRightShift;
    return (AbstractExpresion *)expr;
}
