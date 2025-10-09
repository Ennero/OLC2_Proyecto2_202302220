#include "codegen/arm64_core.h"
#include <stdlib.h>
#include <string.h>

typedef struct StrLit {
    char *label;
    char *text;
    struct StrLit *next;
} StrLit;

static StrLit *str_head = NULL, *str_tail = NULL;
static int str_counter = 0;

void core_emitln(FILE *f, const char *s) { fputs(s, f); fputc('\n', f); }

// --- Decodificación de escapes para strings (similar al intérprete) ---
static size_t utf8_encode_cp(int cp, char *out) {
    if (cp <= 0x7F) { out[0] = (char)cp; return 1; }
    else if (cp <= 0x7FF) { out[0] = (char)(0xC0 | ((cp >> 6) & 0x1F)); out[1] = (char)(0x80 | (cp & 0x3F)); return 2; }
    else if (cp <= 0xFFFF) { out[0] = (char)(0xE0 | ((cp >> 12) & 0x0F)); out[1] = (char)(0x80 | ((cp >> 6) & 0x3F)); out[2] = (char)(0x80 | (cp & 0x3F)); return 3; }
    else { out[0] = (char)(0xF0 | ((cp >> 18) & 0x07)); out[1] = (char)(0x80 | ((cp >> 12) & 0x3F)); out[2] = (char)(0x80 | ((cp >> 6) & 0x3F)); out[3] = (char)(0x80 | (cp & 0x3F)); return 4; }
}

static int parse_unicode_escape_decimal(const char *digits, size_t maxlen) {
    size_t n = 0; long val = 0;
    while (n < maxlen && n < 5 && digits[n] >= '0' && digits[n] <= '9') { val = val*10 + (digits[n]-'0'); n++; }
    if (val < 0) val = 0; if (val > 0x10FFFF) val = 0x10FFFF; return (int)val;
}

static char *process_string_escapes_codegen(const char *input) {
    if (!input) return strdup("");
    size_t len = strlen(input);
    char *out = (char *)malloc(len*4 + 1); // peor caso
    if (!out) return strdup("");
    size_t i = 0, j = 0;
    while (i < len) {
        if (input[i] == '\\' && i + 1 < len) {
            i++;
            switch (input[i]) {
                case 'n': out[j++] = '\n'; break;
                case 't': out[j++] = '\t'; break;
                case 'r': out[j++] = '\r'; break;
                case '\\': out[j++] = '\\'; break;
                case '"': out[j++] = '"'; break;
                case '\'': out[j++] = '\''; break;
                case 'u': {
                    size_t remain = len - (i + 1);
                    int cp = parse_unicode_escape_decimal(&input[i+1], remain);
                    char tmp[4]; size_t n = utf8_encode_cp(cp, tmp);
                    for (size_t k = 0; k < n; k++) out[j++] = tmp[k];
                    size_t consumed = 0;
                    while (consumed < remain && consumed < 5 && input[i+1+consumed] >= '0' && input[i+1+consumed] <= '9') consumed++;
                    i += consumed;
                    break;
                }
                default:
                    out[j++] = '\\';
                    out[j++] = input[i];
                    break;
            }
        } else {
            out[j++] = input[i];
        }
        i++;
    }
    out[j] = '\0';
    return out;
}

static char *escape_for_asciz(const char *s) {
    size_t len = strlen(s);
    char *out = (char *)malloc(len * 4 + 1);
    size_t j = 0;
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char)s[i];
        switch (c) {
            case '"': out[j++]='\\'; out[j++]='"'; break;
            case '\\': out[j++]='\\'; out[j++]='\\'; break;
            case '\n': out[j++]='\\'; out[j++]='n'; break;
            case '\t': out[j++]='\\'; out[j++]='t'; break;
            case '\r': out[j++]='\\'; out[j++]='r'; break;
            default: out[j++] = c;
        }
    }
    out[j] = '\0';
    return out;
}

const char *core_add_string_literal(const char *text) {
    StrLit *n = (StrLit *)calloc(1, sizeof(StrLit));
    char label[64];
    snprintf(label, sizeof(label), "str_lit_%d", ++str_counter);
    n->label = strdup(label);
    // Decodificar secuencias de escape antes de almacenarlo; luego se re-escapa para .asciz al emitir
    char *processed = process_string_escapes_codegen(text ? text : "");
    n->text = processed;
    if (!str_head) str_head = n; else str_tail->next = n; str_tail = n;
    return n->label;
}

const char *core_add_double_literal(const char *number_text) {
    StrLit *n = (StrLit *)calloc(1, sizeof(StrLit));
    char label[64];
    snprintf(label, sizeof(label), "dbl_lit_%d", ++str_counter);
    n->label = strdup(label);
    n->text = strdup(number_text ? number_text : "0");
    if (!str_head) str_head = n; else str_tail->next = n; str_tail = n;
    return n->label;
}

void core_emit_collected_literals(FILE *f) {
    core_emitln(f, "// --- Literales recolectados ---");
    core_emitln(f, ".data");
    for (StrLit *n = str_head; n; n = n->next) {
        if (strncmp(n->label, "dbl_lit_", 8) == 0) {
            char line[256];
            snprintf(line, sizeof(line), "%s:    .double %s", n->label, n->text);
            core_emitln(f, line);
        } else {
            char *esc = escape_for_asciz(n->text);
            char line[512];
            snprintf(line, sizeof(line), "%s:    .asciz \"%s\"", n->label, esc);
            core_emitln(f, line);
            free(esc);
        }
    }
}

void core_reset_literals(void) {
    while (str_head) {
        StrLit *nx = str_head->next;
        free(str_head->label);
        free(str_head->text);
        free(str_head);
        str_head = nx;
    }
    str_tail = NULL;
    str_counter = 0;
}
