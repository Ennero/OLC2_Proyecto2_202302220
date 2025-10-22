#include "codegen/funciones/arm64_funciones.h"
#include <string.h>
#include <stdlib.h>
#include "ast/nodos/estructuras/funciones/funcion.h"
#include "ast/nodos/estructuras/funciones/parametro.h"
#include "ast/nodos/estructuras/funciones/llamada.h"
#include "codegen/arm64_print.h"
#include "codegen/arm64_num.h"
#include "codegen/arm64_bool.h"
#include "codegen/arm64_core.h"
#include "ast/nodos/expresiones/terminales/identificadores.h"
#include "codegen/arm64_vars.h"
#include "codegen/arm64_globals.h"
// Registrar tipo base de arreglos de parámetros para direccionamiento correcto
#include "codegen/estructuras/arm64_arreglos.h"

static void emitln(FILE *f, const char *s) { core_emitln(f, s); }

static Arm64FuncionInfo __funcs[64];
static int __funcs_count = 0;


// Reinicia el registro de funciones
void arm64_funciones_reset(void)
{
    for (int i = 0; i < __funcs_count; ++i)
    {
        __funcs[i].name = NULL;
        __funcs[i].body = NULL;
        for (int j = 0; j < __funcs[i].param_count && j < 8; ++j)
        {
            __funcs[i].param_names[j] = NULL;
        }
    }
    __funcs_count = 0;
}

// Busca información de función por nombre
static Arm64FuncionInfo *funcs_lookup(const char *name)
{
    for (int i = 0; i < __funcs_count; ++i)
    {
        if (strcmp(__funcs[i].name, name) == 0)
            return &__funcs[i];
    }
    return NULL;
}

// Recorre el AST y colecta declaraciones de funciones
void arm64_funciones_colectar(AbstractExpresion *n)
{
    if (!n)
        return;
    if (n->node_type && strcmp(n->node_type, "FunctionDeclaration") == 0)
    {
        if (__funcs_count < (int)(sizeof(__funcs) / sizeof(__funcs[0])))
        {
            FuncionDeclarationNode *fn = (FuncionDeclarationNode *)n;
            Arm64FuncionInfo *fi = &__funcs[__funcs_count++];
            memset(fi, 0, sizeof(*fi));
            fi->name = fn->nombre;

            // Si la función retorna un arreglo (retorno_dimensiones > 0), tratar el retorno como ARRAY (puntero)
            fi->ret = (fn->retorno_dimensiones > 0) ? ARRAY : fn->tipo_retorno;
            AbstractExpresion *params_list = n->hijos[0];
            fi->param_count = (int)(params_list ? params_list->numHijos : 0);
            if (fi->param_count > 8)
                fi->param_count = 8;
            for (int i = 0; i < fi->param_count; ++i)
            {
                ParametroNode *pn = (ParametroNode *)params_list->hijos[i];
                
                // Si el parámetro es un arreglo (dimensiones > 0), trátalo como ARRAY (puntero)
                fi->param_types[i] = (pn->dimensiones > 0) ? ARRAY : pn->tipo;
                fi->param_names[i] = pn->nombre;

                // Registrar tipo base de arreglos de parámetros para que accesos y foreach usen el tamaño correcto
                if (pn->dimensiones > 0)
                {
                    arm64_registrar_arreglo(pn->nombre, pn->tipo);
                }
            }
            fi->body = n->hijos[1];
        }
    }
    // Recorrer hijos
    for (size_t i = 0; i < n->numHijos; ++i)
        arm64_funciones_colectar(n->hijos[i]);
}

// Devuelve el conteo de funciones registradas
int arm64_funciones_count(void) { return __funcs_count; }
const Arm64FuncionInfo *arm64_funciones_get(int idx) { return (idx >= 0 && idx < __funcs_count) ? &__funcs[idx] : NULL; }

// Devuelve el tipo de retorno; para INT-like deja w1 con el valor; para DOUBLE deja d0
TipoDato arm64_emitir_llamada_funcion(AbstractExpresion *call_node, FILE *ftext)
{
    if (!call_node || !(call_node->node_type && strcmp(call_node->node_type, "FunctionCall") == 0))
        return INT;
    LlamadaFuncionNode *ln = (LlamadaFuncionNode *)call_node;
    Arm64FuncionInfo *fi = funcs_lookup(ln->nombre);
    if (!fi)
    {
        char line[128];
        snprintf(line, sizeof(line), "    bl fn_%s", ln->nombre ? ln->nombre : "unknown");
        emitln(ftext, line);
        emitln(ftext, "    mov w1, w0");
        return INT;
    }
    AbstractExpresion *args_list = (call_node->numHijos > 0) ? call_node->hijos[0] : NULL;
    int nargs = args_list ? (int)args_list->numHijos : 0;
    if (nargs > fi->param_count)
        nargs = fi->param_count;
    // Contadores separados para registros de propósito general (x/w) y de punto flotante (d)
    int gpr = 0;             // x0-x7 / w0-w7
    int fpr = 0;             // d0-d7
    int gpr_w1_assigned = 0; 
    int fpr_d0_assigned = 0; 
    int stack_bytes = 0;    
    int spill_kind[8];
    int spill_reg_index[8];
    for (int si = 0; si < 8; ++si)
    {
        spill_kind[si] = -1;
        spill_reg_index[si] = -1;
    }
    for (int i = 0; i < nargs; ++i)
    {
        AbstractExpresion *arg = args_list->hijos[i];
        TipoDato esperado = fi->param_types[i];
        if (esperado == STRING)
        {
            int need_save_x1 = gpr_w1_assigned;
            if (need_save_x1)
                emitln(ftext, "    sub sp, sp, #16\n    str x1, [sp]");
            // Pasar por referencia: enviar la dirección de la ranura del caller que contiene el puntero a string
            if (arg && arg->node_type && strcmp(arg->node_type, "Identificador") == 0)
            {
                IdentificadorExpresion *aid = (IdentificadorExpresion *)arg;
                VarEntry *av = vars_buscar(aid->nombre);
                if (av)
                {
                    // Si el identificador es un parámetro por referencia (is_ref), la ranura local contiene
                    if (av->is_ref)
                    {
                        char ld[128];
                        snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x%d, [x16]", av->offset, gpr);
                        emitln(ftext, ld);
                    }
                    else
                    {
                        // Dirección de la ranura local [x29 - offset]
                        char ld[96];
                        snprintf(ld, sizeof(ld), "    sub x%d, x29, #%d", gpr, av->offset);
                        emitln(ftext, ld);
                    }
                }
                else
                {
                    const GlobalInfo *gi = globals_lookup(aid->nombre);
                    if (gi && gi->tipo == STRING)
                    {
                        // Para globales, no tenemos una ranura local; crear un proxy en el stack del caller
                        emitln(ftext, "    sub sp, sp, #16");
                        char lg[192];
                        snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x1, [x16]", aid->nombre);
                        emitln(ftext, lg);

                        emitln(ftext, "    mov x0, x1");
                        emitln(ftext, "    bl strdup");
                        emitln(ftext, "    mov x1, x0");
                        emitln(ftext, "    str x1, [sp]");
                        char mvsp[64];
                        snprintf(mvsp, sizeof(mvsp), "    mov x%d, sp", gpr);
                        emitln(ftext, mvsp);
                        stack_bytes += 16;
                    }
                    else
                    {
                        // No identificado: construir puntero y colocar en tmp en stack
                        if (!emitir_eval_string_ptr(arg, ftext))
                            emitln(ftext, "    mov x1, #0");
                        emitln(ftext, "    mov x0, x1");
                        emitln(ftext, "    bl strdup");
                        emitln(ftext, "    mov x1, x0");
                        emitln(ftext, "    sub sp, sp, #16");
                        emitln(ftext, "    str x1, [sp]");
                        char mvsp2[64];
                        snprintf(mvsp2, sizeof(mvsp2), "    mov x%d, sp", gpr);
                        emitln(ftext, mvsp2);
                        stack_bytes += 16;
                    }
                }
            }
            else
            {
                // Expresión: evaluar puntero en x1, derramar a stack y pasar su dirección
                if (!emitir_eval_string_ptr(arg, ftext))
                    emitln(ftext, "    mov x1, #0");
                emitln(ftext, "    mov x0, x1");
                emitln(ftext, "    bl strdup");
                emitln(ftext, "    mov x1, x0");
                emitln(ftext, "    sub sp, sp, #16");
                emitln(ftext, "    str x1, [sp]");
                char mv[64];
                snprintf(mv, sizeof(mv), "    mov x%d, sp", gpr);
                emitln(ftext, mv);
                stack_bytes += 16;
            }
            if (gpr == 1)
                gpr_w1_assigned = 1;
            gpr++;
            if (need_save_x1)
                emitln(ftext, "    ldr x1, [sp]\n    add sp, sp, #16");
        }
        else if (esperado == ARRAY)
        {
            int need_save_x1 = gpr_w1_assigned;
            if (need_save_x1)
                emitln(ftext, "    sub sp, sp, #16\n    str x1, [sp]");
            // Pasar arreglos por referencia 
            if (arg && arg->node_type && strcmp(arg->node_type, "Identificador") == 0)
            {
                IdentificadorExpresion *aid = (IdentificadorExpresion *)arg;
                VarEntry *av = vars_buscar(aid->nombre);
                if (av)
                {
                    char ld[96];
                    snprintf(ld, sizeof(ld), "    sub x16, x29, #%d\n    ldr x1, [x16]", av->offset);
                    emitln(ftext, ld);
                }
                else
                {
                    const GlobalInfo *gi = globals_lookup(aid->nombre);
                    if (gi)
                    {
                        char lg[128];
                        snprintf(lg, sizeof(lg), "    ldr x16, =g_%s\n    ldr x1, [x16]", aid->nombre);
                        emitln(ftext, lg);
                    }
                    else
                    {
                        emitln(ftext, "    mov x1, #0");
                    }
                }
            }
            else
            {
                // Soportar expresiones que producen arreglos: llamadas a función y creaciones de arreglos
                const char *nt = arg && arg->node_type ? arg->node_type : "";
                if (strcmp(nt, "FunctionCall") == 0)
                {
                    TipoDato rty = arm64_emitir_llamada_funcion(arg, ftext);
                    if (rty == ARRAY)
                    {
                        emitln(ftext, "    mov x1, x0");
                    }
                    else
                    {
                        emitln(ftext, "    mov x1, #0");
                    }
                }
                else if (strcmp(nt, "ArrayCreation") == 0 || strcmp(nt, "ArrayInitializer") == 0)
                {
                    AbstractExpresion *lista = arg->numHijos > 1 ? arg->hijos[1] : NULL;
                    int dims = (int)(lista ? lista->numHijos : 0);
                    int bytes = ((dims * 4) + 15) & ~15;
                    if (bytes > 0)
                    {
                        char subb[64];
                        snprintf(subb, sizeof(subb), "    sub sp, sp, #%d", bytes);
                        emitln(ftext, subb);
                    }
                    for (int di = 0; di < dims; ++di)
                    {
                        TipoDato ty = emitir_eval_numerico(lista->hijos[di], ftext);
                        if (ty == DOUBLE)
                            emitln(ftext, "    fcvtzs w1, d0");
                        char st[64];
                        snprintf(st, sizeof(st), "    str w1, [sp, #%d]", di * 4);
                        emitln(ftext, st);
                    }
                    char mv0[64];
                    snprintf(mv0, sizeof(mv0), "    mov w0, #%d", dims);
                    emitln(ftext, mv0);
                    emitln(ftext, "    mov x1, sp");
                    emitln(ftext, "    bl new_array_flat");
                    if (bytes > 0)
                    {
                        char addb[64];
                        snprintf(addb, sizeof(addb), "    add sp, sp, #%d", bytes);
                        emitln(ftext, addb);
                    }
                    emitln(ftext, "    mov x1, x0");
                }
                else
                {
                    emitln(ftext, "    mov x1, #0");
                }
            }
            char mv[64];
            snprintf(mv, sizeof(mv), "    mov x%d, x1", gpr);
            emitln(ftext, mv);
            if (gpr == 1)
                gpr_w1_assigned = 1;
            gpr++;
            if (need_save_x1)
                emitln(ftext, "    ldr x1, [sp]\n    add sp, sp, #16");
            emitln(ftext, "    sub sp, sp, #16");
            {
                char stx[64];
                snprintf(stx, sizeof(stx), "    str x%d, [sp]", gpr - 1);
                emitln(ftext, stx);
            }
            spill_kind[i] = 2; 
            spill_reg_index[i] = gpr - 1;
        }
        else if (esperado == DOUBLE || esperado == FLOAT)
        {
            int need_save_d0 = fpr_d0_assigned; 
            if (need_save_d0)
                emitln(ftext, "    sub sp, sp, #16\n    str d0, [sp]");
            TipoDato ty = emitir_eval_numerico(arg, ftext);
            if (ty != DOUBLE)
                emitln(ftext, "    scvtf d0, w1");
            char mv[64];
            snprintf(mv, sizeof(mv), "    fmov d%d, d0", fpr);
            emitln(ftext, mv);
            if (fpr == 0)
                fpr_d0_assigned = 1;
            if (need_save_d0)
                emitln(ftext, "    ldr d0, [sp]\n    add sp, sp, #16");
            fpr++;
            emitln(ftext, "    sub sp, sp, #16");
            {
                char std[64];
                snprintf(std, sizeof(std), "    str d%d, [sp]", fpr - 1);
                emitln(ftext, std);
            }
            spill_kind[i] = 1; 
            spill_reg_index[i] = fpr - 1;
        }
        else
        {
            int need_save_x1 = gpr_w1_assigned;
            if (need_save_x1)
                emitln(ftext, "    sub sp, sp, #16\n    str x1, [sp]");
            TipoDato ty = emitir_eval_numerico(arg, ftext);
            if (ty == DOUBLE)
                emitln(ftext, "    fcvtzs w1, d0");
            char mv[64];
            snprintf(mv, sizeof(mv), "    mov w%d, w1", gpr);
            emitln(ftext, mv);
            if (gpr == 1)
                gpr_w1_assigned = 1;
            gpr++;
            if (need_save_x1)
                emitln(ftext, "    ldr x1, [sp]\n    add sp, sp, #16");
            emitln(ftext, "    sub sp, sp, #16");
            {
                char stw[64];
                snprintf(stw, sizeof(stw), "    str w%d, [sp]", gpr - 1);
                emitln(ftext, stw);
            }
            spill_kind[i] = 0; 
            spill_reg_index[i] = gpr - 1;
        }
    }
    // Restaurar spills en orden inverso
    for (int i = nargs - 1; i >= 0; --i)
    {
        if (spill_kind[i] == -1)
            continue; 
        if (spill_kind[i] == 1)
        {
            // double
            int r = spill_reg_index[i];
            char ldd[64];
            snprintf(ldd, sizeof(ldd), "    ldr d%d, [sp]", r);
            emitln(ftext, ldd);
            emitln(ftext, "    add sp, sp, #16");
        }
        else if (spill_kind[i] == 2)
        {
            // array/pointer in x{r}
            int r = spill_reg_index[i];
            char ldx[64];
            snprintf(ldx, sizeof(ldx), "    ldr x%d, [sp]", r);
            emitln(ftext, ldx);
            emitln(ftext, "    add sp, sp, #16");
        }
        else
        {
            // int-like in w{r}
            int r = spill_reg_index[i];
            char ldw[64];
            snprintf(ldw, sizeof(ldw), "    ldr w%d, [sp]", r);
            emitln(ftext, ldw);
            emitln(ftext, "    add sp, sp, #16");
        }
    }
    // Reasignar registros para parámetros STRING que usaron proxies en el stack,
    if (stack_bytes > 0)
    {
        int total_proxies = stack_bytes / 16; 
        if (total_proxies > 0)
        {
            int proxy_k = 0; // índice de proxy en orden de creación
            int gpr2 = 0;    // posición de registro GPR para cada argumento
            for (int i = 0; i < nargs; ++i)
            {
                TipoDato esperado_i = fi->param_types[i];
                if (esperado_i == DOUBLE || esperado_i == FLOAT)
                {
                    // argumentos FP usan d0..d7, no afectan gpr2
                    continue;
                }
                // Sólo interesa STRING: recomputar si usó proxy
                if (esperado_i == STRING)
                {
                    AbstractExpresion *argi = args_list->hijos[i];
                    int used_proxy = 0;
                    if (argi && argi->node_type && strcmp(argi->node_type, "Identificador") == 0)
                    {
                        IdentificadorExpresion *aid2 = (IdentificadorExpresion *)argi;
                        VarEntry *av2 = vars_buscar(aid2->nombre);
                        if (av2)
                        {
                            used_proxy = 0; 
                        }
                        else
                        {
                            const GlobalInfo *gi2 = globals_lookup(aid2->nombre);
                            if (gi2 && gi2->tipo == STRING)
                                used_proxy = 1;
                        }
                    }
                    else
                    {
                        // literales y expresiones generan proxy
                        used_proxy = 1;
                    }
                    if (used_proxy)
                    {
                        int offset = (total_proxies - 1 - proxy_k) * 16;
                        char addx[96];
                        snprintf(addx, sizeof(addx), "    add x%d, sp, #%d", gpr2, offset);
                        emitln(ftext, addx);
                        proxy_k++;
                    }
                }
                // avanzar contador GPR para todos los argumentos que consumen x0..x7
                if (esperado_i != DOUBLE && esperado_i != FLOAT)
                {
                    gpr2++;
                }
            }
        }
    }
    {
        char line[128];
        snprintf(line, sizeof(line), "    bl fn_%s", fi->name);
        emitln(ftext, line);
    }
    // Liberar espacio temporal reservado para pasar argumentos por referencia
    if (stack_bytes > 0)
    {
        char addsp[64];
        snprintf(addsp, sizeof(addsp), "    add sp, sp, #%d", stack_bytes);
        emitln(ftext, addsp);
    }
    if (fi->ret == DOUBLE || fi->ret == FLOAT)
    {
        return DOUBLE;
    }
    else if (fi->ret == STRING)
    {
        // Propagar puntero de retorno en x0 también a x1 para consumo uniforme aguas arriba
        emitln(ftext, "    mov x1, x0");
        return STRING;
    }
    else if (fi->ret == ARRAY)
    {
        // Mantener puntero en x0; opcionalmente reflejar en x1 para consumidores puntuales
        emitln(ftext, "    mov x1, x0");
        return ARRAY;
    }
    else
    {
        emitln(ftext, "    mov w1, w0");
        return INT;
    }
}
