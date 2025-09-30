#include "bitwise.h"
#include "ast/nodos/builders.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>

static inline int aplicar_operacion_bitwise(int v1, int v2, char op)
{
    switch (op)
    {
    case '&':
        return v1 & v2;
    case '|':
        return v1 | v2;
    case '^':
        return v1 ^ v2;
    default:
        return 0;
    }
}

typedef enum
{
    SHIFT_LEFT,
    SHIFT_RIGHT,
    SHIFT_UNSIGNED_RIGHT
} ShiftTipo;

static inline int normalizar_entero(const Result *operando)
{
    if (!operando || !operando->valor)
    {
        return 0;
    }

    switch (operando->tipo)
    {
    case BOOLEAN:
    {
        int valor = *((int *)operando->valor);
        return valor ? 1 : 0;
    }
    case CHAR:
    case INT:
        return *((int *)operando->valor);
    default:
        return 0;
    }
}

// Función genérica para operaciones binarias
static Result bitwiseOperacion(ExpresionLenguaje *self, char op, TipoDato tipo_resultado)
{
    int v1 = self->izquierda.valor ? *((int *)self->izquierda.valor) : 0;
    int v2 = self->derecha.valor ? *((int *)self->derecha.valor) : 0;

    // Normalizar operandos booleanos a 0 o 1 antes de operar
    if (tipo_resultado == BOOLEAN)
    {
        v1 = v1 ? 1 : 0;
        v2 = v2 ? 1 : 0;
    }

    int resultado_bruto = aplicar_operacion_bitwise(v1, v2, op);

    int *res_val = malloc(sizeof(int));
    if (!res_val)
    {
        return nuevoValorResultadoVacio();
    }

    if (tipo_resultado == BOOLEAN)
    {
        resultado_bruto = resultado_bruto ? 1 : 0;
    }

    *res_val = resultado_bruto;
    return nuevoValorResultado(res_val, tipo_resultado);
}

// Wrappers para cada operador
static Result opBitwiseAndNumerico(ExpresionLenguaje *self) { return bitwiseOperacion(self, '&', INT); }
static Result opBitwiseOrNumerico(ExpresionLenguaje *self) { return bitwiseOperacion(self, '|', INT); }
static Result opBitwiseXorNumerico(ExpresionLenguaje *self) { return bitwiseOperacion(self, '^', INT); }

static Result opBitwiseAndBoolean(ExpresionLenguaje *self) { return bitwiseOperacion(self, '&', BOOLEAN); }
static Result opBitwiseOrBoolean(ExpresionLenguaje *self) { return bitwiseOperacion(self, '|', BOOLEAN); }
static Result opBitwiseXorBoolean(ExpresionLenguaje *self) { return bitwiseOperacion(self, '^', BOOLEAN); }

static Result shiftOperacion(ExpresionLenguaje *self, ShiftTipo tipo)
{
    int valor_izquierdo = normalizar_entero(&self->izquierda);
    int valor_derecho = normalizar_entero(&self->derecha);

    int *res_val = malloc(sizeof(int));
    if (!res_val)
    {
        return nuevoValorResultadoVacio();
    }

    switch (tipo)
    {
    case SHIFT_LEFT:
        *res_val = valor_izquierdo << valor_derecho;
        break;
    case SHIFT_RIGHT:
        *res_val = valor_izquierdo >> valor_derecho;
        break;
    case SHIFT_UNSIGNED_RIGHT:
        *res_val = (unsigned int)valor_izquierdo >> valor_derecho;
        break;
    }

    return nuevoValorResultado(res_val, INT);
}

// Operaciones de desplazamiento -----------
static Result opLeftShift(ExpresionLenguaje *self)
{
    return shiftOperacion(self, SHIFT_LEFT);
}

static Result opRightShift(ExpresionLenguaje *self)
{
    return shiftOperacion(self, SHIFT_RIGHT);
}

static Result opUnsignedRightShift(ExpresionLenguaje *self)
{
    return shiftOperacion(self, SHIFT_UNSIGNED_RIGHT);
}

// Tablas de Operaciones ----------------------------------
Operacion tablaOperacionesBitwiseAnd[TIPO_COUNT][TIPO_COUNT] = {
    [BOOLEAN] = {[BOOLEAN] = opBitwiseAndBoolean},
    [INT] = {[INT] = opBitwiseAndNumerico, [CHAR] = opBitwiseAndNumerico},
    [CHAR] = {[INT] = opBitwiseAndNumerico, [CHAR] = opBitwiseAndNumerico}};

Operacion tablaOperacionesBitwiseOr[TIPO_COUNT][TIPO_COUNT] = {
    [BOOLEAN] = {[BOOLEAN] = opBitwiseOrBoolean},
    [INT] = {[INT] = opBitwiseOrNumerico, [CHAR] = opBitwiseOrNumerico},
    [CHAR] = {[INT] = opBitwiseOrNumerico, [CHAR] = opBitwiseOrNumerico}};

Operacion tablaOperacionesBitwiseXor[TIPO_COUNT][TIPO_COUNT] = {
    [BOOLEAN] = {[BOOLEAN] = opBitwiseXorBoolean},
    [INT] = {[INT] = opBitwiseXorNumerico, [CHAR] = opBitwiseXorNumerico},
    [CHAR] = {[INT] = opBitwiseXorNumerico, [CHAR] = opBitwiseXorNumerico}};

Operacion tablaOperacionesLeftShift[TIPO_COUNT][TIPO_COUNT] = {
    [BOOLEAN] = {[BOOLEAN] = opLeftShift, [INT] = opLeftShift, [CHAR] = opLeftShift},
    [INT] = {[BOOLEAN] = opLeftShift, [INT] = opLeftShift, [CHAR] = opLeftShift},
    [CHAR] = {[BOOLEAN] = opLeftShift, [INT] = opLeftShift, [CHAR] = opLeftShift}};

Operacion tablaOperacionesRightShift[TIPO_COUNT][TIPO_COUNT] = {
    [BOOLEAN] = {[BOOLEAN] = opRightShift, [INT] = opRightShift, [CHAR] = opRightShift},
    [INT] = {[BOOLEAN] = opRightShift, [INT] = opRightShift, [CHAR] = opRightShift},
    [CHAR] = {[BOOLEAN] = opRightShift, [INT] = opRightShift, [CHAR] = opRightShift}};

Operacion tablaOperacionesUnsignedRightShift[TIPO_COUNT][TIPO_COUNT] = {
    [BOOLEAN] = {[BOOLEAN] = opUnsignedRightShift, [INT] = opUnsignedRightShift, [CHAR] = opUnsignedRightShift},
    [INT] = {[BOOLEAN] = opUnsignedRightShift, [INT] = opUnsignedRightShift, [CHAR] = opUnsignedRightShift},
    [CHAR] = {[BOOLEAN] = opUnsignedRightShift, [INT] = opUnsignedRightShift, [CHAR] = opUnsignedRightShift}};

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
