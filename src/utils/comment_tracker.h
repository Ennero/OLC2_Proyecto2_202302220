#ifndef COMMENT_TRACKER_H
#define COMMENT_TRACKER_H

#include <stddef.h>

typedef struct
{
    int line;
    int column;
    char *texto;
} ComentarioFuente;

void registrar_comentario(int line, int column, const char *texto);
const ComentarioFuente *obtener_comentarios(size_t *cantidad);
void clear_comment_tracker(void);

#endif // COMMENT_TRACKER_H
