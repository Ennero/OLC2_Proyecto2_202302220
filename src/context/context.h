#ifndef CONTEXT_H
#define CONTEXT_H

#include "result.h"
#include <stddef.h> 

typedef struct AbstractExpresion AbstractExpresion;

typedef enum
{
    VARIABLE,
    FUNCION,
    STRUCT,
} Clase;

// Información sobre un parámetro de función
typedef struct
{
    TipoDato tipo;   // Tipo base
    int dimensiones; // 0 si escalar; >0 si arreglo
    char *nombre;
} Parametro;

// Información sobre una variable
typedef struct
{
    void *valor;  // Puntero al valor 
    int borrowed; // 1 si es una referencia a un arreglo existente
} VariableInfo;

// Información sobre una función
typedef struct
{
    TipoDato tipo_retorno;     // Tipo base de retorno 
    int retorno_dimensiones;   // 0 si escalar; >0 si retorna arreglo
    Parametro *parametros;     // Array dinámico de parámetros
    size_t num_parametros;     // Número de parámetros
    AbstractExpresion *cuerpo; // Puntero al AST del bloque de la función
} FuncionInfo;

typedef struct Symbol Symbol;
typedef struct Context Context;

// Estructura para un símbolo 
struct Symbol
{
    char *nombre;
    Clase clase;
    TipoDato tipo; // Para var: su tipo. Para func: su tipo de retorno.
    union
    {
        VariableInfo var;
        FuncionInfo func;
    } info;
    int es_constante; // 1 si fue declarada con 'final'
    int line;
    int column;
    Symbol *anterior;
};

// Estructura para un contexto (tabla de símbolos y enlace al contexto padre)
struct Context
{
    char *nombre_completo;
    Context *anterior;
    Symbol *ultimoSymbol;
    Context *raiz;         // Puntero al contexto raíz 
    int proximo_id_bloque; // Contador utilizado por la raíz 

    // Profundidad de regiones que permiten 'break' y 'continue'
    int breakable_depth;   // >0 cuando estamos dentro de while/for/switch
    int continuable_depth; // >0 cuando estamos dentro de while/for
};

Context *nuevoContext(Context *anterior, const char *tipo_contexto);
void liberarContext(Context *context); // Libera el contexto y sus símbolos
Symbol *nuevoVariable(char *nombre, void *valor, TipoDato tipo, int es_constante);
void agregarSymbol(Context *actual, Symbol *symbol, int line, int column);
Symbol *buscarSymbol(Symbol *actual, char *nombre);
Symbol *buscarTablaSimbolos(Context *actual, char *nombre);

#endif // CONTEXT_H