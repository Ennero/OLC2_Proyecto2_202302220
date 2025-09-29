#ifndef SYMBOL_REPORTER_H
#define SYMBOL_REPORTER_H

#include "context/context.h"

// Información sobre un símbolo en el AST
typedef struct SymbolInfo
{
    int id;
    char *name;
    char *type;
    char *value;
    char *context_name;
    int line;
    int column;
    struct SymbolInfo *next;
} SymbolInfo;

// Inicializa el reporte de símbolos
void init_symbol_report();

// Limpia el reporte de símbolos
void clear_symbol_report();

// Libera la memoria utilizada por el reporte de símbolos
void free_symbol_report();

// Añade un símbolo al reporte
void add_symbol_to_report(const Symbol *symbol, const char *context_name);

// Obtiene la lista de símbolos
const SymbolInfo *get_symbol_list();

#endif
