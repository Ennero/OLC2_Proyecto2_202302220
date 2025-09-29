%{
    // Código C que se incluye al inicio del archivo generado
    #include <stdio.h>
    #include <stdlib.h>
    #include "ast/AbstractExpresion.h"

    extern int yylex(void);
    extern AbstractExpresion* ast_root;
    void yyerror(const char *s);

    extern char* yylasttext; 
%}

/* Inclusión de headers necesarios para las acciones semánticas */
%code requires {
    #include "ast/nodos/builders.h"
    #include "context/result.h"
    #include "context/bloque.h"
    #include "error_reporter.h"
    #include "ast/nodos/instrucciones/instruccion/casteos.h"
    #include "ast/nodos/instrucciones/instruccion/reasignacion.h"
    #include "ast/nodos/instrucciones/instruccion/declaracion.h"
    #include "ast/nodos/estructuras/funciones/funcion.h"
    #include "ast/nodos/expresiones/terminales/identificadores.h"
    #include <string.h>
}


%code {
    // Estructuras de datos temporales para ayudar al parser a construir la declaración de una variable compleja

    typedef struct {
        AbstractExpresion base;
        int dimensiones;
        AbstractExpresion* inicializador;
        char* nombre;
    } DeclaradorNode;

    // Constructor para el nodo temporal
    AbstractExpresion* nuevoDeclaradorNode(char* nombre, int dims, AbstractExpresion* init) {
        DeclaradorNode* n = malloc(sizeof(DeclaradorNode));
        buildAbstractExpresion(&n->base, NULL, "TempDeclarator", 0, 0);
        n->nombre = nombre;
        n->dimensiones = dims;
        n->inicializador = init;
        return (AbstractExpresion*)n;
    }

    // Estructura temporal para manejar tipos completos con dimensiones
    typedef struct {
        AbstractExpresion base;
        TipoDato tipo;
        int dimensiones;
    } TipoCompletoNode;

    // Constructor para el nodo temporal de tipo completo
    AbstractExpresion* nuevoTipoCompletoNode(TipoDato tipo, int dims) {
        TipoCompletoNode* n = malloc(sizeof(TipoCompletoNode));
        buildAbstractExpresion(&n->base, NULL, "TempType", 0, 0);
        n->tipo = tipo;
        n->dimensiones = dims;
        return (AbstractExpresion*)n;
    }
}

/* Habilitar el seguimiento de ubicaciones (línea/columna) */
%locations

/* Unión de tipos semánticos */
%union {
    char* string;
    AbstractExpresion* nodo;
    TipoDato tipoDato;
    int num;
}

/* --- Declaración de Tokens --- */
%token TOKEN_PUBLIC TOKEN_STATIC TOKEN_VOID
%token TOKEN_FINAL
%token TOKEN_IF TOKEN_ELSE TOKEN_WHILE TOKEN_FOR TOKEN_SWITCH TOKEN_CASE
%token TOKEN_BREAK TOKEN_CONTINUE TOKEN_RETURN TOKEN_PRINT TOKEN_MAIN
%token TOKEN_DINT TOKEN_DFLOAT TOKEN_DDOUBLE TOKEN_DBOOLEAN TOKEN_DCHAR TOKEN_DSTRING
%token <string> TOKEN_IDENTIFIER TOKEN_INTEGER TOKEN_HEX_INTEGER TOKEN_DOUBLE_LIT
%token <string> TOKEN_CHAR_LITERAL TOKEN_STRING_LITERAL TOKEN_TRUE TOKEN_FALSE TOKEN_FLOAT_LIT
%token TOKEN_IGUAL_IGUAL TOKEN_DIFERENTE TOKEN_MAYOR_IGUAL TOKEN_MENOR_IGUAL
%token TOKEN_AND TOKEN_OR TOKEN_INCREMENTO TOKEN_DECREMENTO
%token TOKEN_LSHIFT TOKEN_RSHIFT TOKEN_URSHIFT 
%token TOKEN_PLUS_ASSIGN TOKEN_MINUS_ASSIGN TOKEN_MULT_ASSIGN TOKEN_DIV_ASSIGN TOKEN_MOD_ASSIGN
%token TOKEN_AND_ASSIGN TOKEN_OR_ASSIGN TOKEN_XOR_ASSIGN
%token TOKEN_LSHIFT_ASSIGN TOKEN_RSHIFT_ASSIGN TOKEN_URSHIFT_ASSIGN
%token TOKEN_DOT
%token TOKEN_DEFAULT
%token TOKEN_NEW
%token TOKEN_PARSE_INT TOKEN_PARSE_FLOAT
%token TOKEN_PARSE_DOUBLE TOKEN_STRING_VALUEOF TOKEN_STRING_JOIN
%token TOKEN_ARRAYS_INDEXOF TOKEN_LENGTH
%token TOKEN_NULL



/* --- Tipos para No-Terminales --- */
%type <nodo> lSentencia sentencia expr lista_Expr bloque declaracion_var primitivo primary_expr if_stmt switch_stmt case_list case_stmt lSentencia_opt programa lista_declaraciones declaracion declaracion_funcion lista_parametros_opt lista_parametros parametro lista_argumentos_opt declaracion_main while_stmt for_stmt for_init for_expr_opt
%type <nodo> inicializador_arreglo expresion_creacion_arreglo lista_dims_expr asignacion_expr
%type <nodo> declarador_completo var_tail lista_item for_head for_init_opt
%type <num> corchetes_lista dims_vacias
%type <tipoDato> tipoPrimitivo

/* --- Precedencia y Asociatividad de Operadores --- */
%left TOKEN_DOT
%left TOKEN_INCREMENTO TOKEN_DECREMENTO
%right '=' TOKEN_PLUS_ASSIGN TOKEN_MINUS_ASSIGN TOKEN_MULT_ASSIGN TOKEN_DIV_ASSIGN TOKEN_MOD_ASSIGN TOKEN_AND_ASSIGN TOKEN_OR_ASSIGN TOKEN_XOR_ASSIGN TOKEN_LSHIFT_ASSIGN TOKEN_RSHIFT_ASSIGN TOKEN_URSHIFT_ASSIGN
%left TOKEN_OR
%left TOKEN_AND
%left '|'
%left '^'
%left '&'
%left TOKEN_IGUAL_IGUAL TOKEN_DIFERENTE
%left '<' '>' TOKEN_MAYOR_IGUAL TOKEN_MENOR_IGUAL
%left TOKEN_LSHIFT TOKEN_RSHIFT TOKEN_URSHIFT 
%left '+' '-'
%left '*' '/' '%'
%right '!' '~' NEG 

/* Resolver el clásico dangling-else */
%nonassoc TOKEN_ELSE
%nonassoc IFX

%%
%start programa;

programa: lista_declaraciones { ast_root = $1; $$ = $1; };

lista_declaraciones: lista_declaraciones declaracion { agregarHijo($1, $2); $$ = $1; }
                    | declaracion { AbstractExpresion* lista = nuevoInstruccionesExpresion(); agregarHijo(lista, $1); $$ = lista; };

// Reglas para tipos primitivos
declaracion:    tipoPrimitivo corchetes_lista TOKEN_IDENTIFIER '(' lista_parametros_opt ')' bloque {
                        AbstractExpresion* decl = nuevoDeclaracionFuncion($1, $3, $5, $7, @1.first_line, @1.first_column);
                        ((FuncionDeclarationNode*)decl)->retorno_dimensiones = $2; $$ = decl;}
                | declaracion_funcion    { $$ = $1; }
                | declaracion_main       { $$ = $1; }
                | tipoPrimitivo corchetes_lista TOKEN_IDENTIFIER var_tail ';' {
                        DeclaradorNode* tail = (DeclaradorNode*)$4; int total_dims = $2 + tail->dimensiones;
                        $$ = nuevoDeclaracionVariable($1, total_dims, $3, tail->inicializador, @1.first_line, @1.first_column); free(tail);}
                | TOKEN_FINAL tipoPrimitivo corchetes_lista TOKEN_IDENTIFIER var_tail ';' {
                        DeclaradorNode* tail = (DeclaradorNode*)$5;
                        int total_dims = $3 + tail->dimensiones;
                        AbstractExpresion* decl = nuevoDeclaracionVariable($2, total_dims, $4, tail->inicializador, @1.first_line, @1.first_column);
                        ((DeclaracionVariable*)decl)->es_constante = 1; $$ = decl; free(tail);}
                ;

declaracion_funcion:    TOKEN_VOID TOKEN_IDENTIFIER '(' lista_parametros_opt ')' bloque {
                        $$ = nuevoDeclaracionFuncion(NULO, $2, $4, $6, @1.first_line, @1.first_column);}
                        ;

lista_parametros_opt:   lista_parametros    { $$ = $1; }
                        | %empty            { $$ = nuevoListaExpresiones(); };

lista_parametros:   lista_parametros ',' parametro  { agregarHijo($1, $3); $$ = $1; }
                    | parametro                     { AbstractExpresion* lista = nuevoListaExpresiones(); agregarHijo(lista, $1); $$ = lista; };

parametro:  tipoPrimitivo corchetes_lista TOKEN_IDENTIFIER corchetes_lista {
            int total_dims = $2 + $4; $$ = nuevoParametro($1, total_dims, $3);}
            ;

declaracion_main:   TOKEN_PUBLIC TOKEN_STATIC TOKEN_VOID TOKEN_MAIN 
                    '(' ')' bloque { $$ = nuevoMainFunctionNode($7, @1.first_line, @1.first_column);}
                    ;

lista_argumentos_opt:   lista_Expr { $$ = $1; }
                        | %empty   { $$ = NULL; };

lSentencia: lSentencia sentencia { if ($2 != NULL) {agregarHijo($1, $2);} $$ = $1; }
            | sentencia { AbstractExpresion* b = nuevoInstruccionesExpresion(); if ($1 != NULL) { agregarHijo(b, $1);} $$ = b;}
            ;

sentencia:  bloque                  { $$ = $1; }
            | declaracion_var ';'   { $$ = $1; }
            | if_stmt               { $$ = $1; }
            | while_stmt            { $$ = $1; }
            | for_stmt              { $$ = $1; }
            | switch_stmt           { $$ = $1; }
            | TOKEN_BREAK ';'       { $$ = nuevoBreakExpresion(@1.first_line, @1.first_column); }
            | TOKEN_CONTINUE ';'    { $$ = nuevoContinueExpresion(@1.first_line, @1.first_column); }
            | TOKEN_RETURN expr ';' { $$ = nuevoReturnExpresion($2, @1.first_line, @1.first_column); }
            | TOKEN_RETURN ';'      { $$ = nuevoReturnExpresion(NULL, @1.first_line, @1.first_column); } 
            | expr ';'              { $$ = $1; }
            | error ';'             { yyerrok; $$ = NULL; }
            ;

lista_Expr: lista_Expr ',' lista_item { agregarHijo($1, $3); $$ = $1; }
            | lista_item { AbstractExpresion* b = nuevoListaExpresiones();agregarHijo(b, $1); $$ = b; };

lista_item: expr { $$ = $1; }
            | inicializador_arreglo { $$ = $1; }
            ;

bloque: '{' lSentencia '}' { $$ = nuevoBloqueExpresion($2, @1.first_line, @1.first_column); }
        | '{' '}' { $$ = nuevoBloqueExpresion(NULL, @1.first_line, @1.first_column); }
        ;

declaracion_var:    tipoPrimitivo declarador_completo {
                        DeclaradorNode* declarador_info = (DeclaradorNode*)$2;
                        $$ = nuevoDeclaracionVariable($1, declarador_info->dimensiones, declarador_info->nombre, declarador_info->inicializador, @2.first_line, @2.first_column);
                        free(declarador_info);}
                    | TOKEN_FINAL tipoPrimitivo declarador_completo {
                        DeclaradorNode* declarador_info = (DeclaradorNode*)$3;
                        AbstractExpresion* decl = nuevoDeclaracionVariable($2, declarador_info->dimensiones, declarador_info->nombre, declarador_info->inicializador, @1.first_line, @1.first_column);
                        ((DeclaracionVariable*)decl)->es_constante = 1;$$ = decl;free(declarador_info);}
                    ;


declarador_completo: corchetes_lista TOKEN_IDENTIFIER corchetes_lista '=' inicializador_arreglo {
                        $$ = nuevoDeclaradorNode($2, $1 + $3, $5);}
                    | corchetes_lista TOKEN_IDENTIFIER corchetes_lista '=' expr {
                        $$ = nuevoDeclaradorNode($2, $1 + $3, $5);}
                    | corchetes_lista TOKEN_IDENTIFIER corchetes_lista {
                        $$ = nuevoDeclaradorNode($2, $1 + $3, NULL);}
                    ;

corchetes_lista:    corchetes_lista '[' ']' { $$ = $1 + 1; }
                    | %empty { $$ = 0; }
                    ;

inicializador_arreglo : '{' lista_Expr '}' { $$ = nuevoInicializadorArreglo($2, @1.first_line, @1.first_column); }
                        | '{' '}' { $$ = nuevoInicializadorArreglo(NULL, @1.first_line, @1.first_column); }
                        ;


var_tail: corchetes_lista '=' inicializador_arreglo { $$ = nuevoDeclaradorNode(NULL, $1, $3); }
        | corchetes_lista '=' expr { $$ = nuevoDeclaradorNode(NULL, $1, $3); }
        | corchetes_lista { $$ = nuevoDeclaradorNode(NULL, $1, NULL); }
        ;


asignacion_expr: TOKEN_IDENTIFIER '=' expr { $$ = nuevoReasignacionExpresion($1, $3, @1.first_line, @1.first_column); }
                | primary_expr '[' expr ']' '=' expr { $$ = nuevoAsignacionArreglo($1, $3, $6, @5.first_line, @5.first_column); }
                | TOKEN_IDENTIFIER TOKEN_PLUS_ASSIGN expr  { $$ = nuevoAsignacionCompuestaExpresion($1, '+', $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_MINUS_ASSIGN expr { $$ = nuevoAsignacionCompuestaExpresion($1, '-', $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_MULT_ASSIGN expr  { $$ = nuevoAsignacionCompuestaExpresion($1, '*', $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_DIV_ASSIGN expr   { $$ = nuevoAsignacionCompuestaExpresion($1, '/', $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_MOD_ASSIGN expr   { $$ = nuevoAsignacionCompuestaExpresion($1, '%', $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_AND_ASSIGN expr    { $$ = nuevoAsignacionCompuestaExpresion($1, '&', $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_OR_ASSIGN expr     { $$ = nuevoAsignacionCompuestaExpresion($1, '|', $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_XOR_ASSIGN expr     { $$ = nuevoAsignacionCompuestaExpresion($1, '^', $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_LSHIFT_ASSIGN expr  { $$ = nuevoAsignacionCompuestaExpresion($1, TOKEN_LSHIFT, $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_RSHIFT_ASSIGN expr  { $$ = nuevoAsignacionCompuestaExpresion($1, TOKEN_RSHIFT, $3, @1.first_line, @1.first_column); }
                | TOKEN_IDENTIFIER TOKEN_URSHIFT_ASSIGN expr { $$ = nuevoAsignacionCompuestaExpresion($1, TOKEN_URSHIFT, $3, @1.first_line, @1.first_column); }
                | primary_expr '[' expr ']' TOKEN_PLUS_ASSIGN expr  { $$ = nuevoAsignacionArreglo($1, $3, nuevoSumaExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_MINUS_ASSIGN expr { $$ = nuevoAsignacionArreglo($1, $3, nuevoRestaExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_MULT_ASSIGN expr  { $$ = nuevoAsignacionArreglo($1, $3, nuevoMultiplicacionExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_DIV_ASSIGN expr   { $$ = nuevoAsignacionArreglo($1, $3, nuevoDivisionExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_MOD_ASSIGN expr   { $$ = nuevoAsignacionArreglo($1, $3, nuevoModuloExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_AND_ASSIGN expr   { $$ = nuevoAsignacionArreglo($1, $3, nuevoBitwiseAndExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_OR_ASSIGN expr    { $$ = nuevoAsignacionArreglo($1, $3, nuevoBitwiseOrExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_XOR_ASSIGN expr   { $$ = nuevoAsignacionArreglo($1, $3, nuevoBitwiseXorExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_LSHIFT_ASSIGN expr { $$ = nuevoAsignacionArreglo($1, $3, nuevoLeftShiftExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_RSHIFT_ASSIGN expr { $$ = nuevoAsignacionArreglo($1, $3, nuevoRightShiftExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                | primary_expr '[' expr ']' TOKEN_URSHIFT_ASSIGN expr { $$ = nuevoAsignacionArreglo($1, $3, nuevoUnsignedRightShiftExpresion(nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column), $6, @5.first_line, @5.first_column), @5.first_line, @5.first_column); }
                ;


expr: asignacion_expr              { $$ = $1; }
    | expr TOKEN_OR expr           { $$ = nuevoOrExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr TOKEN_AND expr          { $$ = nuevoAndExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '|' expr                { $$ = nuevoBitwiseOrExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '^' expr                { $$ = nuevoBitwiseXorExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '&' expr                { $$ = nuevoBitwiseAndExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr TOKEN_IGUAL_IGUAL expr  { $$ = nuevoIgualExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr TOKEN_DIFERENTE expr    { $$ = nuevoDiferenteExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '<' expr                { $$ = nuevoMenorQueExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '>' expr                { $$ = nuevoMayorQueExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr TOKEN_MENOR_IGUAL expr  { $$ = nuevoMenorIgualExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr TOKEN_MAYOR_IGUAL expr  { $$ = nuevoMayorIgualExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr TOKEN_LSHIFT expr       { $$ = nuevoLeftShiftExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr TOKEN_RSHIFT expr       { $$ = nuevoRightShiftExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr TOKEN_URSHIFT expr      { $$ = nuevoUnsignedRightShiftExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '+' expr                { $$ = nuevoSumaExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '-' expr                { $$ = nuevoRestaExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '*' expr                { $$ = nuevoMultiplicacionExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '/' expr                { $$ = nuevoDivisionExpresion($1, $3, @2.first_line, @2.first_column); }
    | expr '%' expr                { $$ = nuevoModuloExpresion($1, $3, @2.first_line, @2.first_column); }
    | primary_expr                 { $$ = $1; }
    ;


primary_expr: '(' expr ')'                                  { $$ = $2; }
            | '(' tipoPrimitivo ')' primary_expr            { $$ = nuevoCasteoExpresion($2, $4, @1.first_line, @1.first_column); }
            | TOKEN_IDENTIFIER                              { $$ = nuevoIdentificadorExpresion($1, @1.first_line, @1.first_column); }
            | primary_expr '[' expr ']'                     { $$ = nuevoAccesoArreglo($1, $3, @2.first_line, @2.first_column); }
            | expresion_creacion_arreglo                    { $$ = $1; }
            | TOKEN_PARSE_INT '(' expr ')'                  { $$ = nuevoParseIntExpresion($3, @1.first_line, @1.first_column); }
            | TOKEN_PARSE_FLOAT '(' expr ')'                { $$ = nuevoParseFloatExpresion($3, @1.first_line, @1.first_column); }
            | TOKEN_PARSE_DOUBLE '(' expr ')'               { $$ = nuevoParseDoubleExpresion($3, @1.first_line, @1.first_column); }
            | TOKEN_STRING_VALUEOF '(' expr ')'             { $$ = nuevoStringValueofExpresion($3, @1.first_line, @1.first_column); }
            | TOKEN_STRING_JOIN '(' expr ',' lista_Expr ')' { $$ = nuevoStringJoinExpresion($3, $5, @1.first_line, @1.first_column); }
            | TOKEN_ARRAYS_INDEXOF '(' expr ',' expr ')'    { $$ = nuevoArraysIndexofExpresion($3, $5, @1.first_line, @1.first_column); }
            | primary_expr TOKEN_DOT TOKEN_LENGTH           { $$ = nuevoArrayLengthExpresion($1, @2.first_line, @2.first_column); }
            | TOKEN_IDENTIFIER '(' lista_argumentos_opt ')' { $$ = nuevoLlamadaFuncion($1, $3, @1.first_line, @1.first_column); }
            | TOKEN_PRINT '(' ')'                       {
                AbstractExpresion* lista = nuevoListaExpresiones();
                $$ = nuevoPrintExpresion(lista, @1.first_line, @1.first_column);
            }
            | TOKEN_PRINT '(' expr ')'                      {
                AbstractExpresion* lista = nuevoListaExpresiones();
                agregarHijo(lista, $3);
                $$ = nuevoPrintExpresion(lista, @1.first_line, @1.first_column);
            }
            | primitivo                                     { $$ = $1; }
            | '-' primary_expr %prec NEG                    { $$ = nuevoUnarioExpresion($2, @1.first_line, @1.first_column); }
            | '!' primary_expr                              { $$ = nuevoNotExpresion($2, @1.first_line, @1.first_column); }
            | '~' primary_expr                              { $$ = nuevoBitwiseNotExpresion($2, @1.first_line, @1.first_column); }
            | primary_expr TOKEN_INCREMENTO                 { $$ = nuevoPostfixExpresion($1, TOKEN_INCREMENTO, @2.first_line, @2.first_column); }
            | primary_expr TOKEN_DECREMENTO                 { $$ = nuevoPostfixExpresion($1, TOKEN_DECREMENTO, @2.first_line, @2.first_column); }
            | primary_expr TOKEN_DOT TOKEN_IDENTIFIER '(' expr ')' {
                if (strcmp($3, "equals") == 0) {
                    $$ = nuevoEqualsExpresion($1, $5, @2.first_line, @2.first_column);
                    free($3);
                } else if (strcmp($3, "add") == 0) {
                    $$ = nuevoArrayAddExpresion($1, $5, @2.first_line, @2.first_column);
                    free($3);
                } else {
                    char desc[100];
                    sprintf(desc, "El método '%s' no está definido.", $3);
                    yyerror(desc);
                    $$ = NULL;
                    free($3);
                }
            }
            ;

primitivo: TOKEN_INTEGER   { $$ = nuevoPrimitivoExpresion($1, INT, @1.first_line, @1.first_column); }
    | TOKEN_HEX_INTEGER    { $$ = nuevoPrimitivoExpresion($1, INT, @1.first_line, @1.first_column); }
    | TOKEN_FLOAT_LIT      { $$ = nuevoPrimitivoExpresion($1, FLOAT, @1.first_line, @1.first_column); }
    | TOKEN_DOUBLE_LIT     { $$ = nuevoPrimitivoExpresion($1, DOUBLE, @1.first_line, @1.first_column); }
    | TOKEN_STRING_LITERAL { $$ = nuevoPrimitivoExpresion($1, STRING, @1.first_line, @1.first_column); }
    | TOKEN_CHAR_LITERAL   { $$ = nuevoPrimitivoExpresion($1, CHAR, @1.first_line, @1.first_column); }
    | TOKEN_TRUE           { $$ = nuevoPrimitivoExpresion($1, BOOLEAN, @1.first_line, @1.first_column); }
    | TOKEN_FALSE          { $$ = nuevoPrimitivoExpresion($1, BOOLEAN, @1.first_line, @1.first_column); }
    | TOKEN_NULL           { $$ = nuevoPrimitivoExpresion(NULL, NULO, @1.first_line, @1.first_column); }
    ;


tipoPrimitivo: TOKEN_DINT     { $$ = INT; }
    | TOKEN_DFLOAT    { $$ = FLOAT; }
    | TOKEN_DDOUBLE   { $$ = DOUBLE; }
    | TOKEN_DSTRING   { $$ = STRING; }
    | TOKEN_DCHAR     { $$ = CHAR; }
    | TOKEN_DBOOLEAN  { $$ = BOOLEAN; }
    ;


if_stmt: TOKEN_IF '(' expr ')' bloque %prec IFX { 
            $$ = nuevoIfExpresion($3, $5, NULL, @1.first_line, @1.first_column);
            }
        | TOKEN_IF '(' expr ')' bloque TOKEN_ELSE bloque {
            $$ = nuevoIfExpresion($3, $5, $7, @1.first_line, @1.first_column);
            }
        | TOKEN_IF '(' expr ')' bloque TOKEN_ELSE if_stmt {
            $$ = nuevoIfExpresion($3, $5, $7, @1.first_line, @1.first_column);
            }
            ;


while_stmt: TOKEN_WHILE '(' expr ')' bloque {
                $$ = nuevoWhileExpresion($3, $5, @1.first_line, @1.first_column);
            };


for_init: declaracion_var { $$ = $1; }
    | expr            { $$ = $1; };

for_expr_opt: expr            { $$ = $1; }
            | %empty          { $$ = NULL; };


for_stmt:
    TOKEN_FOR '(' for_head ')' bloque {
        AbstractExpresion* for_node = $3;
        if (for_node != NULL) {
            agregarHijo(for_node, $5);}
        $$ = for_node;
    }
    ;


for_head:
    tipoPrimitivo corchetes_lista TOKEN_IDENTIFIER corchetes_lista ':' expr {
        int total_dims = $2 + $4;
        $$ = nuevoForEachExpresion(
            $1,            // tipo base
            total_dims,    // dimensiones totales
            $3,            // nombre de variable
            $6,            // expresión iterable
            NULL,          // bloque se añade después
            @1.first_line,
            @1.first_column
        );
    }
    | tipoPrimitivo corchetes_lista TOKEN_IDENTIFIER corchetes_lista '=' inicializador_arreglo ';' for_expr_opt ';' for_expr_opt {
        int total_dims = $2 + $4;
        AbstractExpresion* decl = nuevoDeclaracionVariable($1, total_dims, $3, $6, @3.first_line, @3.first_column);
        $$ = nuevoForExpresion(
            decl,
            $8,
            $10,
            NULL,
            @1.first_line,
            @1.first_column
        );
    }
    | tipoPrimitivo corchetes_lista TOKEN_IDENTIFIER corchetes_lista '=' expr ';' for_expr_opt ';' for_expr_opt {
        int total_dims = $2 + $4;
        AbstractExpresion* decl = nuevoDeclaracionVariable($1, total_dims, $3, $6, @3.first_line, @3.first_column);
        $$ = nuevoForExpresion(
            decl,
            $8,
            $10,
            NULL,
            @1.first_line,
            @1.first_column
        );
    }
    | tipoPrimitivo corchetes_lista TOKEN_IDENTIFIER corchetes_lista ';' for_expr_opt ';' for_expr_opt {
        int total_dims = $2 + $4;
        AbstractExpresion* decl = nuevoDeclaracionVariable($1, total_dims, $3, NULL, @3.first_line, @3.first_column);
        $$ = nuevoForExpresion(
            decl,
            $6,
            $8,
            NULL,
            @1.first_line,
            @1.first_column
        );
    }
    | for_init_opt ';' for_expr_opt ';' for_expr_opt {
        $$ = nuevoForExpresion(
            $1,   // init (expr o NULL)
            $3,   // cond
            $5,   // update
            NULL, // bloque se añadirá después
            @1.first_line, 
            @1.first_column
        );
    }
    ;


for_init_opt:
    for_init { $$ = $1; }
    | %empty { $$ = NULL; }
    ;


switch_stmt: TOKEN_SWITCH '(' expr ')' '{' case_list '}' {
                $$ = nuevoSwitchExpresion($3, $6, @1.first_line, @1.first_column);
            };



case_list: case_list case_stmt { agregarHijo($1, $2); $$ = $1; }
        | case_stmt         { 
                                AbstractExpresion* lista = nuevoListaExpresiones();
                                agregarHijo(lista, $1);
                                $$ = lista;
                            }
        ;

case_stmt:  TOKEN_CASE expr ':' lSentencia_opt { $$ = nuevoCaseExpresion($2, $4, @1.first_line, @1.first_column);}
            | TOKEN_DEFAULT ':' lSentencia_opt { $$ = nuevoDefaultExpresion($3, @1.first_line, @1.first_column); }
            ;


lSentencia_opt: lSentencia { $$ = $1; } 
                | %empty   { $$ = NULL; } 
                ;


expresion_creacion_arreglo: TOKEN_NEW tipoPrimitivo lista_dims_expr dims_vacias {
                                AbstractExpresion* tipo_nodo = nuevoTipoNode($2);
                                AbstractExpresion* node = nuevoCreacionArreglo(tipo_nodo, $3, @1.first_line, @1.first_column);char* numstr = malloc(16);
                                sprintf(numstr, "%d", $4);
                                AbstractExpresion* cnt = nuevoPrimitivoExpresion(numstr, INT, @1.first_line, @1.first_column);agregarHijo(node, cnt);$$ = node;}
                            | TOKEN_NEW tipoPrimitivo lista_dims_expr {
                                AbstractExpresion* tipo_nodo = nuevoTipoNode($2);$$ = nuevoCreacionArreglo(tipo_nodo, $3, @1.first_line, @1.first_column);
                            }
                            ;

lista_dims_expr: lista_dims_expr '[' expr ']' { agregarHijo($1, $3); $$ = $1; }
                | '[' expr ']' {
                    AbstractExpresion* lista = nuevoListaExpresiones();
                    agregarHijo(lista, $2);
                    $$ = lista;
                }
                ;

dims_vacias
    : dims_vacias '[' ']' { $$ = $1 + 1; }
    | '[' ']' { $$ = 1; }
    ;

%%

void yyerror(const char *s) {
    add_error_to_report("Sintáctico", yylasttext, s, yylloc.first_line, yylloc.first_column, NULL);
}
