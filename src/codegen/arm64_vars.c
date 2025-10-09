#include "codegen/arm64_vars.h"
#include <stdlib.h>
#include <string.h>

static VarEntry *vars_head = NULL;
static int local_bytes = 0;

static void emitln(FILE *f, const char *s) { fputs(s, f); fputc('\n', f); }

VarEntry *vars_buscar(const char *name) {
    for (VarEntry *v = vars_head; v; v = v->next) {
        if (strcmp(v->name, name) == 0) return v;
    }
    return NULL;
}

VarEntry *vars_agregar(const char *name, TipoDato tipo, int size_bytes, FILE *ftext) {
    int sz = size_bytes;
    if (sz % 8 != 0) sz = ((sz / 8) + 1) * 8;
    local_bytes += sz;
    char line[64];
    snprintf(line, sizeof(line), "    sub sp, sp, #%d", sz);
    emitln(ftext, line);
    VarEntry *v = (VarEntry *)calloc(1, sizeof(VarEntry));
    v->name = strdup(name);
    v->tipo = tipo;
    v->offset = local_bytes;
    v->next = vars_head;
    vars_head = v;
    return v;
}

int vars_local_bytes(void) { return local_bytes; }

void vars_epilogo(FILE *ftext) {
    if (local_bytes > 0) {
        char addb[64]; snprintf(addb, sizeof(addb), "    add sp, sp, #%d", local_bytes); emitln(ftext, addb);
    }
}

void vars_reset(void) {
    while (vars_head) {
        VarEntry *nx = vars_head->next;
        free(vars_head->name);
        free(vars_head);
        vars_head = nx;
    }
    local_bytes = 0;
}
