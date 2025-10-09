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
    n->text = strdup(text ? text : "");
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
