#ifndef OUTPUT_BUFFER_H
#define OUTPUT_BUFFER_H

// Inicializa el búfer
void init_output_buffer();

// Agrega texto al final del búfer
void append_to_output(const char *text);

// Obtiene el contenido actual del búfer
const char *get_output_buffer();

// Limpia el búfer para una nueva ejecución
void clear_output_buffer();

// Libera la memoria usada por el búfer al final del programa
void free_output_buffer();

#endif