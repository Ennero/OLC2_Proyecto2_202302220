#include "utils/comment_tracker.h"
#include <stdlib.h>
#include <string.h>

static ComentarioFuente *comentarios = NULL;
static size_t cantidad_comentarios = 0;
static size_t capacidad_comentarios = 0;

static int asegurar_capacidad(size_t adicional)
{
    size_t requerida = cantidad_comentarios + adicional;
    if (requerida <= capacidad_comentarios)
    {
        return 1;
    }

    size_t nueva_capacidad = capacidad_comentarios == 0 ? 16 : capacidad_comentarios * 2;
    while (nueva_capacidad < requerida)
    {
        nueva_capacidad *= 2;
    }

    ComentarioFuente *nuevos = realloc(comentarios, nueva_capacidad * sizeof(ComentarioFuente));
    if (!nuevos)
    {
        return 0;
    }

    comentarios = nuevos;
    capacidad_comentarios = nueva_capacidad;
    return 1;
}

void registrar_comentario(int line, int column, const char *texto)
{
    if (!texto)
    {
        return;
    }

    size_t longitud = strlen(texto);
    char *copia = malloc(longitud + 1);
    if (!copia)
    {
        return;
    }
    memcpy(copia, texto, longitud + 1);

    if (!asegurar_capacidad(1))
    {
        free(copia);
        return;
    }

    comentarios[cantidad_comentarios].line = line;
    comentarios[cantidad_comentarios].column = column;
    comentarios[cantidad_comentarios].texto = copia;
    cantidad_comentarios++;
}

const ComentarioFuente *obtener_comentarios(size_t *cantidad)
{
    if (cantidad)
    {
        *cantidad = cantidad_comentarios;
    }
    return (const ComentarioFuente *)comentarios;
}

void clear_comment_tracker(void)
{
    if (comentarios)
    {
        for (size_t i = 0; i < cantidad_comentarios; ++i)
        {
            free(comentarios[i].texto);
        }
        free(comentarios);
    }
    comentarios = NULL;
    cantidad_comentarios = 0;
    capacidad_comentarios = 0;
}
