#include "codegen/arm64_vars.h"
#include <stdlib.h>
#include <string.h>

static VarEntry *vars_head = NULL;
static int local_bytes = 0;
// Bytes efectivamente reservados en el stack (sub sp, sp, #...)
static int allocated_bytes = 0;
// Pila de marcas de alcance: apilamos el valor de local_bytes al entrar a un bloque
typedef struct ScopeMark { int bytes_mark; struct ScopeMark *next; } ScopeMark;
static ScopeMark *scope_stack = NULL;

static void emitln(FILE *f, const char *s) { fputs(s, f); fputc('\n', f); }

VarEntry *vars_buscar(const char *name) {
    for (VarEntry *v = vars_head; v; v = v->next) {
        if (strcmp(v->name, name) == 0) return v;
    }
    return NULL;
}

VarEntry *vars_agregar(const char *name, TipoDato tipo, int size_bytes, FILE *ftext) {
    int sz = size_bytes;
    // Mínimo alineado a 8 por acceso natural de datos
    if (sz % 8 != 0) sz = ((sz / 8) + 1) * 8;
    // Mantener SP siempre alineado a 16 bytes tras cada reserva local
    // Ajustamos 'sz' con padding si local_bytes + sz no es múltiplo de 16
    int new_total = local_bytes + sz;
    int misalign = new_total % 16;
    if (misalign != 0) {
        int pad = 16 - misalign; // 8 típico cuando sz es 8 y local_bytes%16==0
        sz += pad;
        new_total += pad;
    }
    local_bytes = new_total;
    // Reservar en tiempo de emisión el delta nuevo una sola vez (high-water mark)
    if (ftext && new_total > allocated_bytes) {
        int delta = new_total - allocated_bytes;
        char sub[64]; snprintf(sub, sizeof(sub), "    sub sp, sp, #%d", delta); emitln(ftext, sub);
        allocated_bytes = new_total;
    }
    VarEntry *v = (VarEntry *)calloc(1, sizeof(VarEntry));
    v->name = strdup(name);
    v->tipo = tipo;
    v->offset = local_bytes;
    v->is_const = 0;
    v->next = vars_head;
    vars_head = v;
    return v;
}

VarEntry *vars_agregar_ext(const char *name, TipoDato tipo, int size_bytes, int is_const, FILE *ftext) {
    VarEntry *v = vars_agregar(name, tipo, size_bytes, ftext);
    v->is_const = is_const;
    return v;
}

int vars_local_bytes(void) { return local_bytes; }

void vars_epilogo(FILE *ftext) {
    // Restaurar el stack al frame pointer para evitar desbalances por rutas de control
    (void)ftext;
    // El epílogo real lo emite el generador: "mov sp, x29"
}

void vars_reset(void) {
    while (vars_head) {
        VarEntry *nx = vars_head->next;
        free(vars_head->name);
        free(vars_head);
        vars_head = nx;
    }
    local_bytes = 0;
    allocated_bytes = 0;
    while (scope_stack) { ScopeMark *nx = scope_stack->next; free(scope_stack); scope_stack = nx; }
}

void vars_push_scope(FILE *ftext) {
    (void)ftext; // Por ahora no emitimos nada al entrar; solo marcamos
    ScopeMark *m = (ScopeMark *)calloc(1, sizeof(ScopeMark));
    m->bytes_mark = local_bytes;
    m->next = scope_stack;
    scope_stack = m;
}

void vars_pop_scope(FILE *ftext) {
    if (!scope_stack) return;
    int target_bytes = scope_stack->bytes_mark;
    // Liberar entradas VarEntry hasta volver al offset del alcance anterior
    while (vars_head && vars_head->offset > target_bytes) {
        VarEntry *nx = vars_head->next;
        free(vars_head->name);
        free(vars_head);
        vars_head = nx;
    }
    // No ajustar el stack en tiempo de ejecución aquí.
    // Mantener local_bytes como el "high-water mark" de la función para que
    // el epílogo único de la función (vars_epilogo) restaure todo de una vez.
    // Pop scope mark
    ScopeMark *old = scope_stack; scope_stack = scope_stack->next; free(old);
}
