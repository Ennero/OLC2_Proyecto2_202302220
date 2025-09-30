#ifndef ERROR_REPORTER_H
#define ERROR_REPORTER_H
#include <stdbool.h> // Incluir stdbool.h para usar el tipo bool

// La estructura ErrorInfo representa un error individual
typedef struct ErrorInfo
{
    int id;
    char *type;
    char *lexeme;
    char *description;
    char *context_name;
    int line;
    int column;
    struct ErrorInfo *next;
} ErrorInfo;

typedef struct ErrorReportSnapshot
{
    ErrorInfo *tail;
    int last_error_id;
    bool semantic_flag;
} ErrorReportSnapshot;

void init_error_report();
void clear_error_report();
void free_error_report();
void add_error_to_report(const char *type, const char *lexeme, const char *description, int line, int column, const char *context_name);
const ErrorInfo *get_error_list();

// Verifica si se ha encontrado al menos un error semantico
bool has_semantic_error_been_found();

ErrorReportSnapshot capture_error_report_snapshot();
bool error_report_has_new_errors_since(ErrorReportSnapshot snapshot);
void rollback_error_report_to_snapshot(ErrorReportSnapshot snapshot);

#endif