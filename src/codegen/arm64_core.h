#ifndef ARM64_CORE_H
#define ARM64_CORE_H
#include <stdio.h>

// Utilidad para emitir una línea
void core_emitln(FILE *f, const char *s);

// Literales de strings/dobles recolectados
const char *core_add_string_literal(const char *text);
const char *core_add_double_literal(const char *number_text);
void core_emit_collected_literals(FILE *f);
void core_reset_literals(void);

#endif // ARM64_CORE_H
