// src/.../transferencia/return.c
#include "ast/nodos/builders.h"
#include <stdlib.h>

// La función que interpreta una instrucción de retorno
Result interpretReturnExpresion(AbstractExpresion *self, Context *context)
{
    Result valor_a_retornar;

    // Comprobar si hay una expresión de retorno
    if (self->numHijos > 0)
    {
        valor_a_retornar = self->hijos[0]->interpret(self->hijos[0], context);
    }
    // Si no hay expresión, el valor a retornar es vacío (void)
    else
    {
        valor_a_retornar = nuevoValorResultadoVacio();
    }

    // Para poder propagar el valor de retorno COMPLETO lo "envolvemos" en un puntero.
    Result *resultado_envuelto = malloc(sizeof(Result));
    *resultado_envuelto = valor_a_retornar;

    // Devolvemos la señal RETURN_T, llevando el resultado envuelto como carga.
    return nuevoValorResultado(resultado_envuelto, RETURN_T);
}

// El constructor para el nodo de instrucción de retorno
AbstractExpresion *nuevoReturnExpresion(AbstractExpresion *expresion, int line, int column)
{
    // Crear un nuevo nodo de retorno
    AbstractExpresion *nodo = malloc(sizeof(AbstractExpresion));
    buildAbstractExpresion(nodo, interpretReturnExpresion, "ReturnStatement", line, column);
    
    // Si hay una expresión, agregarla como hijo
    if (expresion)
    {
        agregarHijo(nodo, expresion);
    }
    return nodo;
}