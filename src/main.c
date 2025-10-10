#include <gtk/gtk.h>
#include <gtksourceview/gtksource.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include "ast/AbstractExpresion.h"
#include "context/context.h"
#include "output_buffer.h"
#include "symbol_reporter.h"
#include "error_reporter.h"
#include "ast_grapher.h"
#include "codegen/arm64_codegen.h"

// --- Declaraciones Globales y Prototipos ---
typedef struct yy_buffer_state *YY_BUFFER_STATE;
extern int yyparse(void);
extern int yylineno;
extern int yycolumn;
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern void yy_delete_buffer(YY_BUFFER_STATE b);
extern void yylex_destroy();

// Raíz del árbol de sintaxis abstracta
AbstractExpresion *ast_root = NULL;
static char *current_file_path = NULL;

// Estructura para almacenar los widgets de la aplicación
typedef struct
{
    GtkWindow *main_window;
    GtkSourceBuffer *input_buffer;
    GtkTextBuffer *output_buffer;
} AppWidgets;

// Prototipos
static void on_new_clicked(GtkToolButton *button, gpointer user_data);
static void on_open_clicked(GtkToolButton *button, gpointer user_data);
static void on_save_clicked(GtkToolButton *button, gpointer user_data);
static void on_save_as_clicked(GtkToolButton *button, gpointer user_data);
static void on_execute_clicked(GtkToolButton *button, gpointer user_data);
static void on_show_symbols_clicked(GtkToolButton *button, gpointer user_data);
static void on_show_errors_clicked(GtkToolButton *button, gpointer user_data);
static void on_generate_ast_clicked(GtkToolButton *button, gpointer user_data);
static void on_compile_clicked(GtkToolButton *button, gpointer user_data);
static void on_ast_export_clicked(GtkButton *button, gpointer user_data);

// Funciones para mostrar las ventanas de reportes
static void display_error_table_window(GtkWindow *parent);
static void display_symbol_table_window(GtkWindow *parent);
static gboolean save_file_content(AppWidgets *widgets, const char *path);
static void open_file(AppWidgets *widgets, const char *path);
static gboolean copy_file(const char *src_path, const char *dest_path);

//=====================================================================
// LÓGICA DE GESTIÓN DE ARCHIVOS Y EXPORTACIÓN
//=====================================================================
// Funcion para abrir un archivo
static void open_file(AppWidgets *widgets, const char *path)
{

    // Leer el contenido del archivo
    FILE *file = fopen(path, "r");
    if (!file)
    {
        perror("fopen");
        return;
    }

    // Obtener el tamaño del archivo
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);
    char *content = malloc(length + 1);
    if (content)
    {
        fread(content, 1, length, file);
        content[length] = '\0';
        gtk_text_buffer_set_text(GTK_TEXT_BUFFER(widgets->input_buffer), content, -1);
        free(content);
    }
    fclose(file);

    // Actualizar la ruta del archivo actual y el título de la ventana
    if (current_file_path)
    {
        g_free(current_file_path);
    }
    current_file_path = g_strdup(path);
    char *basename = g_path_get_basename(path);
    char *window_title = g_strdup_printf("%s - JavaLang Interpreter", basename);
    gtk_window_set_title(widgets->main_window, window_title);
    g_free(basename);
    g_free(window_title);
}

// Función para guardar el contenido del archivo
static gboolean save_file_content(AppWidgets *widgets, const char *path)
{
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(widgets->input_buffer), &start, &end);
    char *content = gtk_text_buffer_get_text(GTK_TEXT_BUFFER(widgets->input_buffer), &start, &end, FALSE);

    // Escribir el contenido en el archivo
    FILE *file = fopen(path, "w");
    if (!file)
    {
        perror("fopen on save");
        g_free(content);
        return FALSE;
    }
    fprintf(file, "%s", content);
    fclose(file);
    g_free(content);

    // Actualizar la ruta del archivo actual y el título de la ventana
    if (current_file_path)
    {
        g_free(current_file_path);
    }
    current_file_path = g_strdup(path);
    char *basename = g_path_get_basename(path);
    char *window_title = g_strdup_printf("%s - JavaLang Interpreter", basename);
    gtk_window_set_title(widgets->main_window, window_title);
    g_free(basename);
    g_free(window_title);
    return TRUE;
}

// Función auxiliar para copiar un archivo
static gboolean copy_file(const char *src_path, const char *dest_path)
{

    // Abrir ambos archivos
    FILE *src = fopen(src_path, "rb");
    if (!src)
        return FALSE;
    FILE *dest = fopen(dest_path, "wb");
    if (!dest)
    {
        fclose(src);
        return FALSE;
    }

    // Copiar el contenido del archivo
    char buffer[4096];
    size_t n;

    // Leer y escribir en bloques para manejar archivos grandes
    while ((n = fread(buffer, 1, sizeof(buffer), src)) > 0)
    {
        if (fwrite(buffer, 1, n, dest) != n)
        {
            fclose(src);
            fclose(dest);
            return FALSE;
        }
    }

    fclose(src);
    fclose(dest);
    return TRUE;
}

//=====================================================================
// DEFINICIONES DE LAS FUNCIONES CALLBACK
//=====================================================================
// Función para crear un nuevo archivo
static void on_new_clicked(GtkToolButton *button, gpointer user_data)
{
    // Cochino GTK
    (void)button;

    // Limpiar el área de texto y resetear el estado
    AppWidgets *widgets = (AppWidgets *)user_data;

    // Limpiar el área de texto y resetear el estado
    gtk_text_buffer_set_text(GTK_TEXT_BUFFER(widgets->input_buffer), "", -1);

    // Resetear variables globales
    if (current_file_path)
    {
        g_free(current_file_path);
        current_file_path = NULL;
    }
    gtk_window_set_title(widgets->main_window, "JavaLang Interpreter");
}

// Funcion para abrir un archivo
static void on_open_clicked(GtkToolButton *button, gpointer user_data)
{
    (void)button;

    // Crear y mostrar el diálogo de selección de archivo
    AppWidgets *widgets = (AppWidgets *)user_data;
    GtkWidget *dialog = gtk_file_chooser_dialog_new("Abrir Archivo", widgets->main_window, GTK_FILE_CHOOSER_ACTION_OPEN,
                                                    "_Cancelar", GTK_RESPONSE_CANCEL,
                                                    "_Abrir", GTK_RESPONSE_ACCEPT, NULL);
    GtkFileFilter *filter = gtk_file_filter_new();
    gtk_file_filter_set_name(filter, "Archivos JavaLang (*.usl)");
    gtk_file_filter_add_pattern(filter, "*.usl");
    gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), filter);

    // Si el usuario selecciona un archivo y confirma
    if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT)
    {
        char *filename = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
        open_file(widgets, filename);
        g_free(filename);
    }
    gtk_widget_destroy(dialog);
}

// Funcion para guardar
static void on_save_clicked(GtkToolButton *button, gpointer user_data)
{
    (void)button;

    // Si el archivo del documento actual es NULL, llamar a "Guardar Como"
    if (current_file_path == NULL)
    {
        on_save_as_clicked(button, user_data);
    }
    else
    {
        // Si no no xd, guardar directamente
        save_file_content((AppWidgets *)user_data, current_file_path);
    }
}

// Funcion para guardar en
static void on_save_as_clicked(GtkToolButton *button, gpointer user_data)
{
    (void)button;
    AppWidgets *widgets = (AppWidgets *)user_data;

    // Crear y mostrar el diálogo de selección de archivo
    GtkWidget *dialog = gtk_file_chooser_dialog_new("Guardar Archivo Como", widgets->main_window, GTK_FILE_CHOOSER_ACTION_SAVE,
                                                    "_Cancelar", GTK_RESPONSE_CANCEL,
                                                    "_Guardar", GTK_RESPONSE_ACCEPT, NULL);
    GtkFileFilter *filter = gtk_file_filter_new();

    // Configurar el filtro para archivos .usl y otras cositas
    gtk_file_filter_set_name(filter, "Archivos JavaLang (*.usl)");
    gtk_file_filter_add_pattern(filter, "*.usl");
    gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), filter);
    gtk_file_chooser_set_do_overwrite_confirmation(GTK_FILE_CHOOSER(dialog), TRUE);
    gtk_file_chooser_set_current_name(GTK_FILE_CHOOSER(dialog), "nuevo.usl");

    // Si el usuario selecciona un archivo y confirma
    if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT)
    {
        char *filename = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
        save_file_content(widgets, filename);
        g_free(filename);
    }
    gtk_widget_destroy(dialog);
}

//==========================================================================================================================================
// EJECUCIÓN DEL CÓDIGO
//==========================================================================================================================================
// Funcion para ejecutar el código
static void on_execute_clicked(GtkToolButton *button, gpointer user_data)
{
    (void)button;
    AppWidgets *widgets = (AppWidgets *)user_data;

    // Obtener el texto de entrada
    GtkTextBuffer *buffer = GTK_TEXT_BUFFER(widgets->input_buffer);
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    gchar *input_text = gtk_text_buffer_get_text(buffer, &start, &end, FALSE);

    // Limpiar los reportes
    clear_output_buffer();
    clear_symbol_report();
    clear_error_report();
    ast_root = NULL;
    yylineno = 1;
    yycolumn = 1;

    // Si hay algo en el texto de entrada
    if (input_text && input_text[0] != '\0')
    {
        // Ejecutar el análisis léxico y sintáctico
        YY_BUFFER_STATE buffer_state = yy_scan_string(input_text);
        yyparse();

        // Si NO hubo errores de sintaxis Y se generó un AST, proceder a interpretar
        if (get_error_list() == NULL && ast_root)
        {
            Context *contextPadre = nuevoContext(NULL, "global");
            ast_root->interpret(ast_root, contextPadre);
        }

        // Al finalizar borrar el buffer del analizador
        yy_delete_buffer(buffer_state);
    }
    else
    {
        append_to_output("No hay código para ejecutar.\n");
    }

    // Lógica final para determinar el mensaje de estado
    if (get_error_list() != NULL)
    {
        // Si la lista de errores NO está vacía:
        // Limpiamos cualquier salida parcial.
        clear_output_buffer();
        // Escribimos el mensaje de error.
        append_to_output("======== Se encontraron errores durante el análisis y/o ejecución ========\nVer la tabla de errores para más detalles.");
    }
    else
    {

        // Si la lista de errores está completamente vacía, la ejecución fue un éxito.
        append_to_output("\n\n======== Código analizado y ejecutado correctamente ========");
    }

    // Actualizar el buffer de salida
    const char *output_text = get_output_buffer();
    gtk_text_buffer_set_text(widgets->output_buffer, output_text, -1);
    g_free(input_text);
}

// Funcion para mostrar la tabla de simbolos
static void on_show_symbols_clicked(GtkToolButton *button, gpointer user_data)
{
    (void)button;
    AppWidgets *widgets = (AppWidgets *)user_data;
    GtkTextBuffer *buffer = GTK_TEXT_BUFFER(widgets->input_buffer);
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    gchar *input_text = gtk_text_buffer_get_text(buffer, &start, &end, FALSE);

    // Limpiar los reportes
    clear_symbol_report();
    clear_error_report();
    ast_root = NULL;
    yylineno = 1;
    yycolumn = 1;

    // Si hay algo en el texto de entrada
    if (input_text && input_text[0] != '\0')
    {
        YY_BUFFER_STATE buffer_state = yy_scan_string(input_text);
        yyparse();

        // Si tampoco hay errores
        if (get_error_list() == NULL && ast_root)
        {

            // Si no hay errores, se procede a la interpretación
            Context *contextPadre = nuevoContext(NULL, "global");
            ast_root->interpret(ast_root, contextPadre);
        }
        yy_delete_buffer(buffer_state);
    }

    // Mostrar la ventana de símbolos
    display_symbol_table_window(widgets->main_window);
    g_free(input_text);
}

// Funcion para Mostrar los Errores
static void on_show_errors_clicked(GtkToolButton *button, gpointer user_data)
{
    (void)button;
    AppWidgets *widgets = (AppWidgets *)user_data;
    GtkTextBuffer *buffer = GTK_TEXT_BUFFER(widgets->input_buffer);
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    gchar *input_text = gtk_text_buffer_get_text(buffer, &start, &end, FALSE);
    clear_error_report();
    ast_root = NULL;
    yylineno = 1;
    yycolumn = 1;

    // Si hay algo en el texto de entrada
    if (input_text && input_text[0] != '\0')
    {
        YY_BUFFER_STATE buffer_state = yy_scan_string(input_text);
        yyparse();

        // Si tampoco hay errores
        if (get_error_list() == NULL && ast_root)
        {
            Context *contextPadre = nuevoContext(NULL, "global");
            ast_root->interpret(ast_root, contextPadre);
        }
        yy_delete_buffer(buffer_state);
    }
    display_error_table_window(widgets->main_window);
    g_free(input_text);
}

// Funcion para Exportar el AST
static void on_ast_export_clicked(GtkButton *button, gpointer user_data)
{
    (void)button;
    GtkWidget *parent_window = GTK_WIDGET(user_data);
    GtkWidget *dialog = gtk_file_chooser_dialog_new("Exportar AST Como", GTK_WINDOW(parent_window), GTK_FILE_CHOOSER_ACTION_SAVE,
                                                    "_Cancelar", GTK_RESPONSE_CANCEL,
                                                    "_Exportar", GTK_RESPONSE_ACCEPT, NULL);

    GtkFileFilter *svg_filter = gtk_file_filter_new();
    gtk_file_filter_set_name(svg_filter, "Gráfico Vectorial Escalable (*.svg)");
    gtk_file_filter_add_pattern(svg_filter, "*.svg");
    gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), svg_filter);

    GtkFileFilter *pdf_filter = gtk_file_filter_new();
    gtk_file_filter_set_name(pdf_filter, "Documento PDF (*.pdf)");
    gtk_file_filter_add_pattern(pdf_filter, "*.pdf");
    gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), pdf_filter);

    gtk_file_chooser_set_do_overwrite_confirmation(GTK_FILE_CHOOSER(dialog), TRUE);
    gtk_file_chooser_set_current_name(GTK_FILE_CHOOSER(dialog), "ast.svg");

    if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT)
    {
        char *dest_filename = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
        const char *src_filename = "ast-graph/ast.svg";

        if (g_str_has_suffix(dest_filename, ".pdf"))
        {
            src_filename = "ast-graph/ast.pdf";
        }

        copy_file(src_filename, dest_filename);
        g_free(dest_filename);
    }
    gtk_widget_destroy(dialog);
}

//==========================================================================================================================================
// COMPILACIÓN A ARM64 DESDE LA GUI
//==========================================================================================================================================
static void on_compile_clicked(GtkToolButton *button, gpointer user_data)
{
    (void)button;
    AppWidgets *widgets = (AppWidgets *)user_data;

    // Obtener el texto de entrada
    GtkTextBuffer *buffer = GTK_TEXT_BUFFER(widgets->input_buffer);
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    gchar *input_text = gtk_text_buffer_get_text(buffer, &start, &end, FALSE);

    // Limpiar reportes previos
    clear_output_buffer();
    clear_symbol_report();
    clear_error_report();
    ast_root = NULL;
    yylineno = 1;
    yycolumn = 1;

    if (input_text && input_text[0] != '\0')
    {
        // Parsear el contenido como en CLI
        YY_BUFFER_STATE buffer_state = yy_scan_string(input_text);
        yyparse();

        if (get_error_list() == NULL && ast_root)
        {
            // Generar ensamblador ARM64 en arm/salida.s, igual que en CLI --arm
            mkdir("arm", 0777);
            int rc = arm64_generate_program(ast_root, "arm/salida.s");
            if (rc != 0)
            {
                append_to_output("Fallo generando ARM64 a 'arm/salida.s'\n");
            }
        }

        yy_delete_buffer(buffer_state);
    }
    else
    {
        append_to_output("No hay código para compilar.\n");
    }

    // Mensaje final coherente
    if (get_error_list() != NULL)
    {
        clear_output_buffer();
        append_to_output("======== Se encontraron errores durante el análisis ========\nVer la tabla de errores para más detalles.\n");
    }
    else if (input_text && input_text[0] != '\0')
    {
        append_to_output("\n\n======== Código analizado y ensamblador ARM64 generado en arm/salida.s ========\n");
    }

    // Actualizar salida en la UI
    const char *output_text = get_output_buffer();
    gtk_text_buffer_set_text(widgets->output_buffer, output_text, -1);
    g_free(input_text);
}

// Funcion para generar el ast
static void on_generate_ast_clicked(GtkToolButton *button, gpointer user_data)
{
    (void)button;
    AppWidgets *widgets = (AppWidgets *)user_data;

    // Obtener el texto de entrada
    GtkTextBuffer *buffer = GTK_TEXT_BUFFER(widgets->input_buffer);
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    gchar *input_text = gtk_text_buffer_get_text(buffer, &start, &end, FALSE);

    // Limpiar los reportes
    clear_error_report();
    if (ast_root)
    {
        // liberarAST(ast_root);
        ast_root = NULL;
    }
    yylineno = 1;
    yycolumn = 1;

    // Si hay algo en el texto de entrada
    if (input_text && input_text[0] != '\0')
    {
        YY_BUFFER_STATE buffer_state = yy_scan_string(input_text);
        yyparse();
        yy_delete_buffer(buffer_state);
    }

    // Si no hubo errores y se generó un AST, proceder a graficar
    if (get_error_list() == NULL && ast_root)
    {
        mkdir("ast-graph", 0777);
        generate_ast_graph(ast_root, "ast-graph/ast.dot");
        system("dot -Tsvg ast-graph/ast.dot -o ast-graph/ast.svg");
        system("dot -Tpdf ast-graph/ast.dot -o ast-graph/ast.pdf");

        GtkWidget *ast_window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_window_set_title(GTK_WINDOW(ast_window), "Visor del Árbol de Sintaxis Abstracta (AST)");
        gtk_window_set_default_size(GTK_WINDOW(ast_window), 800, 600);
        gtk_window_set_transient_for(GTK_WINDOW(ast_window), widgets->main_window);
        gtk_window_set_modal(GTK_WINDOW(ast_window), TRUE);

        GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 5);
        gtk_container_add(GTK_CONTAINER(ast_window), vbox);

        GtkWidget *scrolled_window = gtk_scrolled_window_new(NULL, NULL);
        gtk_widget_set_vexpand(scrolled_window, TRUE);
        gtk_box_pack_start(GTK_BOX(vbox), scrolled_window, TRUE, TRUE, 0);

        GtkWidget *image = gtk_image_new_from_file("ast-graph/ast.svg");
        gtk_container_add(GTK_CONTAINER(scrolled_window), image);

        GtkWidget *button_box = gtk_button_box_new(GTK_ORIENTATION_HORIZONTAL);
        gtk_button_box_set_layout(GTK_BUTTON_BOX(button_box), GTK_BUTTONBOX_END);
        GtkWidget *export_button = gtk_button_new_with_label("Exportar como...");
        g_signal_connect(export_button, "clicked", G_CALLBACK(on_ast_export_clicked), ast_window);
        gtk_container_add(GTK_CONTAINER(button_box), export_button);
        gtk_box_pack_start(GTK_BOX(vbox), button_box, FALSE, FALSE, 5);

        gtk_widget_show_all(ast_window);

        gtk_text_buffer_set_text(widgets->output_buffer, "Gráfico del AST generado en la carpeta 'ast-graph'.", -1);
    }
    else
    {
        gtk_text_buffer_set_text(widgets->output_buffer, "No se pudo generar el AST debido a errores en el código.", -1);
        display_error_table_window(widgets->main_window);
    }

    g_free(input_text);
}

//=====================================================================
// CONSTRUCCIÓN DE LA INTERFAZ GRÁFICA
//=====================================================================
static void activate(GtkApplication *app, gpointer user_data)
{
    // Crear los widgets principales
    GtkWidget *window, *vbox, *toolbar, *paned, *scrolled_input, *scrolled_output, *input_view, *output_view;
    GtkToolItem *new_tool, *open_tool, *save_tool, *save_as_tool, *spacer, *compile_tool, *exec_tool, *ast_tool, *symbols_tool, *errors_tool;
    AppWidgets *widgets = (AppWidgets *)user_data;

    // Configurar la ventana principal
    window = gtk_application_window_new(app);
    widgets->main_window = GTK_WINDOW(window);
    gtk_window_set_title(GTK_WINDOW(window), "JavaLang Interpreter");
    gtk_window_set_default_size(GTK_WINDOW(window), 1200, 768);
    gtk_window_set_position(GTK_WINDOW(window), GTK_WIN_POS_CENTER);

    // Crear el layout principal
    vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_container_add(GTK_CONTAINER(window), vbox);

    // Aplicar estilos CSS personalizados
    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(provider,
                                    "toolbar .execute-button button { background-image: image(green); color: white; font-weight: bold; }"
                                    "toolbar .compile-button button { background-image: image(orange); color: white; font-weight: bold; }"
                                    "toolbar .analysis-button button { background-image: image(lightgreen); }",
                                    -1, NULL);
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(), GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(provider);

    // Crear la barra de herramientas y todas esas cositas que tiene y no comentare por la pereza xd
    toolbar = gtk_toolbar_new();
    gtk_toolbar_set_style(GTK_TOOLBAR(toolbar), GTK_TOOLBAR_BOTH);
    gtk_box_pack_start(GTK_BOX(vbox), toolbar, FALSE, FALSE, 0);

    new_tool = gtk_tool_button_new(gtk_image_new_from_icon_name("document-new", GTK_ICON_SIZE_SMALL_TOOLBAR), "Nuevo");
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), new_tool, -1);

    open_tool = gtk_tool_button_new(gtk_image_new_from_icon_name("document-open", GTK_ICON_SIZE_SMALL_TOOLBAR), "Abrir");
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), open_tool, -1);

    save_tool = gtk_tool_button_new(gtk_image_new_from_icon_name("document-save", GTK_ICON_SIZE_SMALL_TOOLBAR), "Guardar");
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), save_tool, -1);

    save_as_tool = gtk_tool_button_new(gtk_image_new_from_icon_name("document-save-as", GTK_ICON_SIZE_SMALL_TOOLBAR), "Guardar Como");
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), save_as_tool, -1);

    spacer = gtk_separator_tool_item_new();
    gtk_separator_tool_item_set_draw(GTK_SEPARATOR_TOOL_ITEM(spacer), FALSE);
    gtk_tool_item_set_expand(spacer, TRUE);
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), spacer, -1);

    compile_tool = gtk_tool_button_new(gtk_image_new_from_icon_name("system-run", GTK_ICON_SIZE_SMALL_TOOLBAR), "Compilar");
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), compile_tool, -1);

    errors_tool = gtk_tool_button_new(gtk_image_new_from_icon_name("dialog-error", GTK_ICON_SIZE_SMALL_TOOLBAR), "Tabla Errores");
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), errors_tool, -1);

    symbols_tool = gtk_tool_button_new(gtk_image_new_from_icon_name("view-list-text", GTK_ICON_SIZE_SMALL_TOOLBAR), "Tabla Símbolos");
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), symbols_tool, -1);

    ast_tool = gtk_tool_button_new(gtk_image_new_from_icon_name("preferences-system", GTK_ICON_SIZE_SMALL_TOOLBAR), "Generar AST");
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), ast_tool, -1);

    exec_tool = gtk_tool_button_new(gtk_image_new_from_icon_name("media-playback-start", GTK_ICON_SIZE_SMALL_TOOLBAR), "Ejecutar");
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), exec_tool, -1);

    gtk_style_context_add_class(gtk_widget_get_style_context(GTK_WIDGET(exec_tool)), "execute-button");
    gtk_style_context_add_class(gtk_widget_get_style_context(GTK_WIDGET(compile_tool)), "compile-button");
    gtk_style_context_add_class(gtk_widget_get_style_context(GTK_WIDGET(errors_tool)), "analysis-button");
    gtk_style_context_add_class(gtk_widget_get_style_context(GTK_WIDGET(symbols_tool)), "analysis-button");
    gtk_style_context_add_class(gtk_widget_get_style_context(GTK_WIDGET(ast_tool)), "analysis-button");

    paned = gtk_paned_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_box_pack_start(GTK_BOX(vbox), paned, TRUE, TRUE, 0);

    GtkWidget *left_vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 5);
    GtkWidget *input_label = gtk_label_new(NULL);
    gtk_label_set_markup(GTK_LABEL(input_label), "<span weight='bold' size='large'>Entrada del Programa</span>");
    gtk_widget_set_halign(input_label, GTK_ALIGN_CENTER);
    gtk_box_pack_start(GTK_BOX(left_vbox), input_label, FALSE, FALSE, 5);

    scrolled_input = gtk_scrolled_window_new(NULL, NULL);
    gtk_widget_set_vexpand(scrolled_input, TRUE);
    gtk_box_pack_start(GTK_BOX(left_vbox), scrolled_input, TRUE, TRUE, 0);
    gtk_paned_add1(GTK_PANED(paned), left_vbox);

    input_view = gtk_source_view_new();
    widgets->input_buffer = GTK_SOURCE_BUFFER(gtk_text_view_get_buffer(GTK_TEXT_VIEW(input_view)));
    gtk_text_view_set_wrap_mode(GTK_TEXT_VIEW(input_view), GTK_WRAP_WORD_CHAR);
    gtk_source_view_set_show_line_numbers(GTK_SOURCE_VIEW(input_view), TRUE);
    gtk_source_view_set_auto_indent(GTK_SOURCE_VIEW(input_view), TRUE);
    gtk_container_add(GTK_CONTAINER(scrolled_input), input_view);

    GtkSourceLanguageManager *lang_manager = gtk_source_language_manager_get_default();
    GtkSourceLanguage *lang = gtk_source_language_manager_get_language(lang_manager, "java");
    gtk_source_buffer_set_language(widgets->input_buffer, lang);

    GtkWidget *right_vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 5);
    GtkWidget *output_label = gtk_label_new(NULL);
    gtk_label_set_markup(GTK_LABEL(output_label), "<span weight='bold' size='large'>Salida del Programa</span>");
    gtk_widget_set_halign(output_label, GTK_ALIGN_CENTER);
    gtk_box_pack_start(GTK_BOX(right_vbox), output_label, FALSE, FALSE, 5);

    scrolled_output = gtk_scrolled_window_new(NULL, NULL);
    gtk_widget_set_vexpand(scrolled_output, TRUE);
    gtk_box_pack_start(GTK_BOX(right_vbox), scrolled_output, TRUE, TRUE, 0);
    gtk_paned_add2(GTK_PANED(paned), right_vbox);

    output_view = gtk_text_view_new();
    widgets->output_buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(output_view));
    gtk_text_view_set_editable(GTK_TEXT_VIEW(output_view), FALSE);
    gtk_container_add(GTK_CONTAINER(scrolled_output), output_view);

    gtk_paned_set_position(GTK_PANED(paned), 600);

    g_signal_connect(G_OBJECT(new_tool), "clicked", G_CALLBACK(on_new_clicked), widgets);
    g_signal_connect(G_OBJECT(open_tool), "clicked", G_CALLBACK(on_open_clicked), widgets);
    g_signal_connect(G_OBJECT(save_tool), "clicked", G_CALLBACK(on_save_clicked), widgets);
    g_signal_connect(G_OBJECT(save_as_tool), "clicked", G_CALLBACK(on_save_as_clicked), widgets);
    g_signal_connect(G_OBJECT(compile_tool), "clicked", G_CALLBACK(on_compile_clicked), widgets);
    g_signal_connect(G_OBJECT(exec_tool), "clicked", G_CALLBACK(on_execute_clicked), widgets);
    g_signal_connect(G_OBJECT(ast_tool), "clicked", G_CALLBACK(on_generate_ast_clicked), widgets);
    g_signal_connect(G_OBJECT(symbols_tool), "clicked", G_CALLBACK(on_show_symbols_clicked), widgets);
    g_signal_connect(G_OBJECT(errors_tool), "clicked", G_CALLBACK(on_show_errors_clicked), widgets);

    gtk_widget_show_all(window);
}

// Manejo de la señal 'open' para abrir archivos desde la línea de comandos o el gestor de archivos
static void on_app_open(GtkApplication *app, GFile **files, gint n_files, char *hint, gpointer user_data)
{
    (void)hint;
    AppWidgets *widgets = (AppWidgets *)user_data;

    // Si la ventana principal no está creada, llamamos a 'activate' para crearla
    if (!widgets->main_window)
    {
        activate(app, user_data);
    }

    // Abrir el primer archivo proporcionado
    if (n_files > 0)
    {
        // Por simplicidad, solo abrimos el primer archivo
        char *path = g_file_get_path(files[0]);
        open_file(widgets, path);
        g_free(path);
    }

    gtk_window_present(widgets->main_window);
}

// Función Principal
int main(int argc, char **argv)
{
    // Inicializar buffers y reportes
    init_output_buffer();
    init_symbol_report();
    init_error_report();

    // Modo CLI opcional: "--run <archivo.usl>" (interpreta)
    // y "--arm <archivo.usl>" (genera ensamblador AArch64)
    if (argc >= 3 && (strcmp(argv[1], "--run") == 0 || strcmp(argv[1], "--arm") == 0))
    {
        // Leer el archivo de entrada
        const char *path = argv[2];
        FILE *f = fopen(path, "r");
        // Si no se puede abrir, salir con error
        if (!f)
        {
            fprintf(stderr, "No se pudo abrir el archivo: %s\n", path);
            free_output_buffer();
            free_symbol_report();
            free_error_report();
            yylex_destroy();
            return 2;
        }
        // Leer todo el contenido del archivo
        fseek(f, 0, SEEK_END);
        long len = ftell(f);
        fseek(f, 0, SEEK_SET);
        char *content = (char *)malloc((size_t)len + 1);

        // Si no hay memoria, salir con error
        if (!content)
        {
            fclose(f);
            fprintf(stderr, "Memoria insuficiente.\n");
            free_output_buffer();
            free_symbol_report();
            free_error_report();
            yylex_destroy();
            return 3;
        }
        fread(content, 1, (size_t)len, f);
        content[len] = '\0';
        fclose(f);

        // Reset de estado
        ast_root = NULL;
        yylineno = 1;
        yycolumn = 1;
        clear_output_buffer();
        clear_symbol_report();
        clear_error_report();

        // Parsear (para ambos modos)
        YY_BUFFER_STATE buffer_state = yy_scan_string(content);
        yyparse();
        if (get_error_list() == NULL && ast_root)
        {
            if (strcmp(argv[1], "--run") == 0)
            {
                // Interpretación tradicional
                Context *contextPadre = nuevoContext(NULL, "global");
                ast_root->interpret(ast_root, contextPadre);
            }
            else
            {
                // Generación ARM64
                // Asegurar carpeta de salida
                mkdir("arm", 0777);
                int rc = arm64_generate_program(ast_root, "arm/salida.s");
                if (rc != 0)
                {
                    fprintf(stderr, "Fallo generando ARM64 a 'arm/salida.s'\n");
                }
            }
        }
        yy_delete_buffer(buffer_state);
        free(content);

        // Mensaje final coherente con la GUI/CLI
        if (get_error_list() != NULL)
        {
            clear_output_buffer();
            append_to_output("======== Se encontraron errores durante el análisis ========\nVer la tabla de errores para más detalles.\n");
        }
        else
        {
            if (strcmp(argv[1], "--run") == 0)
                append_to_output("\n\n======== Código analizado y ejecutado correctamente ========\n");
            else
                append_to_output("\n\n======== Código analizado y ensamblador ARM64 generado en arm/salida.s ========\n");
        }

        // Imprimir salida y, si se desea, errores/símbolos en modo texto sencillo
        fputs(get_output_buffer(), stdout);

    // Imprimir tabla de errores por stderr
        const ErrorInfo *errors = get_error_list();
        while (errors)
        {
            fprintf(stderr, "[%u] %s: %s (lexema='%s') en %s:%u,%u\n",
                    errors->id, errors->type, errors->description, errors->lexeme,
                    errors->context_name, errors->line, errors->column);
            errors = errors->next;
        }

        free_output_buffer();
        free_symbol_report();
        free_error_report();
        yylex_destroy();
        if (current_file_path)
        {
            g_free(current_file_path);
        }
        return (get_error_list() == NULL) ? 0 : 1;
    }

    // Modo GUI por defecto
    GtkApplication *app;
    int status;
    AppWidgets *widgets = g_malloc(sizeof(AppWidgets));

    app = gtk_application_new("com.mi.interprete", G_APPLICATION_HANDLES_OPEN);
    g_signal_connect(app, "activate", G_CALLBACK(activate), widgets);
    g_signal_connect(app, "open", G_CALLBACK(on_app_open), widgets);
    g_signal_connect(app, "open", G_CALLBACK(on_app_open), widgets); // Connect the 'open' signal
    status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);

    g_free(widgets);
    free_output_buffer();
    free_symbol_report();
    free_error_report();
    yylex_destroy();

    // Liberar la ruta del archivo actual si existe
    if (current_file_path)
    {
        g_free(current_file_path);
    }

    return status;
}

//=====================================================================
// LÓGICA DE TABLAS
//=====================================================================
enum
{
    ERR_COL_ID,
    ERR_COL_TYPE,
    ERR_COL_LEXEME,
    ERR_COL_DESC,
    ERR_COL_CONTEXT,
    ERR_COL_LINE,
    ERR_COL_COLUMN,
    ERR_NUM_COLS
};

// Función para mostrar la ventana de la tabla de errores
static void display_error_table_window(GtkWindow *parent)
{
    GtkWidget *window, *scrolled_window, *tree_view;
    GtkListStore *store;
    GtkCellRenderer *renderer;
    GtkTreeViewColumn *column;
    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "Tabla de Errores");
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 400);
    gtk_window_set_transient_for(GTK_WINDOW(window), parent);
    gtk_window_set_modal(GTK_WINDOW(window), TRUE);
    gtk_container_set_border_width(GTK_CONTAINER(window), 10);
    store = gtk_list_store_new(ERR_NUM_COLS, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT);
    const ErrorInfo *errors = get_error_list();

    // Llenar la lista con los errores
    while (errors)
    {
        GtkTreeIter iter;
        gtk_list_store_append(store, &iter);
        gtk_list_store_set(store, &iter,
                           ERR_COL_ID, errors->id, ERR_COL_TYPE, errors->type,
                           ERR_COL_LEXEME, errors->lexeme, ERR_COL_DESC, errors->description,
                           ERR_COL_CONTEXT, errors->context_name,
                           ERR_COL_LINE, errors->line, ERR_COL_COLUMN, errors->column, -1);
        errors = errors->next;
    }

    // Crear la vista de árbol y las columnas
    tree_view = gtk_tree_view_new_with_model(GTK_TREE_MODEL(store));
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("#", renderer, "text", ERR_COL_ID, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Tipo", renderer, "text", ERR_COL_TYPE, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Lexema", renderer, "text", ERR_COL_LEXEME, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Descripción", renderer, "text", ERR_COL_DESC, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Contexto", renderer, "text", ERR_COL_CONTEXT, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Línea", renderer, "text", ERR_COL_LINE, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Columna", renderer, "text", ERR_COL_COLUMN, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    scrolled_window = gtk_scrolled_window_new(NULL, NULL);
    gtk_container_add(GTK_CONTAINER(scrolled_window), tree_view);
    gtk_container_add(GTK_CONTAINER(window), scrolled_window);
    gtk_widget_show_all(window);
}

enum
{
    SYM_COL_ID,
    SYM_COL_NAME,
    SYM_COL_TYPE,
    SYM_COL_VALUE,
    SYM_COL_CONTEXT,
    SYM_COL_LINE,
    SYM_COL_COLUMN,
    SYM_NUM_COLS
};

// Función para mostrar la ventana de la tabla de símbolos
static void display_symbol_table_window(GtkWindow *parent)
{
    GtkWidget *window, *scrolled_window, *tree_view;
    GtkListStore *store;
    GtkCellRenderer *renderer;
    GtkTreeViewColumn *column;
    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "Tabla de Símbolos");
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 400);
    gtk_window_set_transient_for(GTK_WINDOW(window), parent);
    gtk_window_set_modal(GTK_WINDOW(window), TRUE);
    gtk_container_set_border_width(GTK_CONTAINER(window), 10);
    store = gtk_list_store_new(SYM_NUM_COLS, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT);
    const SymbolInfo *symbols = get_symbol_list();

    // Llenar la lista con los símbolos
    while (symbols)
    {
        GtkTreeIter iter;
        gtk_list_store_append(store, &iter);
        gtk_list_store_set(store, &iter,
                           SYM_COL_ID, symbols->id, SYM_COL_NAME, symbols->name,
                           SYM_COL_TYPE, symbols->type, SYM_COL_VALUE, symbols->value,
                           SYM_COL_CONTEXT, symbols->context_name, SYM_COL_LINE, symbols->line,
                           SYM_COL_COLUMN, symbols->column, -1);
        symbols = symbols->next;
    }
    tree_view = gtk_tree_view_new_with_model(GTK_TREE_MODEL(store));
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("#", renderer, "text", SYM_COL_ID, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Nombre", renderer, "text", SYM_COL_NAME, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Tipo", renderer, "text", SYM_COL_TYPE, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Valor", renderer, "text", SYM_COL_VALUE, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Contexto", renderer, "text", SYM_COL_CONTEXT, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Línea", renderer, "text", SYM_COL_LINE, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    renderer = gtk_cell_renderer_text_new();
    column = gtk_tree_view_column_new_with_attributes("Columna", renderer, "text", SYM_COL_COLUMN, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
    scrolled_window = gtk_scrolled_window_new(NULL, NULL);
    gtk_container_add(GTK_CONTAINER(scrolled_window), tree_view);
    gtk_container_add(GTK_CONTAINER(window), scrolled_window);
    gtk_widget_show_all(window);
}
