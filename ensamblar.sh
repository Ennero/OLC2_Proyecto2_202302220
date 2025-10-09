#!/bin/bash

set -euo pipefail

# Por defecto arm/salida.s; permite override por $1
ASM_FILE="${1:-./arm/salida.s}"
OBJ_FILE="./arm/javalang.o"
BIN_FILE="./arm/javalang"

if [ ! -f "$ASM_FILE" ]; then
	echo "No se encontró $ASM_FILE. Ejecuta el compilador con --arm primero." >&2
	exit 1
fi

mkdir -p ./arm

echo "[1/3] Ensamblando $ASM_FILE"
aarch64-linux-gnu-as -o "$OBJ_FILE" "$ASM_FILE"

echo "[2/3] Enlazando a binario"
# Enlazamos contra la libc de aarch64 para tener printf y libm (fmod) disponibles
aarch64-linux-gnu-gcc -no-pie -o "$BIN_FILE" "$OBJ_FILE" -lm

echo "[3/3] Ejecutando en qemu-aarch64"
# Si existe el sysroot de aarch64 en el sistema, usarlo para la libc y el loader
if [ -d "/usr/aarch64-linux-gnu" ]; then
	qemu-aarch64 -L /usr/aarch64-linux-gnu "$BIN_FILE"
else
	echo "[WARN] No se encontró /usr/aarch64-linux-gnu. Intentando ejecutar sin sysroot..." >&2
	echo "       Si falla con 'ld-linux-aarch64.so.1 not found', instala libc cruzada o usa -static." >&2
	qemu-aarch64 "$BIN_FILE"
fi