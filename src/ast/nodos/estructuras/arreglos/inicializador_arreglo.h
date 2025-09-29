#ifndef INICIALIZADOR_ARREGLO_H
#define INICIALIZADOR_ARREGLO_H

#include "ast/AbstractExpresion.h"
#include "context/array_value.h"
#include "ast/nodos/instrucciones/instruccion/declaracion.h"

ArrayValue *construirDesdeInicializador(
    DeclaracionVariable *decl_node,
    Context *context,
    AbstractExpresion *current_list,
    TipoDato tipo_esperado,
    int dimension_esperada);

#endif // INICIALIZADOR_ARREGLO_H