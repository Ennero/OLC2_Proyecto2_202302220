%{
// Definiciones y declaraciones en C
#include "parser.tab.h"
#include "error_reporter.h"
#include <stdio.h>
#include <string.h>

// Prototipos de funciones
extern void yyerror(const char *s);
int yycolumn = 1;
char* yylasttext = NULL;
int yywrap(void);

// Definición de la estructura para la ubicación
#define YY_USER_ACTION                                   \
    yylloc.first_line   = yylineno;                      \
    yylloc.first_column = yycolumn;                      \
    yylloc.last_line    = yylineno;                      \
    yylloc.last_column  = yycolumn + yyleng - 1;         \
    yycolumn += yyleng;                                  \
    if (yylasttext) free(yylasttext);                    \
    yylasttext = strdup(yytext);

%}

%option yylineno nounput noinput warn
%x COMMENT

digit             [0-9]
hex_digit         [0-9a-fA-F]
alpha             [a-zA-Z_]
alpha_num         ({alpha}|{digit})
identifier        {alpha}{alpha_num}*
integer           {digit}+
hex_integer       0[xX]{hex_digit}+
exponent          [eE][+-]?{digit}+

float_lit         ({digit}+\.{digit}*[fF])|(\.{digit}+[fF])|({digit}+[fF])
double_lit        ({digit}+\.{digit}*({exponent})?|\.{digit}+({exponent})?|{digit}+{exponent})

/* Unicode decimal escape: \u followed by 1 to 5 decimal digits (0-65535) */
unicode_escape_dec \\u{digit}{1,5}

char_lit          \'([^'\\]|\\.|{unicode_escape_dec})\'
string_lit        \"([^"\\]|\\.|{unicode_escape_dec})*\"

line_comment      "//".*
block_comment     "/*"
white_space       [ \t\r]+
newline           \n

%%

{white_space}      { /* Ignorar */ }
{newline}          { yycolumn = 1; }
{line_comment}     { /* Ignorar */ }

{block_comment}    { BEGIN(COMMENT); }
<COMMENT>"*/"      { BEGIN(INITIAL); }
<COMMENT>.         { /* Ignorar */ }
<COMMENT>\n        { yycolumn = 1; }

"if"                    return TOKEN_IF;
"else"                  return TOKEN_ELSE;
"while"                 return TOKEN_WHILE;
"for"                   return TOKEN_FOR;


"switch"                return TOKEN_SWITCH;
"case"                  return TOKEN_CASE;


"break"                 return TOKEN_BREAK;
"default"               return TOKEN_DEFAULT;
"continue"              return TOKEN_CONTINUE;
"return"                return TOKEN_RETURN;


"new"                   return TOKEN_NEW;
"System.out.println"    return TOKEN_PRINT;
"main"                  return TOKEN_MAIN;
"Integer.parseInt"      return TOKEN_PARSE_INT;
"Float.parseFloat"      return TOKEN_PARSE_FLOAT;
"Double.parseDouble"    return TOKEN_PARSE_DOUBLE;
"String.valueOf"        return TOKEN_STRING_VALUEOF;
"String.join"           return TOKEN_STRING_JOIN;
"Arrays.indexOf"        return TOKEN_ARRAYS_INDEXOF;
"length"                return TOKEN_LENGTH;

"null"                  return TOKEN_NULL;


"public"                return TOKEN_PUBLIC;   
"static"                return TOKEN_STATIC;   
"void"                  return TOKEN_VOID;  


"int"                   return TOKEN_DINT;
"float"                 return TOKEN_DFLOAT;
"double"                return TOKEN_DDOUBLE;
"boolean"               return TOKEN_DBOOLEAN;
"char"                  return TOKEN_DCHAR;
"String"                return TOKEN_DSTRING;
"final"                 return TOKEN_FINAL;
"true"                  { yylval.string = strdup(yytext); return TOKEN_TRUE; }
"false"                 { yylval.string = strdup(yytext); return TOKEN_FALSE; }


{integer}               { yylval.string = strdup(yytext); return TOKEN_INTEGER; }
{hex_integer}           { yylval.string = strdup(yytext); return TOKEN_HEX_INTEGER; }
{float_lit}             { yylval.string = strdup(yytext); return TOKEN_FLOAT_LIT; }
{double_lit}            { yylval.string = strdup(yytext); return TOKEN_DOUBLE_LIT; }

{char_lit}              {
                            // Elimina las comillas inicial y final
                            yytext[yyleng-1] = '\0';
                            yylval.string = strdup(yytext + 1);
                            return TOKEN_CHAR_LITERAL;
                        }
{string_lit}            {
                            // Elimina las comillas inicial y final
                            yytext[yyleng-1] = '\0';
                            yylval.string = strdup(yytext + 1);
                            return TOKEN_STRING_LITERAL;
                        }

{identifier}            { yylval.string = strdup(yytext); return TOKEN_IDENTIFIER; }




">>="              return TOKEN_RSHIFT_ASSIGN;
">>>="             return TOKEN_URSHIFT_ASSIGN;
"<<="              return TOKEN_LSHIFT_ASSIGN;


"&="               return TOKEN_AND_ASSIGN;
"|="               return TOKEN_OR_ASSIGN;
"^="               return TOKEN_XOR_ASSIGN;
"+="               return TOKEN_PLUS_ASSIGN;
"-="               return TOKEN_MINUS_ASSIGN;
"*="               return TOKEN_MULT_ASSIGN;
"/="               return TOKEN_DIV_ASSIGN;
"%="               return TOKEN_MOD_ASSIGN;


">>>"              return TOKEN_URSHIFT;
">>"               return TOKEN_RSHIFT;
"<<"               return TOKEN_LSHIFT;
"=="               return TOKEN_IGUAL_IGUAL;
"!="               return TOKEN_DIFERENTE;
">="               return TOKEN_MAYOR_IGUAL;
"<="               return TOKEN_MENOR_IGUAL;
"&&"               return TOKEN_AND;
"||"               return TOKEN_OR;
"++"               return TOKEN_INCREMENTO;
"--"               return TOKEN_DECREMENTO;

"-"                { return '-'; }
"."                return TOKEN_DOT;

[+*/%<>()\[\]{};,=.!&|^~:] { return yytext[0]; }
.                  { add_error_to_report("Léxico", yytext, "Caracter ilegal no reconocido.", yylineno, yycolumn, NULL); }

%%

int yywrap(void) {
    if (YY_START == COMMENT) {
        add_error_to_report("Léxico", "EOF", "Fin de archivo inesperado dentro de un comentario en bloque.", yylineno, yycolumn, NULL);
        BEGIN(INITIAL);
    }
    return 1;
}