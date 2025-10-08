#!/bin/bash

# Script para automatizar la compilación y ejecución de 'arm/javalang.s'

# set -e: Detiene el script si un comando falla.
# set -u: Trata las variables no definidas como un error.
set -eu

SOURCE_DIR="arm"
SOURCE_FILE="${SOURCE_DIR}/javalang.s"

# Los archivos de salida se crearán en el mismo directorio.
OBJECT_FILE="${SOURCE_DIR}/javalang.o"
EXECUTABLE_FILE="${SOURCE_DIR}/javalang"

echo "Iniciando proceso para '$SOURCE_FILE'..."

# --- 2. Validar que el archivo de entrada existe ---
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: No se encontró el archivo en la ruta esperada: '$SOURCE_FILE'"
    exit 1
fi

# --- 3. Ensamblar, Enlazar y Limpiar ---
echo "   [1/3] Ensamblando..."
aarch64-linux-gnu-as -o "$OBJECT_FILE" "$SOURCE_FILE"

echo "   [2/3] Enlazando estáticamente..."
aarch64-linux-gnu-gcc -static -o "$EXECUTABLE_FILE" "$OBJECT_FILE"

echo "   Limpiando archivo intermedio..."
rm "$OBJECT_FILE"

# --- 4. Ejecutar con QEMU ---
echo "[3/3] Ejecutando '$EXECUTABLE_FILE' con QEMU..."
echo "-------------------- INICIO SALIDA --------------------"
qemu-aarch64 "$EXECUTABLE_FILE"
echo "--------------------- FIN SALIDA ----------------------"

echo "Proceso completado. El ejecutable es: '$EXECUTABLE_FILE'"