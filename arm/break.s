// Nombre del archivo: break_test.s
// Para compilar y ejecutar:
// as -o break_test.o break_test.s
// gcc -o break_test break_test.o
// ./break_test

.data

// --- Cadenas de texto para los mensajes ---
title_str:              .asciz "--- Prueba de 'break' ---\n"
test1_header_str:       .asciz "Prueba 1: Saliendo de un 'for' en i=3\n"
test1_break_msg_str:    .asciz "Break activado.\n"
test2_header_str:       .asciz "Prueba 2: Saliendo de un 'while' en j=7\n"
test3_header_str:       .asciz "Prueba 3: Saliendo de un 'case' con break\n"
case1_str:              .asciz "Lunes\n"
case2_str:              .asciz "Martes\n"
case3_str:              .asciz "Miércoles\n"
default_str:            .asciz "Otro día\n"
test4_header_str:       .asciz "Prueba 4: 'break' en bucle anidado\n"
outer_loop_str:         .asciz "Outer: %d\n"
inner_loop_str:         .asciz "  Inner: %d\n"
footer_str:             .asciz "--- Fin de la prueba de 'break' ---\n"
separator_str:          .asciz "----------------------------------------\n"
int_format:             .asciz "%d\n"

.text
.global main

main:
    // Prólogo de la función
    stp x29, x30, [sp, -16]!
    mov x29, sp

    // --- Prueba de 'break' ---
    ldr x0, =title_str
    bl printf

    // --- Prueba 1: 'break' en un ciclo 'for' ---
    ldr x0, =test1_header_str
    bl printf
    mov w19, #0                 // int i = 0;

for_loop_1_start:
    cmp w19, #10                // i < 10
    b.ge for_loop_1_end         // Si i >= 10, salir del bucle

    cmp w19, #3                 // if (i == 3)
    b.eq for_loop_1_break       // Si i == 3, saltar al 'break'

    // System.out.println(i);
    ldr x0, =int_format
    mov w1, w19
    bl printf

    add w19, w19, #1            // i = i + 1
    b for_loop_1_start

for_loop_1_break:
    ldr x0, =test1_break_msg_str
    bl printf
    // El 'break' se implementa simplemente continuando después del bucle

for_loop_1_end:
    ldr x0, =separator_str
    bl printf

    // --- Prueba 2: 'break' en un ciclo 'while' ---
    ldr x0, =test2_header_str
    bl printf
    mov w20, #10                // int j = 10;

while_loop_2_start:
    cmp w20, #0                 // while (j > 0)
    b.le while_loop_2_end       // Si j <= 0, salir

    cmp w20, #7                 // if (j == 7)
    b.eq while_loop_2_break     // Si j == 7, activar 'break'

    sub w20, w20, #1            // j = j - 1;
    b while_loop_2_start

while_loop_2_break:
    // El 'break' salta aquí, manteniendo el valor actual de j (7)

while_loop_2_end:
    // System.out.println(j);
    ldr x0, =int_format
    mov w1, w20
    bl printf
    ldr x0, =separator_str
    bl printf

    // --- Prueba 3: 'break' en un 'switch' ---
    ldr x0, =test3_header_str
    bl printf
    mov w21, #2                 // int dia = 2;

    cmp w21, #1                 // case 1
    b.eq case_1
    cmp w21, #2                 // case 2
    b.eq case_2
    cmp w21, #3                 // case 3
    b.eq case_3
    b default_case              // default

case_1:
    ldr x0, =case1_str
    bl printf
    b switch_end                // break;
case_2:
    ldr x0, =case2_str
    bl printf
    b switch_end                // break;
case_3:
    ldr x0, =case3_str
    bl printf
    b switch_end                // break;
default_case:
    ldr x0, =default_str
    bl printf
    // No necesita 'break' al ser el último

switch_end:
    ldr x0, =separator_str
    bl printf

    // --- Prueba 4: 'break' en bucles anidados ---
    ldr x0, =test4_header_str
    bl printf
    mov w22, #0                 // int outer = 0;

outer_loop_start:
    cmp w22, #3                 // outer < 3
    b.ge outer_loop_end

    // System.out.println("Outer: " + outer);
    ldr x0, =outer_loop_str
    mov w1, w22
    bl printf

    mov w23, #0                 // int inner = 0;
inner_loop_start:
    cmp w23, #5                 // inner < 5
    b.ge after_inner_loop       // Si inner >= 5, termina el bucle interno

    cmp w23, #2                 // if (inner == 2)
    b.eq after_inner_loop       // break; (sale solo del bucle interno)

    // System.out.println("  Inner: " + inner);
    ldr x0, =inner_loop_str
    mov w1, w23
    bl printf

    add w23, w23, #1            // inner = inner + 1
    b inner_loop_start

after_inner_loop:
    add w22, w22, #1            // outer = outer + 1
    b outer_loop_start

outer_loop_end:
    ldr x0, =footer_str
    bl printf

    // Epílogo de la función
    mov w0, #0                  // Código de retorno 0 (éxito)
    ldp x29, x30, [sp], 16
    ret
