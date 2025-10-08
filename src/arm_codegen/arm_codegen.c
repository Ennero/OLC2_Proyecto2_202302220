#include "arm_codegen.h"
#include <stdio.h>
#include <stdlib.h>

int generar_arm_desde_ast(AbstractExpresion *programa, const char *ruta_salida)
{
    (void)programa; // La primera fase genera un stub sin utilizar el AST.

    if (ruta_salida == NULL)
    {
        return -1;
    }

    FILE *out = fopen(ruta_salida, "w");
    if (!out)
    {
        return -2;
    }

    fprintf(out, "// Archivo generado automáticamente por el compilador JavaLang -> AArch64\n");
    fprintf(out, "// Aún en fase inicial: solo contiene un esqueleto de programa\n\n");

    fprintf(out, ".text\n");
    fprintf(out, ".global main\n\n");
    fprintf(out, "main:\n");
    fprintf(out, "    stp x29, x30, [sp, -16]!\n");
    fprintf(out, "    mov x29, sp\n\n");
    fprintf(out, "    // TODO: insertar instrucciones traducidas del programa JavaLang\n\n");
    fprintf(out, "    mov w0, #0\n");
    fprintf(out, "    ldp x29, x30, [sp], 16\n");
    fprintf(out, "    ret\n");

    fclose(out);
    return 0;
}
