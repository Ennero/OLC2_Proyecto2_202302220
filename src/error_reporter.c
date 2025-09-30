#include "error_reporter.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>

// Punteros a la cabeza y la cola de la lista para inserción eficiente
static ErrorInfo *error_list_head = NULL;
static ErrorInfo *error_list_tail = NULL;

// Contador estático para el ID correlativo de los errores
static int error_id_counter = 0;

// Bandera para indicar si se ha encontrado un error semántico
static bool semantic_error_found = false;

static void free_error_nodes(ErrorInfo *node)
{
    while (node != NULL)
    {
        ErrorInfo *next = node->next;
        free(node->type);
        free(node->lexeme);
        free(node->description);
        free(node->context_name);
        free(node);
        node = next;
    }
}

// Inicializa o reinicia el reportero de errores
void init_error_report()
{

    // Si ya hay errores, se limpian primero para evitar fugas de memoria
    if (error_list_head != NULL)
    {
        clear_error_report();
    }

    // Reiniciar los punteros y el contador
    error_list_head = NULL;
    error_list_tail = NULL;
    error_id_counter = 0;
    semantic_error_found = false;
}

// Libera toda la memoria utilizada por la lista de errores
void clear_error_report()
{
    free_error_nodes(error_list_head);
    // Reiniciar los punteros y el contador
    error_list_head = NULL;
    error_list_tail = NULL;
    error_id_counter = 0;
    semantic_error_found = false;
}

// Función para liberar la memoria al final del programa
void free_error_report()
{
    clear_error_report();
}

// Añade un nuevo error al final de la lista
void add_error_to_report(const char *type, const char *lexeme, const char *description, int line, int column, const char *context_name)
{

    // Si se encuentra un error semántico, se marca la bandera
    if (strcmp(type, "Semantico") == 0 || strcmp(type, "Semántico") == 0)
    {
        semantic_error_found = true;
    }

    // Reservar memoria para el nuevo nodo de error
    ErrorInfo *new_info = (ErrorInfo *)malloc(sizeof(ErrorInfo));
    if (!new_info)
        return; // Fallo de asignación de memoria

    // Poblar el nuevo nodo con la información del error
    new_info->id = ++error_id_counter; // Pre-incrementar y asignar el ID único
    new_info->type = strdup(type);
    new_info->lexeme = strdup(lexeme);
    new_info->description = strdup(description);
    new_info->line = line;
    new_info->column = column;
    new_info->context_name = strdup(context_name ? context_name : "global");
    new_info->next = NULL; // Este será el último nodo de la lista

    // Añadir el nodo al final de la lista enlazada
    if (error_list_head == NULL)
    {

        // Si la lista está vacía, el nuevo nodo es tanto la cabeza como la cola
        error_list_head = new_info;
        error_list_tail = new_info;
    }
    else
    {

        // Si la lista no está vacía, se enlaza después de la cola actual
        error_list_tail->next = new_info;

        // Se actualiza la cola para que apunte al nuevo último nodo
        error_list_tail = new_info;
    }
}

// Devuelve un puntero a la cabeza de la lista de errores
const ErrorInfo *get_error_list()
{
    return error_list_head;
}

// Bandera de si hay errores semánticos
bool has_semantic_error_been_found()
{
    return semantic_error_found;
}

ErrorReportSnapshot capture_error_report_snapshot()
{
    ErrorReportSnapshot snapshot;
    snapshot.tail = error_list_tail;
    snapshot.last_error_id = error_id_counter;
    snapshot.semantic_flag = semantic_error_found;
    return snapshot;
}

bool error_report_has_new_errors_since(ErrorReportSnapshot snapshot)
{
    return error_id_counter != snapshot.last_error_id;
}

void rollback_error_report_to_snapshot(ErrorReportSnapshot snapshot)
{
    ErrorInfo *first_new = snapshot.tail ? snapshot.tail->next : error_list_head;

    if (first_new)
    {
        free_error_nodes(first_new);
    }

    if (snapshot.tail)
    {
        snapshot.tail->next = NULL;
        error_list_tail = snapshot.tail;
    }
    else
    {
        error_list_head = NULL;
        error_list_tail = NULL;
    }

    error_id_counter = snapshot.last_error_id;
    semantic_error_found = snapshot.semantic_flag;
}