#!/bin/bash

set -euo pipefail

ASM_FILE="./arm/javalang.s"
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
aarch64-linux-gnu-gcc -nostdlib -static -o "$BIN_FILE" "$OBJ_FILE"

echo "[3/3] Ejecutando en qemu-aarch64"
qemu-aarch64 "$BIN_FILE"