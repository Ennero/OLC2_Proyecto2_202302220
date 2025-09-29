#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/array_value.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <string.h>
#include "ast/nodos/expresiones/terminales/identificadores.h"

// Función para encontrar el nodo Identificador en la base de un acceso a arreglo
static AbstractExpresion *findBaseIdentifierNode(AbstractExpresion *expr)
{
    // Si el nodo actual ya es el identificador, lo hemos encontrado.
    if (strcmp(expr->node_type, "Identificador") == 0)
    {
        return expr;
    }
    // Si es un acceso a un arreglo, la base está en su primer hijo.
    if (strcmp(expr->node_type, "ArrayAccess") == 0)
    {
        return findBaseIdentifierNode(expr->hijos[0]);
    }
    return NULL;
}

// Función de interpretación para el nodo AsignacionArreglo
Result interpretAsignacionArreglo(AbstractExpresion *self, Context *context)
{
    AbstractExpresion *acceso_nodo = self->hijos[0]; // El lado izquierdo
    AbstractExpresion *valor_nodo = self->hijos[1];  // El lado derecho

    // Encontrar el nombre de la variable base del lado izquierdo.
    AbstractExpresion *id_base_nodo = findBaseIdentifierNode(acceso_nodo);
    if (!id_base_nodo)
    {
        add_error_to_report("Semantico", "=", "El lado izquierdo de la asignación no es una variable válida.", self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Buscar la variable en la tabla de símbolos
    char *nombre_base = ((IdentificadorExpresion *)id_base_nodo)->nombre;
    Symbol *simbolo = buscarTablaSimbolos(context, nombre_base);

    // Validaciones
    if (!simbolo || simbolo->tipo != ARRAY)
    {
        add_error_to_report("Semantico", nombre_base, "La variable no es un arreglo o no ha sido declarada.", self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Contar profundidad
    int depth = 0;
    AbstractExpresion *iter = acceso_nodo;
    while (strcmp(iter->node_type, "ArrayAccess") == 0)
    {
        depth++;
        iter = iter->hijos[0];
    }

    // Guardar punteros a las expresiones de índices en un arreglo
    AbstractExpresion **idx_nodes = malloc(sizeof(AbstractExpresion *) * (size_t)depth);
    if (!idx_nodes)
        return nuevoValorResultadoVacio();

    // Recolectar nodos de índice
    iter = acceso_nodo;
    for (int i = 0; i < depth; i++)
    {
        idx_nodes[i] = iter->hijos[1];
        iter = iter->hijos[0];
    }

    // Navegar por las dimensiones del arreglo hasta llegar a la posición deseada
    ArrayValue *current_array = (ArrayValue *)simbolo->info.var.valor;

    // Navegar por todos los índices excepto el último, en orden interno->externo
    for (int i = depth - 1; i >= 1; --i)
    {
        // Evaluar el índice actual
        Result res_idx = idx_nodes[i]->interpret(idx_nodes[i], context);
        // Validar que sea entero
        if (res_idx.tipo != INT)
        {
            add_error_to_report("Semantico", "[]", "El índice de un arreglo debe ser un entero.", self->line, self->column, context->nombre_completo);
            free(res_idx.valor);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }
        int index = *(int *)res_idx.valor;
        free(res_idx.valor);
        // Validar límites y existencia del sub-arreglo
        if (!current_array || index < 0 || index >= current_array->tamano)
        {
            add_error_to_report("Semantico", "[]", "Índice fuera de los límites del arreglo en una asignación.", self->line, self->column, context->nombre_completo);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }
        // Mover a la siguiente dimensión
        Result elem = current_array->valores[index];
        if (elem.tipo != ARRAY || elem.valor == NULL)
        {
            add_error_to_report("Semantico", "[]", "Se esperaba un sub-arreglo al navegar dimensiones (arreglo irregular no instanciado).", self->line, self->column, context->nombre_completo);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }
        current_array = (ArrayValue *)elem.valor;
    }

    // Evaluar el índice final más externo y el nuevo valor
    Result res_idx_final = idx_nodes[0]->interpret(idx_nodes[0], context);
    // Validar que sea entero
    if (res_idx_final.tipo != INT)
    {
        add_error_to_report("Semantico", "[]", "El índice de un arreglo debe ser un entero.", self->line, self->column, context->nombre_completo);
        free(res_idx_final.valor);
        free(idx_nodes);
        return nuevoValorResultadoVacio();
    }
    int index_final = *(int *)res_idx_final.valor;
    free(res_idx_final.valor);

    Result nuevo_valor = valor_nodo->interpret(valor_nodo, context);

    // Validar y realizar la asignación en el arreglo original
    if (!current_array || index_final < 0 || index_final >= current_array->tamano)
    {
        add_error_to_report("Semantico", "[]", "Índice fuera de los límites del arreglo en una asignación.", self->line, self->column, context->nombre_completo);
        free(nuevo_valor.valor);
        free(idx_nodes);
        return nuevoValorResultadoVacio();
    }

    // Navegar por las dimensiones del arreglo hasta llegar a la posición deseada
    int remaining_dims = current_array->dimensiones_total;
    if (remaining_dims <= 1)
    {
        // Asignación a elemento primitivo
        if (nuevo_valor.tipo != current_array->tipo_elemento_base)
        {
            add_error_to_report("Semantico", "=", "Tipo incompatible en la asignación al elemento del arreglo.", self->line, self->column, context->nombre_completo);
            free(nuevo_valor.valor);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }
        // Liberar valor previo correctamente
        Result old = current_array->valores[index_final];

        // Si el valor previo era un arreglo, liberar recursivamente
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
        current_array->valores[index_final] = nuevo_valor;
    }
    else
    {
        // Asignación a una posición que debe contener un sub-arreglo
        if (nuevo_valor.tipo != ARRAY || nuevo_valor.valor == NULL)
        {
            // Se esperaba un arreglo
            add_error_to_report("Semantico", "=", "Se esperaba un arreglo para asignar en una dimensión intermedia (multidimensional).", self->line, self->column, context->nombre_completo);
            if (nuevo_valor.valor)
                free(nuevo_valor.valor);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }

        // Validar compatibilidad del sub-arreglo
        ArrayValue *sub = (ArrayValue *)nuevo_valor.valor;
        if (sub->tipo_elemento_base != current_array->tipo_elemento_base)
        {
            add_error_to_report("Semantico", "=", "Tipo base incompatible entre el sub-arreglo asignado y el arreglo de destino.", self->line, self->column, context->nombre_completo);
            liberarArray(sub);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }

        // Validar dimensiones
        if (sub->dimensiones_total != remaining_dims - 1)
        {
            add_error_to_report("Semantico", "=", "Dimensionalidad incompatible en la asignación del sub-arreglo.", self->line, self->column, context->nombre_completo);
            liberarArray(sub);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }

        // Liberar valor previo correctamente y asignar el nuevo sub-arreglo
        Result old = current_array->valores[index_final];
        if (old.tipo == ARRAY)
        {
            if (old.valor)
                liberarArray((ArrayValue *)old.valor);
        }
        // Si no es ARRAY, solo liberar el puntero (error en el estado del arreglo)
        else
        {
            if (old.valor)
                free(old.valor);
        }
        current_array->valores[index_final] = nuevo_valor; // transfiere la propiedad del puntero
    }

    free(idx_nodes);

    return nuevoValorResultadoVacio();
}

// El constructor
AbstractExpresion *nuevoAsignacionArreglo(AbstractExpresion *base, AbstractExpresion *indice, AbstractExpresion *expr, int line, int column)
{
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretAsignacionArreglo, "ArrayAssignment", line, column);

    AbstractExpresion *acceso = nuevoAccesoArreglo(base, indice, line, column);

    agregarHijo(nodo, acceso);
    agregarHijo(nodo, expr);

    return nodo;
}