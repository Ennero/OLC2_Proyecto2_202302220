#include "funcion.h"
#include "parametro.h"
#include "ast/nodos/builders.h"
#include "context/context.h"
#include "error_reporter.h"
#include <stdlib.h>
#include <string.h>
#include <strings.h>

// Interpretar una declaración
Result interpretDeclaracionFuncion(AbstractExpresion *self, Context *context)
{
    // Extraemos los datos del nodo
    FuncionDeclarationNode *nodo = (FuncionDeclarationNode *)self;
    AbstractExpresion *params_list = self->hijos[0];
    AbstractExpresion *bloque_cuerpo = self->hijos[1];

    // Se crea un símbolo de tipo FUNCION para guardarlo en la tabla
    Symbol *func_symbol = malloc(sizeof(Symbol));

    // Duplicamos el nombre para que el símbolo sea dueño de su memoria
    func_symbol->nombre = strdup(nodo->nombre);
    func_symbol->clase = FUNCION;
    func_symbol->tipo = nodo->tipo_retorno; // El tipo del símbolo es el tipo de retorno

    // Se llena la información específica de la función dentro de la union
    func_symbol->info.func.tipo_retorno = nodo->tipo_retorno;
    func_symbol->info.func.retorno_dimensiones = nodo->retorno_dimensiones;
    func_symbol->info.func.cuerpo = bloque_cuerpo;
    func_symbol->info.func.num_parametros = params_list->numHijos;
    func_symbol->info.func.parametros = malloc(sizeof(Parametro) * params_list->numHijos);

    // Convertimos los nodos AST de parámetro a nuestra estructura de datos Parametro
    for (size_t i = 0; i < params_list->numHijos; i++)
    {
        ParametroNode *param_nodo = (ParametroNode *)params_list->hijos[i];
        func_symbol->info.func.parametros[i].tipo = param_nodo->tipo;
        func_symbol->info.func.parametros[i].dimensiones = param_nodo->dimensiones;
        func_symbol->info.func.parametros[i].nombre = strdup(param_nodo->nombre);
    }

    agregarSymbol(context, func_symbol, self->line, self->column);
    return nuevoValorResultadoVacio();
}

// Constructor del nodo DeclaracionFuncion
AbstractExpresion *nuevoDeclaracionFuncion(TipoDato tipo_retorno, char *nombre, AbstractExpresion *params, AbstractExpresion *bloque, int line, int column)
{
    // Reservar el espacio en memoria y obtener el puntero a este
    FuncionDeclarationNode *nodo = malloc(sizeof(FuncionDeclarationNode));
    buildAbstractExpresion(&nodo->base, interpretDeclaracionFuncion, "FunctionDeclaration", line, column);
    nodo->nombre = nombre;
    nodo->tipo_retorno = tipo_retorno;
    nodo->retorno_dimensiones = 0;

    agregarHijo((AbstractExpresion *)nodo, params);
    agregarHijo((AbstractExpresion *)nodo, bloque);

    return (AbstractExpresion *)nodo;
}