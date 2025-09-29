#include "asignacion_compuesta.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "ast/nodos/expresiones/aritmeticas/aritmeticas.h"
#include "ast/nodos/expresiones/bit/bitwise.h"
#include "parser.tab.h"

// Función para obtener la tabla de operaciones correcta
static Operacion (*get_op_table(int op_type))[TIPO_COUNT][TIPO_COUNT]
{
    switch (op_type)
    {
    case '+':
        return &tablaOperacionesSuma;
    case '-':
        return &tablaOperacionesResta;
    case '*':
        return &tablaOperacionesMultiplicacion;
    case '/':
        return &tablaOperacionesDivision;
    case '%':
        return &tablaOperacionesModulo;
    case '&':
        return &tablaOperacionesBitwiseAnd;
    case '|':
        return &tablaOperacionesBitwiseOr;
    case '^':
        return &tablaOperacionesBitwiseXor;
    case TOKEN_LSHIFT:
        return &tablaOperacionesLeftShift;
    case TOKEN_RSHIFT:
        return &tablaOperacionesRightShift;
    case TOKEN_URSHIFT:
        return &tablaOperacionesUnsignedRightShift;
    default:
        return NULL;
    }
}

// Función para obtener el tamaño en bytes de un tipo de dato
static size_t get_type_size(TipoDato tipo)
{
    switch (tipo)
    {
    case INT:
    case BOOLEAN:
    case CHAR:
        return sizeof(int);
    case FLOAT:
        return sizeof(float);
    case DOUBLE:
        return sizeof(double);
    default:
        return 0;
    }
}

// Función para obtener el string del operador para los mensajes de error
static const char *get_op_string(int op_type)
{
    switch (op_type)
    {
    case '+':
        return "+=";
    case '-':
        return "-=";
    case '*':
        return "*=";
    case '/':
        return "/=";
    case '%':
        return "%=";
    case '&':
        return "&=";
    case '|':
        return "|=";
    case '^':
        return "^=";
    case TOKEN_LSHIFT:
        return "<<=";
    case TOKEN_RSHIFT:
        return ">>=";
    case TOKEN_URSHIFT:
        return ">>>=";
    default:
        return "?=";
    }
}

// La función que interpreta una instrucción de asignación compuesta
Result interpretAsignacionCompuesta(AbstractExpresion *self, Context *context)
{
    // Obtener el nodo específico de asignación compuesta
    AsignacionCompuestaExpresion *nodo = (AsignacionCompuestaExpresion *)self;
    Symbol *simbolo = buscarTablaSimbolos(context, nodo->nombre);

    // Verificar que el símbolo exista y sea una variable
    if (!simbolo || simbolo->clase != VARIABLE)
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "La variable '%s' no ha sido declarada.", nodo->nombre);
        add_error_to_report("Semantico", nodo->nombre, desc, nodo->line, nodo->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Si es constante, no se puede reasignar
    if (simbolo->es_constante)
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "No se puede usar una asignación compuesta sobre la constante 'final' '%s'.", nodo->nombre);
        add_error_to_report("Semantico", nodo->nombre, desc, self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    ExpresionLenguaje expr_simulada;

    // Creamos una copia del valor actual para la operación, para no modificar el original prematuramente.
    void *valor_izquierdo_copiado;

    // Si es string, usamos strdup para copiar
    if (simbolo->tipo == STRING)
    {
        valor_izquierdo_copiado = strdup((char *)simbolo->info.var.valor);
    }
    // Si es arreglo o nulo, no se puede operar
    else if (simbolo->tipo == ARRAY || simbolo->info.var.valor == NULL)
    {
        char desc[256];
        snprintf(desc, sizeof(desc), "No se puede usar una asignación compuesta sobre la variable '%s' de tipo '%s'.", nodo->nombre, labelTipoDato[simbolo->tipo]);
        add_error_to_report("Semantico", nodo->nombre, desc, self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }
    // Si es un tipo primitivo, hacemos una copia del valor
    else
    {
        size_t size = get_type_size(simbolo->tipo); // Obtener el tamaño del tipo

        // Si el tipo no es soportado, error
        if (size == 0)
        {
            char desc[256];
            snprintf(desc, sizeof(desc), "Tipo de dato '%s' no soporta asignaciones compuestas.", labelTipoDato[simbolo->tipo]);
            add_error_to_report("Semantico", nodo->nombre, desc, self->line, self->column, context->nombre_completo);
            return nuevoValorResultadoVacio();
        }
        // Alocar memoria y copiar el valor
        valor_izquierdo_copiado = malloc(size);

        memcpy(valor_izquierdo_copiado, simbolo->info.var.valor, size);
    }

    // Configurar la expresión simulada
    expr_simulada.izquierda = nuevoValorResultado(valor_izquierdo_copiado, simbolo->tipo);
    expr_simulada.derecha = self->hijos[0]->interpret(self->hijos[0], context);

    // Si hubo un error semántico durante la evaluación
    if (has_semantic_error_been_found())
    {
        free(expr_simulada.izquierda.valor);
        free(expr_simulada.derecha.valor);
        return nuevoValorResultadoVacio();
    }

    // Obtener la tabla de operaciones adecuada
    Operacion(*tabla)[TIPO_COUNT][TIPO_COUNT] = get_op_table(nodo->op_type);
    if (!tabla)
    {
        add_error_to_report("Semantico", get_op_string(nodo->op_type), "Operador compuesto no soportado.", self->line, self->column, context->nombre_completo);
        return nuevoValorResultadoVacio();
    }

    // Obtener la operación adecuada
    Operacion op = (*tabla)[expr_simulada.izquierda.tipo][expr_simulada.derecha.tipo];
    if (!op)
    {
        char description[256];
        snprintf(description, sizeof(description), "No se puede aplicar el operador '%s' entre tipos '%s' y '%s'.",
                 get_op_string(nodo->op_type),
                 labelTipoDato[expr_simulada.izquierda.tipo],
                 labelTipoDato[expr_simulada.derecha.tipo]);
        add_error_to_report("Semantico", get_op_string(nodo->op_type), description, self->line, self->column, context->nombre_completo);
        free(expr_simulada.izquierda.valor);
        free(expr_simulada.derecha.valor);
        return nuevoValorResultadoVacio();
    }

    Result nuevo_resultado = op(&expr_simulada);

    // Liberar los valores temporales usados en la operación
    if (simbolo->info.var.valor)
        free(simbolo->info.var.valor);
    simbolo->info.var.valor = nuevo_resultado.valor;
    simbolo->tipo = nuevo_resultado.tipo;

    return nuevoValorResultadoVacio();
}

// El constructor para el nodo de asignación compuesta
AbstractExpresion *nuevoAsignacionCompuestaExpresion(char *nombre, int op_type, AbstractExpresion *expresion, int line, int column)
{
    // Crear un nuevo nodo de asignación compuesta
    AsignacionCompuestaExpresion *nodo = malloc(sizeof(AsignacionCompuestaExpresion));
    if (!nodo)
        return NULL;

    // Inicializar el nodo base
    buildAbstractExpresion(&nodo->base, interpretAsignacionCompuesta, "AsignacionCompuesta", line, column);
    nodo->nombre = nombre;
    nodo->op_type = op_type;
    nodo->line = line;
    nodo->column = column;

    agregarHijo((AbstractExpresion *)nodo, expresion);

    return (AbstractExpresion *)nodo;
}