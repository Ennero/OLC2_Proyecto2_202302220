#ifndef RESULT_H
#define RESULT_H

// Definición de tipos de datos
typedef enum
{
    BOOLEAN,
    CHAR,
    INT,
    FLOAT,
    DOUBLE,
    STRING,
    ARRAY,
    BREAK_T,
    CONTINUE_T,
    RETURN_T,
    NULO,
    TIPO_COUNT
} TipoDato;

// Etiquetas legibles para los tipos de datos
extern char *labelTipoDato[];

// Estructura para el resultado de una expresión
typedef struct
{
    TipoDato tipo;
    void *valor;
} Result;

// Funciones para manejar resultados
TipoDato tipoResultante(Result, Result);
Result nuevoValorResultado(void *valor, TipoDato tipo);
Result nuevoValorResultadoVacio(void);

// Utilidades de conversión (widening casting implícito)
int can_widen(TipoDato from, TipoDato to);

// Convierte un Result primitivo a 'to'
Result widen_to(Result src, TipoDato to);

#endif