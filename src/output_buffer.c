#include "output_buffer.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Variables estáticas
static char *buffer = NULL;
static size_t capacity = 0;
static size_t length = 0;

// Inicializa el búfer
void init_output_buffer()
{
    capacity = 1024; // Capacidad inicial
    buffer = malloc(capacity);
    if (buffer)
    {
        buffer[0] = '\0';
    }
    length = 0;
}

// Agrega texto al final del búfer
void append_to_output(const char *text)
{
    if (!buffer)
    {
        init_output_buffer();
    }
    size_t text_len = strlen(text);

    // Asegurar capacidad suficiente (puede requerir múltiples duplicaciones)
    size_t required = length + text_len + 1; // +1 para el terminador NULO
    if (required > capacity)
    {
        size_t new_capacity = capacity ? capacity : 1024;

        // Duplicar hasta alcanzar la capacidad requerida
        while (required > new_capacity)
        {
            new_capacity *= 2;
        }
        // Realocar el búfer a la nueva capacidad
        char *new_buffer = realloc(buffer, new_capacity);

        // Manejo de error en realloc
        if (!new_buffer)
        {
            perror("realloc output buffer");
            return;
        }
        buffer = new_buffer;
        capacity = new_capacity;
    }

    // Copiar eficientemente y mantener el NULO al final
    memcpy(buffer + length, text, text_len);
    length += text_len;
    buffer[length] = '\0';
}

// Devuelve el contenido del búfer de salida
const char *get_output_buffer()
{
    return buffer ? buffer : "";
}

// Limpia el búfer de salida
void clear_output_buffer()
{
    if (buffer)
    {
        buffer[0] = '\0';
    }
    length = 0;
}

// Libera la memoria utilizada por el búfer de salida
void free_output_buffer()
{
    free(buffer);
    buffer = NULL;
    capacity = 0;
    length = 0;
}