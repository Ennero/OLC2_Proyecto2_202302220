#include "ast/nodos/builders.h"
#include "context/array_value.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <string.h>

Result interpretAccesoArreglo(AbstractExpresion* self, Context* context) {

    int depth = 0;
    AbstractExpresion* it = self;
    while (it && strcmp(it->node_type, "ArrayAccess") == 0) {
        depth++;
        it = it->hijos[0];
    }
    AbstractExpresion* base_expr = it; // Debe producir un ARRAY

    // Recolectar nodos de índices
    AbstractExpresion** idx_nodes = malloc(sizeof(AbstractExpresion*) * (size_t)depth);
    if (!idx_nodes) return nuevoValorResultadoVacio();
    it = self;
    for (int i = 0; i < depth; ++i) {
        idx_nodes[i] = it->hijos[1];
        it = it->hijos[0];
    }

    // Evaluar la base una sola vez
    Result base_res = base_expr->interpret(base_expr, context);
    if (base_res.tipo != ARRAY || base_res.valor == NULL) {
        add_error_to_report("Semantico", "[]", "Se intentó indexar una variable que no es un arreglo.", self->line, self->column, context->nombre_completo);
        free(idx_nodes);
        if (base_res.valor) free(base_res.valor); // Solo por seguridad si alguien devolvió copia
        return nuevoValorResultadoVacio();
    }

    ArrayValue* current = (ArrayValue*)base_res.valor; // Referencia

    // Aplicar índices desde el más interno al más externo, dejando el último para el retorno
    for (int i = depth - 1; i >= 1; --i) {
        Result idx_res = idx_nodes[i]->interpret(idx_nodes[i], context);
        if (idx_res.tipo != INT) {
            add_error_to_report("Semantico", "[]", "El índice de un arreglo debe ser un entero.", self->line, self->column, context->nombre_completo);
            free(idx_res.valor);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }

        // Índice válido
        int index = *(int*)idx_res.valor;
        free(idx_res.valor);
        if (!current || index < 0 || index >= current->tamano) {
            add_error_to_report("Semantico", "[]", "Índice fuera de los límites del arreglo.", self->line, self->column, context->nombre_completo);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }

        // Navegar a la siguiente dimensión
        Result elem = current->valores[index];
        if (elem.tipo != ARRAY || elem.valor == NULL) {
            add_error_to_report("Semantico", "[]", "Se esperaba un sub-arreglo al navegar dimensiones.", self->line, self->column, context->nombre_completo);
            free(idx_nodes);
            return nuevoValorResultadoVacio();
        }
        current = (ArrayValue*)elem.valor; // Avanzar a la siguiente dimensión
    }

    // Último índice retorna el elemento
    Result idx_last = idx_nodes[0]->interpret(idx_nodes[0], context);
    if (idx_last.tipo != INT) {
        add_error_to_report("Semantico", "[]", "El índice de un arreglo debe ser un entero.", self->line, self->column, context->nombre_completo);
        free(idx_last.valor);
        free(idx_nodes);
        return nuevoValorResultadoVacio();
    }
    int index_last = *(int*)idx_last.valor;
    free(idx_last.valor);
    free(idx_nodes);

    if (!current || index_last < 0 || index_last >= current->tamano) {
        add_error_to_report("Semantico", "[]", "Índice fuera de los límites del arreglo.", self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    Result elemento = current->valores[index_last];
    Result out;
    out.tipo = elemento.tipo;

    // Hacer copia profunda del valor si no es ARRAY
    if (elemento.tipo == ARRAY) {
        out.valor = elemento.valor;
    } else {
        if (elemento.tipo == STRING) {
            out.valor = elemento.valor ? strdup((char*)elemento.valor) : NULL;
        } else {
            size_t size = sizeof(int);
            if (elemento.tipo == FLOAT) size = sizeof(float);
            if (elemento.tipo == DOUBLE) size = sizeof(double);
            out.valor = malloc(size);
            if (out.valor && elemento.valor) memcpy(out.valor, elemento.valor, size);
        }
    }
    return out;
}

// Constructor para nodo de acceso a arreglo
AbstractExpresion* nuevoAccesoArreglo(AbstractExpresion* base, AbstractExpresion* indice, int line, int column) {
    AbstractExpresion* nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretAccesoArreglo, "ArrayAccess", line, column);
    agregarHijo(nodo, base);
    agregarHijo(nodo, indice);
    return nodo;
}