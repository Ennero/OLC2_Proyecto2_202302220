#include "declaracion.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "context/array_value.h"
#include "context/result.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "ast/nodos/estructuras/arreglos/inicializador_arreglo.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// La función que interpreta una declaración de variable
Result interpretDeclaracionVariable(AbstractExpresion *nodo, Context *context)
{
    // Obtener el nodo específico de declaración
    DeclaracionVariable *self = (DeclaracionVariable *)nodo;
    TipoDato tipo_declarado = (self->dimensiones > 0) ? ARRAY : self->tipo;

    // Si tiene asignacion
    if (nodo->numHijos > 0)
    {

        Result resultado = nodo->hijos[0]->interpret(nodo->hijos[0], context);

        // Si es un inicializador de arreglo
        if (strcmp(nodo->hijos[0]->node_type, "ArrayInitializer") == 0)
        {

            // Si las dimensiones son 0 (significa que no se puede usar un inicializador de arreglo), es un error
            if (self->dimensiones == 0)
            {
                add_error_to_report("Semantico", self->nombre, "La sintaxis de inicializador de arreglo solo es válida para declarar arreglos.", self->line, self->column, context->nombre_completo);
                return nuevoValorResultadoVacio();
            }

            // Construir el arreglo desde el inicializador
            AbstractExpresion *inicializador_nodo = (AbstractExpresion *)resultado.valor;
            ArrayValue *arr_val = NULL;

            // Si el inicializador está vacío (ej. int[] a = {};), crear un arreglo de tamaño 0.
            if (inicializador_nodo->numHijos == 0)
            {
                // Creamos un arreglo de tamaño 0.
                arr_val = nuevoArray(self->tipo, self->dimensiones, 0);
            }
            else
            {
                // Si no está vacío, construir desde el inicializador.
                AbstractExpresion *lista_de_expresiones = inicializador_nodo->hijos[0];
                arr_val = construirDesdeInicializador(self, context, lista_de_expresiones, self->tipo, self->dimensiones);
            }

            // Verificar si la construcción fue exitosa
            if (!arr_val)
            {
                // Si la construcción falló por un error de tipos, retornamos.
                return nuevoValorResultadoVacio();
            }
            // Agregar el símbolo a la tabla de símbolos
            agregarSymbol(context, nuevoVariable(self->nombre, arr_val, ARRAY, self->es_constante), self->line, self->column);
        }
        // Si no es un inicializador de arreglo
        else
        {
            // Inicialización por expresión
            if (self->dimensiones == 0)
            {
                // Permitir asignación de null para String
                if (resultado.tipo == NULO && self->tipo == STRING)
                {
                    agregarSymbol(context, nuevoVariable(self->nombre, NULL, self->tipo, self->es_constante), self->line, self->column);
                }
                else
                {
                    // Intentar permitir widening implícito si los tipos difieren
                    if (resultado.tipo != self->tipo)
                    {
                        // Caso especial: permitir int -> char (narrowing implícito estilo Java para char)
                        if (self->tipo == CHAR && resultado.tipo == INT)
                        {
                            // Convertir el int a un byte sin signo y almacenarlo como int (contrato interno)
                            int *p = malloc(sizeof(int));
                            *p = (int)((unsigned char)(*(int *)resultado.valor));
                            free(resultado.valor);
                            resultado.valor = p;
                            resultado.tipo = CHAR;
                        }
                        else if (can_widen(resultado.tipo, self->tipo))
                        {
                            resultado = widen_to(resultado, self->tipo);
                        }
                        else
                        {
                            char desc[256];
                            snprintf(desc, sizeof(desc), "Error de tipos: no se puede asignar un valor de tipo '%s' a la nueva variable '%s' de tipo '%s'.",
                                     labelTipoDato[resultado.tipo], self->nombre, labelTipoDato[self->tipo]);
                            add_error_to_report("Semantico", self->nombre, desc, self->line, self->column, context->nombre_completo);
                            return nuevoValorResultadoVacio();
                        }
                    }

                    // Guardar el puntero (ya convertido si aplicó widening)
                    void *valor_a_guardar = resultado.valor;
                    agregarSymbol(context, nuevoVariable(self->nombre, valor_a_guardar, self->tipo, self->es_constante), self->line, self->column);
                }
            }
            // Si es un arreglo
            else
            {
                // Permitir asignación de null para arreglos
                if (resultado.tipo == NULO)
                {
                    agregarSymbol(context, nuevoVariable(self->nombre, NULL, ARRAY, self->es_constante), self->line, self->column);
                    return nuevoValorResultadoVacio();
                }

                // Si no es de tipo arreglo, error
                if (resultado.tipo != ARRAY)
                {
                    char desc[256];
                    snprintf(desc, sizeof(desc), "Error de tipos: se esperaba un arreglo de tipo '%s' con %d dimensiones para inicializar '%s', pero se recibió '%s'.",
                             labelTipoDato[self->tipo], self->dimensiones, self->nombre, labelTipoDato[resultado.tipo]);
                    add_error_to_report("Semantico", self->nombre, desc, self->line, self->column, context->nombre_completo);
                    return nuevoValorResultadoVacio();
                }
                // Verificar que el arreglo recibido tenga el tipo y dimensiones esperadas
                ArrayValue *av = (ArrayValue *)resultado.valor;

                // Si el tipo base o dimensiones no coinciden, error
                if (av->tipo_elemento_base != self->tipo || av->dimensiones_total != self->dimensiones)
                {
                    char desc[256];
                    snprintf(desc, sizeof(desc), "Error de tipos: se esperaba %s[%dD] y se recibió %s[%dD] para '%s'.",
                             labelTipoDato[self->tipo], self->dimensiones,
                             labelTipoDato[av->tipo_elemento_base], av->dimensiones_total,
                             self->nombre);
                    add_error_to_report("Semantico", self->nombre, desc, self->line, self->column, context->nombre_completo);
                    return nuevoValorResultadoVacio();
                }
                // Copia profunda del arreglo para almacenar en símbolo
                void *valor_a_guardar = copiarArray(av);
                agregarSymbol(context, nuevoVariable(self->nombre, valor_a_guardar, ARRAY, self->es_constante), self->line, self->column);
            }
        }
    }
    // Si no tiene asignación
    else
    {
        // Si es constante, error
        if (self->es_constante)
        {
            add_error_to_report("Semantico", self->nombre, "Una constante 'final' debe ser inicializada en su declaración.", self->line, self->column, context->nombre_completo);
            return nuevoValorResultadoVacio();
        }
        // Si no es constante, inicializar con valor por defecto (0, false, null, etc.)
        void *default_value = NULL;

        if (tipo_declarado != ARRAY)
        { // Si es primitivo, crea valor por defecto
            default_value = getDefaultValueForType(self->tipo).valor;
        } // Si es arreglo, el valor por defecto es NULL
        agregarSymbol(context, nuevoVariable(self->nombre, default_value, tipo_declarado, 0), self->line, self->column);
    }
    return nuevoValorResultadoVacio();
}

// Constructor actualizado
AbstractExpresion *nuevoDeclaracionVariable(TipoDato tipo, int dimensiones, char *nombre, AbstractExpresion *expresion, int line, int column)
{
    DeclaracionVariable *nodo = malloc(sizeof(DeclaracionVariable));
    buildAbstractExpresion(&nodo->base, interpretDeclaracionVariable, "Declaracion", line, column);
    nodo->tipo = tipo;
    nodo->dimensiones = dimensiones;
    nodo->nombre = nombre;
    nodo->es_constante = 0;
    nodo->line = line;
    nodo->column = column;
    if (expresion)
        agregarHijo((AbstractExpresion *)nodo, expresion);
    return (AbstractExpresion *)nodo;
}