#include "codegen/arm64_globals.h"
#include <string.h>
#include <stdlib.h>
#include "ast/nodos/expresiones/terminales/primitivos.h"

static GlobalInfo g_globals[256];
static int g_count = 0;

void globals_reset(void) { g_count = 0; }

// Registrar una variable global
void globals_register(const char *name, TipoDato tipo, int is_const, AbstractExpresion *init)
{
    if (!name || g_count >= (int)(sizeof(g_globals) / sizeof(g_globals[0])))
        return;

    // Evitar duplicados
    for (int i = 0; i < g_count; ++i)
    {
        if (strcmp(g_globals[i].name, name) == 0)
            return;
    }
    g_globals[g_count].name = name;
    g_globals[g_count].tipo = tipo;
    g_globals[g_count].is_const = is_const;
    g_globals[g_count].init = init;
    g_count++;
}

// Buscar variable global por nombre
const GlobalInfo *globals_lookup(const char *name)
{
    for (int i = 0; i < g_count; ++i)
    {
        if (strcmp(g_globals[i].name, name) == 0)
            return &g_globals[i];
    }
    return NULL;
}

// Emitir sección .data con variables globales
void globals_emit_data(FILE *f)
{
    if (g_count == 0)
        return;
    // Emitimos una sección .data separada con símbolos globales
    fprintf(f, "\n// --- Variables globales ---\n");
    for (int i = 0; i < g_count; ++i)
    {
        const GlobalInfo *gi = &g_globals[i];
        // etiqueta: g_<name>
        fprintf(f, "g_%s:    ", gi->name);
        // Si es primitivo INT/BOOLEAN/CHAR con valor literal, usar .quad con el valor.
        long init_q = 0;
        int has_init = 0;
        if (gi->init && gi->init->node_type && strcmp(gi->init->node_type, "Primitivo") == 0)
        {
            PrimitivoExpresion *p = (PrimitivoExpresion *)gi->init;
            if (p->tipo == INT)
            {
                if (p->valor)
                {
                    // Soportar decimal y hexadecimal
                    if (strncmp(p->valor, "0x", 2) == 0 || strncmp(p->valor, "0X", 2) == 0)
                        init_q = strtol(p->valor, NULL, 16);
                    else
                        init_q = strtol(p->valor, NULL, 10);
                }
                has_init = 1;
            }
            else if (p->tipo == BOOLEAN)
            {
                init_q = (p->valor && strcmp(p->valor, "true") == 0) ? 1 : 0;
                has_init = 1;
            }
            else if (p->tipo == CHAR)
            {
                // Soportar escapes simples
                if (p->valor)
                {
                    const char *s = p->valor;
                    size_t n = strlen(s);
                    int cp = 0;
                    if (n >= 2 && s[0] == '\\')
                    {
                        switch (s[1])
                        {
                        case 'n':
                            cp = '\n';
                            break;
                        case 't':
                            cp = '\t';
                            break;
                        case 'r':
                            cp = '\r';
                            break;
                        case '\\':
                            cp = '\\';
                            break;
                        case '"':
                            cp = '"';
                            break;
                        case '\'':
                            cp = '\'';
                            break;
                        default:
                            cp = (unsigned char)s[1];
                            break;
                        }
                    }
                    else
                    {
                        cp = (unsigned char)s[0];
                    }
                    init_q = cp;
                    has_init = 1;
                }
            }
        }
        if (has_init)
            fprintf(f, ".quad %ld\n", init_q);
        else
            fprintf(f, ".quad 0\n");
    }
}
