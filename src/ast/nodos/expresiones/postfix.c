#include "ast/nodos/builders.h"
#include "ast/AbstractExpresion.h"
#include "context/context.h"
#include "context/array_value.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "parser.tab.h"
#include "ast/nodos/expresiones/postfix.h"

// Estructura interna para este nodo
typedef struct
{
    AbstractExpresion base;
    int op_token; // TOKEN_INCREMENTO o TOKEN_DECREMENTO
} PostfixExpresion;

int postfix_get_op(AbstractExpresion *self)
{
    if (!self || !self->node_type) return 0;
    if (strcmp(self->node_type, "Postfix") != 0) return 0;
    PostfixExpresion *n = (PostfixExpresion *)self;
    return n->op_token;
}

static Result write_back_to_lvalue(AbstractExpresion *lvalue_expr, Context *context, Result nuevo_valor)
{
    // lvalue puede ser un identificador o un acceso a arreglo
    if (strcmp(lvalue_expr->node_type, "Identificador") == 0)
    {
        // Manejo de identificadores
        IdentificadorExpresion *id = (IdentificadorExpresion *)lvalue_expr;
        Symbol *simbolo = buscarTablaSimbolos(context, id->nombre);

        // Validaciones
        if (!simbolo || simbolo->clase != VARIABLE)
        {
            // Si la variable no existe o no es variable, error
            add_error_to_report("Semantico", id->nombre, "Variable no declarada.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
            if (nuevo_valor.tipo == ARRAY)
            {
                // Liberar el valor creado si no se pudo asignar
                if (nuevo_valor.valor)
                    liberarArray((ArrayValue *)nuevo_valor.valor);
            }
            // Si no es arreglo, liberar el valor creado
            else
            {
                free(nuevo_valor.valor);
            }
            return nuevoValorResultadoVacio();
        }

        // Si es constante, error
        if (simbolo->es_constante)
        {
            char desc[256];
            snprintf(desc, sizeof(desc), "No se puede modificar la constante 'final' '%s'.", id->nombre);
            add_error_to_report("Semantico", id->nombre, desc, lvalue_expr->line, lvalue_expr->column, context->nombre_completo);

            // Liberar el valor creado si no se pudo asignar
            if (nuevo_valor.tipo == ARRAY)
            {
                if (nuevo_valor.valor)
                    liberarArray((ArrayValue *)nuevo_valor.valor);
            }
            else
            {
                free(nuevo_valor.valor);
            }
            return nuevoValorResultadoVacio();
        }

        // liberar previo
        if (simbolo->info.var.valor)
        {
            if (simbolo->tipo == ARRAY)
                liberarArray((ArrayValue *)simbolo->info.var.valor);
            else
                free(simbolo->info.var.valor);
        }
        simbolo->info.var.valor = nuevo_valor.valor;
        simbolo->tipo = nuevo_valor.tipo;
        return nuevoValorResultadoVacio();
    }

    // Manejo de accesos a arreglos
    if (strcmp(lvalue_expr->node_type, "ArrayAccess") == 0)
    {
        // Aplanar acceso
        int depth = 0;
        AbstractExpresion *it = lvalue_expr;

        // Contar profundidad y obtener base
        while (it && strcmp(it->node_type, "ArrayAccess") == 0)
        {
            depth++;
            it = it->hijos[0];
        }

        // Recolectar nodos de índice
        AbstractExpresion *base_expr = it;
        AbstractExpresion **idx_nodes = malloc(sizeof(AbstractExpresion *) * (size_t)depth);

        // Validaciones
        if (!idx_nodes)
        {
            if (nuevo_valor.tipo == ARRAY)
                liberarArray((ArrayValue *)nuevo_valor.valor);
            else
                free(nuevo_valor.valor);
            return nuevoValorResultadoVacio();
        }
        it = lvalue_expr;

        // Para cada nivel, guardar el nodo de índice
        for (int i = 0; i < depth; i++)
        {
            idx_nodes[i] = it->hijos[1];
            it = it->hijos[0];
        }

        // Obtener arreglo base por referencia
        Result base_res = base_expr->interpret(base_expr, context);
        if (base_res.tipo != ARRAY || base_res.valor == NULL)
        {
            add_error_to_report("Semantico", "++/--", "Lado izquierdo no es un arreglo.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
            free(idx_nodes);
            if (nuevo_valor.tipo == ARRAY)
                liberarArray((ArrayValue *)nuevo_valor.valor);
            else
                free(nuevo_valor.valor);
            if (base_res.valor)
                free(base_res.valor);
            return nuevoValorResultadoVacio();
        }
        ArrayValue *current = (ArrayValue *)base_res.valor;

        // Navegar hasta penúltima dimensión
        for (int i = depth - 1; i >= 1; --i)
        {
            // Evaluar índice
            Result idx_res = idx_nodes[i]->interpret(idx_nodes[i], context);

            // Si no es entero, error
            if (idx_res.tipo != INT)
            {
                add_error_to_report("Semantico", "[]", "El índice de un arreglo debe ser entero.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
                free(idx_res.valor);
                free(idx_nodes);
                return nuevoValorResultadoVacio();
            }

            // Si índice fuera de límites o current es NULL, error
            int index = *(int *)idx_res.valor;
            free(idx_res.valor);
            if (!current || index < 0 || index >= current->tamano)
            {
                add_error_to_report("Semantico", "[]", "Índice fuera de límites.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
                free(idx_nodes);
                return nuevoValorResultadoVacio();
            }

            // Mover a la siguiente dimensión
            Result elem = current->valores[index];
            if (elem.tipo != ARRAY || elem.valor == NULL)
            {
                add_error_to_report("Semantico", "[]", "Se esperaba sub-arreglo al navegar dimensiones.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
                free(idx_nodes);
                return nuevoValorResultadoVacio();
            }
            current = (ArrayValue *)elem.valor;
        }

        // Índice final y escritura
        Result idx_last = idx_nodes[0]->interpret(idx_nodes[0], context);

        // Validaciones
        if (idx_last.tipo != INT)
        {
            add_error_to_report("Semantico", "[]", "El índice de un arreglo debe ser entero.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
            free(idx_last.valor);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }
        int index_last = *(int *)idx_last.valor;
        free(idx_last.valor);
        free(idx_nodes);
        if (!current || index_last < 0 || index_last >= current->tamano)
        {
            add_error_to_report("Semantico", "[]", "Índice fuera de límites.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
            return nuevoValorResultadoVacio();
        }

        // Validaciones de tipo
        int remaining_dims = current->dimensiones_total;
        if (remaining_dims <= 1)
        {
            if (nuevo_valor.tipo != current->tipo_elemento_base)
            {
                add_error_to_report("Semantico", "++/--", "Tipo incompatible al escribir en arreglo.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
                if (nuevo_valor.tipo == ARRAY)
                    liberarArray((ArrayValue *)nuevo_valor.valor);
                else
                    free(nuevo_valor.valor);
                return nuevoValorResultadoVacio();
            }

            // Liberar previo
            Result old = current->valores[index_last];
            if (old.tipo == ARRAY)
            {
                if (old.valor)
                    liberarArray((ArrayValue *)old.valor);
            }
            else
            {
                if (old.valor)
                    free(old.valor);
            }
            current->valores[index_last] = nuevo_valor;
        }
        // Si quedan más dimensiones, debe ser ARRAY compatible
        else
        {
            // El nuevo valor debe ser ARRAY, sin oerror
            if (nuevo_valor.tipo != ARRAY)
            {
                add_error_to_report("Semantico", "++/--", "Se esperaba sub-arreglo para escribir en dimensión intermedia.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
                if (nuevo_valor.tipo == ARRAY)
                    liberarArray((ArrayValue *)nuevo_valor.valor);
                else
                    free(nuevo_valor.valor);
                return nuevoValorResultadoVacio();
            }

            // Validar compatibilidad del sub-arreglo
            ArrayValue *sub = (ArrayValue *)nuevo_valor.valor;
            if (sub->tipo_elemento_base != current->tipo_elemento_base || sub->dimensiones_total != remaining_dims - 1)
            {
                add_error_to_report("Semantico", "++/--", "Dimensiones incompatibles al escribir en arreglo.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
                liberarArray(sub);
                return nuevoValorResultadoVacio();
            }

            // Liberar previo
            Result old = current->valores[index_last];
            if (old.tipo == ARRAY)
            {
                if (old.valor)
                    liberarArray((ArrayValue *)old.valor);
            }
            else
            {
                if (old.valor)
                    free(old.valor);
            }
            current->valores[index_last] = nuevo_valor;
        }
        return nuevoValorResultadoVacio();
    }

    // Si no es identificador ni acceso a arreglo, error
    add_error_to_report("Semantico", "++/--", "El operando no es un l-value válido.", lvalue_expr->line, lvalue_expr->column, context->nombre_completo);
    if (nuevo_valor.tipo == ARRAY)
        liberarArray((ArrayValue *)nuevo_valor.valor);
    else
        free(nuevo_valor.valor);
    return nuevoValorResultadoVacio();
}

// Función de interpretación
static Result interpretPostfixExpresion(AbstractExpresion *self, Context *context)
{
    PostfixExpresion *nodo = (PostfixExpresion *)self;
    AbstractExpresion *lvalue = self->hijos[0];

    Result actual = lvalue->interpret(lvalue, context);

    // Debe ser INT/FLOAT/DOUBLE/CHAR/BOOLEAN para ++/--
    if (actual.tipo == ARRAY || actual.tipo == STRING || actual.tipo == NULO)
    {
        add_error_to_report("Semantico", "++/--", "El operador postfix solo se aplica a tipos numéricos.", self->line, self->column, context->nombre_completo);
        if (actual.valor)
            free(actual.valor);
        return nuevoValorResultadoVacio();
    }

    // Guardar valor antiguo para retorno
    Result retorno;
    retorno.tipo = actual.tipo;
    if (actual.tipo == STRING || actual.tipo == ARRAY)
    {
        retorno.valor = NULL;
    }

    // Copia profunda para primitivos
    else
    {
        size_t size = sizeof(int);
        if (actual.tipo == FLOAT)
            size = sizeof(float);
        else if (actual.tipo == DOUBLE)
            size = sizeof(double);
        retorno.valor = malloc(size);
        memcpy(retorno.valor, actual.valor, size);
    }

    // Calcular nuevo valor
    Result nuevo;
    nuevo.tipo = actual.tipo;
    if (actual.tipo == INT || actual.tipo == CHAR || actual.tipo == BOOLEAN)
    {
        int v = actual.valor ? *(int *)actual.valor : 0;
        if (nodo->op_token == TOKEN_INCREMENTO)
            v += 1;
        else
            v -= 1;
        nuevo.valor = malloc(sizeof(int));
        *(int *)nuevo.valor = v;
    }

    // Manejo de FLOAT y DOUBLE
    else if (actual.tipo == FLOAT)
    {
        float v = actual.valor ? *(float *)actual.valor : 0.0f;
        if (nodo->op_token == TOKEN_INCREMENTO)
            v += 1.0f;
        else
            v -= 1.0f;
        nuevo.valor = malloc(sizeof(float));
        *(float *)nuevo.valor = v;
    }
    else if (actual.tipo == DOUBLE)
    {
        double v = actual.valor ? *(double *)actual.valor : 0.0;
        if (nodo->op_token == TOKEN_INCREMENTO)
            v += 1.0;
        else
            v -= 1.0;
        nuevo.valor = malloc(sizeof(double));
        *(double *)nuevo.valor = v;
    }

    // Otros tipos no soportados
    else
    {
        add_error_to_report("Semantico", "++/--", "Tipo no soportado para postfix.", self->line, self->column, context->nombre_completo);
        free(actual.valor);
        free(retorno.valor);
        return nuevoValorResultadoVacio();
    }

    // Escribir de vuelta en el l-value el nuevo valor
    write_back_to_lvalue(lvalue, context, nuevo);

    // Liberar el valor leído
    if (actual.valor)
        free(actual.valor);

    // Retornar el valor antiguo
    return retorno;
}

// Constructor del nodo Postfix
AbstractExpresion *nuevoPostfixExpresion(AbstractExpresion *lvalue_expr, int op_token, int line, int column)
{
    PostfixExpresion *nodo = malloc(sizeof(PostfixExpresion));
    if (!nodo)
        return NULL;
    buildAbstractExpresion(&nodo->base, interpretPostfixExpresion, "Postfix", line, column);
    nodo->op_token = op_token;
    agregarHijo((AbstractExpresion *)nodo, lvalue_expr);
    return (AbstractExpresion *)nodo;
}
