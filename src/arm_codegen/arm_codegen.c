#include "arm_codegen.h"
#include "ast/nodos/expresiones/terminales/primitivos.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct
{
    char *label;
    char *text; // Decodificada (sin comillas, sin escapes)
} StringEntry;

typedef struct
{
    StringEntry *entries;
    size_t count;
    size_t capacity;
} StringTable;

typedef enum
{
    ARM_OP_PUTS_LITERAL,
    ARM_OP_COMMENT
} ArmOperationKind;

typedef struct
{
    ArmOperationKind kind;
    const char *string_label;
    char *comment;
    int line;
    int column;
} ArmOperation;

typedef struct
{
    ArmOperation *items;
    size_t count;
    size_t capacity;
} OperationList;

typedef struct
{
    StringTable strings;
    OperationList ops;
    int error_code;
} ArmCodegenContext;

// --------------------------------------------------------------------------------------
// Helpers para manejo de strings y operaciones
// --------------------------------------------------------------------------------------
static void string_table_init(StringTable *table)
{
    table->entries = NULL;
    table->count = 0;
    table->capacity = 0;
}

static void string_table_free(StringTable *table)
{
    if (!table)
        return;
    for (size_t i = 0; i < table->count; ++i)
    {
        free(table->entries[i].label);
        free(table->entries[i].text);
    }
    free(table->entries);
    table->entries = NULL;
    table->count = 0;
    table->capacity = 0;
}

static bool string_table_grow(StringTable *table)
{
    size_t new_capacity = table->capacity == 0 ? 8 : table->capacity * 2;
    StringEntry *new_entries = realloc(table->entries, new_capacity * sizeof(StringEntry));
    if (!new_entries)
        return false;
    table->entries = new_entries;
    table->capacity = new_capacity;
    return true;
}

static const StringEntry *string_table_intern(StringTable *table, char *decoded_text)
{
    for (size_t i = 0; i < table->count; ++i)
    {
        if (strcmp(table->entries[i].text, decoded_text) == 0)
        {
            free(decoded_text);
            return &table->entries[i];
        }
    }

    if (table->count == table->capacity && !string_table_grow(table))
    {
        free(decoded_text);
        return NULL;
    }

    char label_buffer[32];
    snprintf(label_buffer, sizeof(label_buffer), "str_%zu", table->count);
    char *label_copy = strdup(label_buffer);
    if (!label_copy)
    {
        free(decoded_text);
        return NULL;
    }

    table->entries[table->count].label = label_copy;
    table->entries[table->count].text = decoded_text;
    table->count += 1;
    return &table->entries[table->count - 1];
}

static void operations_init(OperationList *ops)
{
    ops->items = NULL;
    ops->count = 0;
    ops->capacity = 0;
}

static void operations_free(OperationList *ops)
{
    if (!ops)
        return;
    for (size_t i = 0; i < ops->count; ++i)
    {
        free(ops->items[i].comment);
    }
    free(ops->items);
    ops->items = NULL;
    ops->count = 0;
    ops->capacity = 0;
}

static bool operations_grow(OperationList *ops)
{
    size_t new_capacity = ops->capacity == 0 ? 8 : ops->capacity * 2;
    ArmOperation *new_items = realloc(ops->items, new_capacity * sizeof(ArmOperation));
    if (!new_items)
        return false;
    ops->items = new_items;
    ops->capacity = new_capacity;
    return true;
}

static bool operations_append_print(OperationList *ops, const StringEntry *entry, int line, int column)
{
    if (ops->count == ops->capacity && !operations_grow(ops))
        return false;

    ArmOperation op = {
        .kind = ARM_OP_PUTS_LITERAL,
        .string_label = entry ? entry->label : NULL,
        .comment = NULL,
        .line = line,
        .column = column};

    ops->items[ops->count++] = op;
    return true;
}

static bool operations_append_comment(OperationList *ops, int line, int column, const char *message)
{
    if (ops->count == ops->capacity && !operations_grow(ops))
        return false;

    size_t needed = strlen(message) + 64;
    char *buffer = malloc(needed);
    if (!buffer)
        return false;
    snprintf(buffer, needed, "TODO (linea %d, columna %d): %s", line, column, message);

    ArmOperation op = {
        .kind = ARM_OP_COMMENT,
        .string_label = NULL,
        .comment = buffer,
        .line = line,
        .column = column};

    ops->items[ops->count++] = op;
    return true;
}

// --------------------------------------------------------------------------------------
// Decodificación de literales String (similar a interpretador)
// --------------------------------------------------------------------------------------
static size_t utf8_encode_cp(int cp, char *out)
{
    if (cp <= 0x7F)
    {
        out[0] = (char)cp;
        return 1;
    }
    if (cp <= 0x7FF)
    {
        out[0] = (char)(0xC0 | ((cp >> 6) & 0x1F));
        out[1] = (char)(0x80 | (cp & 0x3F));
        return 2;
    }
    if (cp <= 0xFFFF)
    {
        out[0] = (char)(0xE0 | ((cp >> 12) & 0x0F));
        out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[2] = (char)(0x80 | (cp & 0x3F));
        return 3;
    }

    out[0] = (char)(0xF0 | ((cp >> 18) & 0x07));
    out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
    out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
    out[3] = (char)(0x80 | (cp & 0x3F));
    return 4;
}

static int parse_unicode_escape_decimal(const char *digits, size_t maxlen)
{
    size_t n = 0;
    while (n < maxlen && n < 5 && digits[n] >= '0' && digits[n] <= '9')
        n++;
    if (n == 0)
        return 0;

    char buffer[6];
    memcpy(buffer, digits, n);
    buffer[n] = '\0';
    long val = strtol(buffer, NULL, 10);
    if (val < 0)
        val = 0;
    if (val > 0x10FFFF)
        val = 0x10FFFF;
    return (int)val;
}

static char *decode_java_string_literal(const char *input)
{
    if (!input)
        return NULL;
    size_t len = strlen(input);
    char *output = malloc(len * 4 + 1);
    if (!output)
        return NULL;

    size_t i = 0;
    size_t j = 0;
    while (i < len)
    {
        if (input[i] == '\\' && i + 1 < len)
        {
            i++;
            switch (input[i])
            {
            case 'n':
                output[j++] = '\n';
                break;
            case 't':
                output[j++] = '\t';
                break;
            case 'r':
                output[j++] = '\r';
                break;
            case '\\':
                output[j++] = '\\';
                break;
            case '"':
                output[j++] = '"';
                break;
            case '\'':
                output[j++] = '\'';
                break;
            case 'u':
            {
                size_t remain = len - (i + 1);
                int unicode_val = parse_unicode_escape_decimal(&input[i + 1], remain);
                char tmp[4];
                size_t written = utf8_encode_cp(unicode_val, tmp);
                for (size_t k = 0; k < written; ++k)
                    output[j++] = tmp[k];
                size_t consumed = 0;
                while (consumed < remain && consumed < 5 && input[i + 1 + consumed] >= '0' && input[i + 1 + consumed] <= '9')
                    consumed++;
                i += consumed;
            }
            break;
            default:
                output[j++] = '\\';
                output[j++] = input[i];
                break;
            }
        }
        else
        {
            output[j++] = input[i];
        }
        i++;
    }
    output[j] = '\0';
    return output;
}

// --------------------------------------------------------------------------------------
// Recorrido del AST para detectar prints simples
// --------------------------------------------------------------------------------------
static void collect_print_literal(AbstractExpresion *print_node, ArmCodegenContext *ctx)
{
    if (!print_node || !ctx)
        return;

    AbstractExpresion *lista = (print_node->numHijos > 0) ? print_node->hijos[0] : NULL;
    if (!lista || lista->numHijos != 1)
    {
        if (!operations_append_comment(&ctx->ops, print_node->line, print_node->column, "System.out.println actualmente solo soporta un literal String."))
        {
            ctx->error_code = -3;
        }
        return;
    }

    AbstractExpresion *expr = lista->hijos[0];
    if (!expr || strcmp(expr->node_type, "Primitivo") != 0)
    {
        if (!operations_append_comment(&ctx->ops, print_node->line, print_node->column, "System.out.println solo soporta, por ahora, literales String."))
        {
            ctx->error_code = -3;
        }
        return;
    }

    PrimitivoExpresion *prim = (PrimitivoExpresion *)expr;
    if (prim->tipo != STRING || prim->valor == NULL)
    {
        if (!operations_append_comment(&ctx->ops, print_node->line, print_node->column, "Literal soportado debe ser de tipo String."))
        {
            ctx->error_code = -3;
        }
        return;
    }

    char *decoded = decode_java_string_literal(prim->valor);
    if (!decoded)
    {
        ctx->error_code = -3;
        return;
    }

    const StringEntry *entry = string_table_intern(&ctx->strings, decoded);
    if (!entry)
    {
        ctx->error_code = -3;
        return;
    }

    if (!operations_append_print(&ctx->ops, entry, print_node->line, print_node->column))
    {
        ctx->error_code = -3;
    }
}

static void collect_nodes(AbstractExpresion *node, ArmCodegenContext *ctx)
{
    if (!node || !ctx || ctx->error_code != 0)
        return;

    if (node->node_type && strcmp(node->node_type, "Print") == 0)
    {
        collect_print_literal(node, ctx);
    }

    for (size_t i = 0; i < node->numHijos; ++i)
    {
        collect_nodes(node->hijos[i], ctx);
    }
}

// --------------------------------------------------------------------------------------
// Emisión de secciones en ensamblador
// --------------------------------------------------------------------------------------
static void emit_data_section(FILE *out, const StringTable *strings)
{
    if (!strings || strings->count == 0)
        return;

    fprintf(out, ".data\n\n");
    for (size_t i = 0; i < strings->count; ++i)
    {
        const StringEntry *entry = &strings->entries[i];
        fprintf(out, "%s:\n    .asciz \"", entry->label);
        const unsigned char *p = (const unsigned char *)entry->text;
        while (*p)
        {
            unsigned char c = *p++;
            switch (c)
            {
            case '\\':
                fputs("\\\\", out);
                break;
            case '\"':
                fputs("\\\"", out);
                break;
            case '\n':
                fputs("\\n", out);
                break;
            case '\t':
                fputs("\\t", out);
                break;
            case '\r':
                fputs("\\r", out);
                break;
            default:
                if (c < 32 || c > 126)
                {
                    fprintf(out, "\\x%02X", c);
                }
                else
                {
                    fputc(c, out);
                }
                break;
            }
        }
        fputs("\"\n\n", out);
    }
}

static void emit_text_section(FILE *out, const OperationList *ops)
{
    fprintf(out, ".text\n");
    fprintf(out, ".global main\n\n");
    fprintf(out, "main:\n");
    fprintf(out, "    stp x29, x30, [sp, -16]!\n");
    fprintf(out, "    mov x29, sp\n\n");

    for (size_t i = 0; i < ops->count; ++i)
    {
        const ArmOperation *op = &ops->items[i];
        switch (op->kind)
        {
        case ARM_OP_PUTS_LITERAL:
            if (op->string_label)
            {
                fprintf(out, "    ldr x0, =%s\n", op->string_label);
            }
            else
            {
                fprintf(out, "    // Operación de impresión con etiqueta nula\n");
            }
            fprintf(out, "    bl puts\n\n");
            break;
        case ARM_OP_COMMENT:
            fprintf(out, "    // %s\n\n", op->comment ? op->comment : "Operación no soportada");
            break;
        }
    }

    fprintf(out, "    mov w0, #0\n");
    fprintf(out, "    ldp x29, x30, [sp], 16\n");
    fprintf(out, "    ret\n");
}

// --------------------------------------------------------------------------------------
// Función pública principal
// --------------------------------------------------------------------------------------
int generar_arm_desde_ast(AbstractExpresion *programa, const char *ruta_salida)
{
    if (ruta_salida == NULL)
    {
        return -1;
    }

    if (programa == NULL)
    {
        return -2;
    }

    ArmCodegenContext ctx;
    string_table_init(&ctx.strings);
    operations_init(&ctx.ops);
    ctx.error_code = 0;

    collect_nodes(programa, &ctx);

    if (ctx.error_code != 0)
    {
        operations_free(&ctx.ops);
        string_table_free(&ctx.strings);
        return ctx.error_code;
    }

    FILE *out = fopen(ruta_salida, "w");
    if (!out)
    {
        operations_free(&ctx.ops);
        string_table_free(&ctx.strings);
        return -3;
    }

    fprintf(out, "// Archivo generado automáticamente por el compilador JavaLang -> AArch64\n");
    fprintf(out, "// Fase 2: Soporte inicial para System.out.println con literales String\n\n");

    emit_data_section(out, &ctx.strings);
    emit_text_section(out, &ctx.ops);

    fclose(out);

    operations_free(&ctx.ops);
    string_table_free(&ctx.strings);
    return 0;
}
