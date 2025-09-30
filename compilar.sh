#!/bin/bash
echo "Compilando el programa en ensamblador..."
aarch64-linux-gnu-as -o programa.o programa.s

echo "Enlazando el programa..."
aarch64-linux-gnu-ld -o programa_ensamblado programa.o

echo "=============== Ejecutando el programa ensamblado ==============="
qemu-aarch64 ./programa_ensamblado
echo "====================== Ejecución finalizada ====================="