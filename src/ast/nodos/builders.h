#ifndef BUILDERS_H
#define BUILDERS_H

#include "ast/AbstractExpresion.h"

/*
    Así como dijo el aux, este archivo es como un catálogo
    para cada tipo de nodo que puede existir en el Árbol de Sintaxis Abstracta (AST).
    El parser lo utiliza para construir el árbol durante el análisis.
*/

// Constructor de instrucciones y expresiones
AbstractExpresion *nuevoInstruccionesExpresion(void);
AbstractExpresion *nuevoListaExpresiones(void);

// Constructor de declaraciones y asignaciones
AbstractExpresion *nuevoDeclaracionVariable(TipoDato tipo, int dimensiones, char *nombre, AbstractExpresion *expresion, int line, int column);
AbstractExpresion *nuevoReasignacionExpresion(char *nombre, AbstractExpresion *expresion, int line, int column);
AbstractExpresion *nuevoAsignacionCompuestaExpresion(char *nombre, int op_type, AbstractExpresion *expresion, int line, int column);

// Constructor de bloques
AbstractExpresion *nuevoBloqueExpresion(AbstractExpresion *lSentencia, int line, int column);

// Constructor de casteo
AbstractExpresion *nuevoCasteoExpresion(TipoDato tipo_destino, AbstractExpresion *expresion, int line, int column);

// Constructores de Nodos de Expresiones Terminales
AbstractExpresion *nuevoPrimitivoExpresion(char *valor, TipoDato tipo, int line, int column);
AbstractExpresion *nuevoIdentificadorExpresion(char *nombre, int line, int column);

// Constructores de Nodos de Expresiones Aritméticas
AbstractExpresion *nuevoSumaExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoRestaExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoMultiplicacionExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoDivisionExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoModuloExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoUnarioExpresion(AbstractExpresion *expresion, int line, int column);

// Constructores de Nodos de Expresiones Relacionales
AbstractExpresion *nuevoIgualExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoDiferenteExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoMenorQueExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoMayorQueExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoMenorIgualExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoMayorIgualExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoEqualsExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);

// Constructores de Nodos de Expresiones Lógicas
AbstractExpresion *nuevoAndExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoOrExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoNotExpresion(AbstractExpresion *expresion, int line, int column);

// Constructores de Nodos de Expresiones Bit a Bit
AbstractExpresion *nuevoBitwiseAndExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoBitwiseOrExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoBitwiseXorExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoBitwiseNotExpresion(AbstractExpresion *expresion, int line, int column);
AbstractExpresion *nuevoPostfixExpresion(AbstractExpresion *lvalue_expr, int op_token, int line, int column);

// Constructores de Nodos de Desplazamiento de Bits
AbstractExpresion *nuevoLeftShiftExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoRightShiftExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);
AbstractExpresion *nuevoUnsignedRightShiftExpresion(AbstractExpresion *izquierda, AbstractExpresion *derecha, int line, int column);

// Constructor de Nodos de Control de Flujo
AbstractExpresion *nuevoIfExpresion(AbstractExpresion *condicion, AbstractExpresion *bloque_if, AbstractExpresion *bloque_else, int line, int column);

// Ciclo while
AbstractExpresion *nuevoWhileExpresion(AbstractExpresion *condicion, AbstractExpresion *bloque, int line, int column);

// Ciclo for
AbstractExpresion *nuevoForExpresion(AbstractExpresion *init, AbstractExpresion *cond, AbstractExpresion *update, AbstractExpresion *bloque, int line, int column);
AbstractExpresion *nuevoForEachExpresion(TipoDato tipo, int dimensiones, char *nombre, AbstractExpresion *array_expr, AbstractExpresion *bloque, int line, int column);

// Switch
AbstractExpresion *nuevoSwitchExpresion(AbstractExpresion *expresion, AbstractExpresion *case_list, int line, int column);
AbstractExpresion *nuevoCaseExpresion(AbstractExpresion *expresion, AbstractExpresion *sentencias, int line, int column);
AbstractExpresion *nuevoDefaultExpresion(AbstractExpresion *sentencias, int line, int column);

// Constructores de Nodos de Control de Flujo
AbstractExpresion *nuevoBreakExpresion(int line, int column);
AbstractExpresion *nuevoContinueExpresion(int line, int column);
AbstractExpresion *nuevoReturnExpresion(AbstractExpresion *expresion, int line, int column);

// Constructores de Nodos de Estructura
AbstractExpresion *nuevoMainFunctionNode(AbstractExpresion *bloque, int line, int column);

// Arreglos
AbstractExpresion *nuevoTipoNode(TipoDato tipo);
AbstractExpresion *nuevoCreacionArreglo(AbstractExpresion *tipo, AbstractExpresion *dimensiones, int line, int column);
AbstractExpresion *nuevoAccesoArreglo(AbstractExpresion *base, AbstractExpresion *indice, int line, int column);
AbstractExpresion *nuevoInicializadorArreglo(AbstractExpresion *lista_exp, int line, int column);

// Funciones
AbstractExpresion *nuevoDeclaracionFuncion(TipoDato tipo_retorno, char *nombre, AbstractExpresion *params, AbstractExpresion *bloque, int line, int column);
AbstractExpresion *nuevoParametro(TipoDato tipo, int dimensiones, char *nombre);
AbstractExpresion *nuevoLlamadaFuncion(char *nombre, AbstractExpresion *args, int line, int column);
AbstractExpresion *nuevoAsignacionArreglo(AbstractExpresion *id, AbstractExpresion *indice, AbstractExpresion *expr, int line, int column);

// Funciones Embebidas
AbstractExpresion *nuevoParseIntExpresion(AbstractExpresion *expr, int line, int column);
AbstractExpresion *nuevoParseFloatExpresion(AbstractExpresion *expr, int line, int column);
AbstractExpresion *nuevoParseDoubleExpresion(AbstractExpresion *expr, int line, int column);
AbstractExpresion *nuevoStringValueofExpresion(AbstractExpresion *expr, int line, int column);
AbstractExpresion *nuevoStringJoinExpresion(AbstractExpresion *delimitador, AbstractExpresion *arreglo, int line, int column);
AbstractExpresion *nuevoPrintExpresion(AbstractExpresion *listaExpresiones, int line, int column);
AbstractExpresion *nuevoArrayLengthExpresion(AbstractExpresion *arr_expr, int line, int column);

// Métodos de Arreglos
AbstractExpresion *nuevoArraysIndexofExpresion(AbstractExpresion *arr_expr, AbstractExpresion *val_expr, int line, int column);
AbstractExpresion *nuevoArrayAddExpresion(AbstractExpresion *arr_expr, AbstractExpresion *elem_expr, int line, int column);

#endif
