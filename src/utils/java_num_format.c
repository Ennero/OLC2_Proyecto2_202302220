// Formateo numerico similar a Java (Float/Double.toString),
#include "java_num_format.h"
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

//  Helpers para formateo
static void ensure_decimal_point(char *buf, size_t size);
static void normalize_exponent(char *buf, size_t size);

// Formatea un double similar a Java Double.toString
static void format_candidate_double(int k, int use_exp, double val, char *out, size_t out_size)
{
    // Usar notación científica o fija según el flag
    if (use_exp)
    {
        // Usar 'e' minúscula temporalmente; se normaliza después
        snprintf(out, out_size, "%.*e", k, val);
    }
    // Notación fija
    else
    {
        // Usar 'f' minúscula
        snprintf(out, out_size, "%.*f", k, val);
    }
    // Asegurar que haya un punto decimal
    ensure_decimal_point(out, out_size);

    // Normalizar el exponente al estilo Java
    normalize_exponent(out, out_size);
}

// Verifica si la representación preserva el signo de -0.0
static int preserves_neg_zero_double(double val, const char *s)
{
    if (val == 0.0 && signbit(val))
        return s && s[0] == '-';
    return 1;
}


// Formatea un float similar a Java Float.toString
static void format_candidate_float(int k, int use_exp, float val, char *out, size_t out_size)
{
    if (use_exp)
    {
        snprintf(out, out_size, "%.*e", k, (double)val);
    }
    else
    {
        snprintf(out, out_size, "%.*f", k, (double)val);
    }
    ensure_decimal_point(out, out_size);
    normalize_exponent(out, out_size);
}

// Verifica si la representación preserva el signo de -0.0
static int preserves_neg_zero_float(float val, const char *s)
{
    // Verifica si la representación preserva el signo de -0.0
    if (val == 0.0f && signbit(val))
        return s && s[0] == '-';
    return 1;
}

// Asegura que haya un punto decimal en la representación
static void ensure_decimal_point(char *buf, size_t size)
{
    // Si hay 'e' o 'E', es notación científica: asegurar decimal antes del exponente
    char *e = strpbrk(buf, "eE");
    if (e)
    {
        // Verificar si hay un punto decimal antes del exponente
        int has_dot = 0;
        for (char *p = buf; p < e; ++p)
            if (*p == '.')
            {
                has_dot = 1;
                break;
            }
        if (!has_dot)
        {
            // ¿Insertar ".0" antes del exponente si hay espacio?
            size_t len = strlen(buf);
            if (len + 2 < size)
            {
                memmove(e + 2, e, len - (e - buf) + 1);
                e[0] = '.';
                e[1] = '0';
            }
        }
        return;
    }
    //  Notación fija: asegurar punto decimal en toda la cadena
    if (!strchr(buf, '.'))
    {
        size_t len = strlen(buf);
        if (len + 2 < size)
        {
            buf[len] = '.';
            buf[len + 1] = '0';
            buf[len + 2] = '\0';
        }
    }
}

// Normaliza el exponente al estilo Java (E mayúscula, sin '+' y sin ceros a la izquierda)
static void normalize_exponent(char *buf, size_t size)
{
    (void)size;
    char *e = strpbrk(buf, "eE");
    if (!e)
        return;
    *e = 'E';

    // Eliminar '+' y ceros a la izquierda en el exponente
    char *p = e + 1;
    if (*p == '+')
    {
        memmove(p, p + 1, strlen(p));
    }

    // Puntero para procesar dígitos del exponente
    char *d = p;
    if (*d == '-')
    {
        d = p + 1; // mantener el signo negativo
    }

    // Eliminar ceros a la izquierda en el exponente, pero mantener al menos un dígito
    while (*d == '0' && isdigit((unsigned char)d[1]))
    {
        memmove(d, d + 1, strlen(d));
    }
    // Si el exponente terminó vacío después de E o E-, asegurar un cero
    if (*d == '\0')
    {
        *d = '0';
        d[1] = '\0';
    }
}

// Función pública para formatear un double al estilo Java
void java_format_double(double v, char *buf, size_t size)
{
    if (isnan(v))
    {
        snprintf(buf, size, "NaN");
        return;
    }
    if (isinf(v))
    {
        snprintf(buf, size, (v > 0) ? "Infinity" : "-Infinity");
        return;
    }
    // Mismos umbrales que Double según reglas de formateo de Java
    double av = fabs(v);
    int use_exp_style = (av != 0.0) && (av >= 1e7 || av < 1e-3);

    // Preparar un fallback genérico seguro
    char generic[256];
    snprintf(generic, sizeof(generic), "%.17g", v);
    ensure_decimal_point(generic, sizeof(generic));
    normalize_exponent(generic, sizeof(generic));

    // Intentar con diferentes precisiones
    char candidate[256];
    for (int k = 1; k <= 17; ++k)
    {
        // Intentar formatear con k dígitos significativos
        format_candidate_double(k, use_exp_style, v, candidate, sizeof(candidate));
        char *endptr = NULL;
        double parsed = strtod(candidate, &endptr);
        if (endptr && *endptr == '\0' && parsed == v && preserves_neg_zero_double(v, candidate))
        {
            snprintf(buf, size, "%s", candidate);
            return;
        }
    }

    // Fallback a genérico
    snprintf(buf, size, "%s", generic);

    // Forzar estilo si los umbrales demandan notación científica pero el genérico eligió fija
    if (use_exp_style && !strpbrk(buf, "eE"))
    {
        for (int k = 1; k <= 17; ++k)
        {
            format_candidate_double(k, 1 /*force exp*/, v, candidate, sizeof(candidate));
            char *endptr = NULL;
            double parsed = strtod(candidate, &endptr);
            if (endptr && *endptr == '\0' && parsed == v && preserves_neg_zero_double(v, candidate))
            {
                snprintf(buf, size, "%s", candidate);
                return;
            }
        }
        // Último recurso: usar una forma exponencial precisa
        snprintf(buf, size, "%.17e", v);
        ensure_decimal_point(buf, size);
        normalize_exponent(buf, size);
    }
}

// Función pública para formatear un float al estilo Java
void java_format_float(float v, char *buf, size_t size)
{
    if (isnan(v))
    {
        snprintf(buf, size, "NaN");
        return;
    }
    if (isinf(v))
    {
        snprintf(buf, size, (v > 0) ? "Infinity" : "-Infinity");
        return;
    }
    // Mismos umbrales que Double según reglas de formateo de Java
    double av = fabs((double)v);
    int use_exp_style = (av != 0.0) && (av >= 1e7 || av < 1e-3);

    // Preparar un fallback genérico seguro
    char generic[256];
    snprintf(generic, sizeof(generic), "%.7g", v);
    ensure_decimal_point(generic, sizeof(generic));
    normalize_exponent(generic, sizeof(generic));

    char candidate[256];

    // Intentar con diferentes precisiones
    for (int k = 1; k <= 7; ++k)
    {
        // Intentar formatear con k dígitos significativos
        format_candidate_float(k, use_exp_style, v, candidate, sizeof(candidate));
        char *endptr = NULL;
        float parsed = strtof(candidate, &endptr);

        // Verificar si el formato es válido
        if (endptr && *endptr == '\0' && parsed == v && preserves_neg_zero_float(v, candidate))
        {
            snprintf(buf, size, "%s", candidate);
            return;
        }
    }

    // Fallback a genérico seguro
    snprintf(buf, size, "%s", generic);

    // Forzar estilo si los umbrales demandan notación científica pero el genérico eligió fija
    if (use_exp_style && !strpbrk(buf, "eE"))
    {
        // Intentar con diferentes precisiones
        for (int k = 1; k <= 7; ++k)
        {
            // Intentar formatear con k dígitos significativos
            format_candidate_float(k, 1 /*force exp*/, v, candidate, sizeof(candidate));
            char *endptr = NULL;
            float parsed = strtof(candidate, &endptr);
            if (endptr && *endptr == '\0' && parsed == v && preserves_neg_zero_float(v, candidate))
            {
                snprintf(buf, size, "%s", candidate);
                return;
            }
        }
        // Último recurso: usar una forma exponencial precisa
        snprintf(buf, size, "%.7e", (double)v);
        ensure_decimal_point(buf, size);
        normalize_exponent(buf, size);
    }
}
