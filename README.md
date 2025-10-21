# OLC2_Proyecto1_202302220

# Instrucciones de configuración y ejecución del programa

## Instalación de dependencias

Para correr el programa principal (el compilador) y ejecutar el código ARM generado, son necesarias las siguientes instalaciones:

### 1. Actualizar el sistema
```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Instalar dependencias básicas
```bash
sudo apt install build-essential pkg-config git -y
```

### 3. Instalar GTK3 y dependencias
```bash
sudo apt install libgtk-3-dev -y
```

### 4. Instalar GtkSourceView
```bash
sudo apt install libgtksourceview-3.0-dev -y
```
Si `pkg-config` no encuentra `gtksourceview-3.0`, verifica la ubicación del archivo `.pc` con:
```bash
find /usr/lib -name "gtksourceview-3.0.pc"
```
Si está en `/usr/lib/x86_64-linux-gnu/pkgconfig/`, añade esta ruta a `PKG_CONFIG_PATH`:
```bash
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/:\$PKG_CONFIG_PATH
```
Y agrégalo permanentemente a `~/.bashrc`:
```bash
echo 'export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/:\$PKG_CONFIG_PATH' >> ~/.bashrc
source ~/.bashrc
```

### 5. Instalar dependencias adicionales de GTK3
```bash
sudo apt install libatk1.0-dev libpango1.0-dev libcairo2-dev libgdk-pixbuf2.0-dev -y
```


### 6. Instalar Graphviz
```bash
sudo apt update
sudo apt install graphviz -y
```

### 7. Instalar QEMU y Coss-Compiler ARM (aarch64)

Para ensamblar y ejecutar el código ARM (aarch64) que genera tu compilador, necesitas el compilador cruzado de GCC, las binutils (ensamblador) y el emulador QEMU.

```bash
sudo apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu libc6-dev-arm64-cross qemu-user -y
```


### 8. Verificar instalaciones
Verifica GTK3:
```bash
pkg-config --modversion gtk+-3.0
```
Verifica GtkSourceView:
```bash
pkg-config --modversion gtksourceview-3.0
```

Verifica Graphviz:
```bash
dot -V
```

Verifica el Cross-Compiler de ARM:
```bash
aarch64-linux-gnu-gcc --version
aarch64-linux-gnu-as --version
```

Verifica QEMU:
```bash
qemu-aarch64 --version
```


---

## Configuraciones adicionales

### 9. Configurar el proyecto en VS Code
- Descarga e instala [VS Code](https://code.visualstudio.com).
- Instala la extensión **C/C++** de Microsoft (busca "C/C++" en la pestaña de Extensiones).

### 10. Crear el directorio del proyecto
Crea un directorio (por ejemplo, `OLC2_Proyecto1_202302220`) y navega a él:
```bash
mkdir ~/Escritorio/OLC2_Proyecto1_202302220
cd ~/Escritorio/OLC2_Proyecto1_202302220
```

### 11. Configurar VS Code para IntelliSense
- Abre el proyecto en VS Code (**File > Open Folder** y selecciona el directorio).
- Crea o edita el archivo de configuración de IntelliSense: Presiona `Ctrl+Shift+P`, escribe `C/C++: Edit Configurations (JSON)` y selecciona.
- Asegúrate de que tu archivo .vscode/c_cpp_properties.json incluya todas las rutas. El siguiente JSON está basado en el que proporcionaste y es correcto:
```json
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/**",
                "/usr/include/gtk-3.0",
                "/usr/include/pango-1.0",
                "/usr/include/glib-2.0",
                "/usr/lib/x86_64-linux-gnu/glib-2.0/include",
                "/usr/include/harfbuzz",
                "/usr/include/freetype2",
                "/usr/include/libpng16",
                "/usr/include/libmount",
                "/usr/include/blkid",
                "/usr/include/fribidi",
                "/usr/include/cairo",
                "/usr/include/pixman-1",
                "/usr/include/gdk-pixbuf-2.0",
                "/usr/include/x86_64-linux-gnu",
                "/usr/include/webp",
                "/usr/include/gio-unix-2.0",
                "/usr/include/atk-1.0",
                "/usr/include/gtksourceview-3.0"
            ],
            "defines": [],
            "cStandard": "c17",
            "cppStandard": "gnu++17",
            "intelliSenseMode": "linux-gcc-x64"
        }
    ],
    "version": 4
}
```

- Guarda el archivo (`c_cpp_properties.json`).
- Recarga VS Code (`Ctrl+Shift+P` > **"Developer: Reload Window"**).

---

## Compilar y Ejecutar el Compilador (GUI)

### 12. Compilar el Programa (GUI)
- Abre una terminal en VS Code o en el directorio del proyecto.
- Asegúrate de tener tu Makefile en el directorio raíz.
- Compila el proyecto (esto creará el ejecutable en `./build/javalang`):
```bash
make
```

### 13. Ejecutar el Programa (GUI)

- Asegúrate de tener tu script compile.sh con el contenido #!/bin/bash ./build/javalang y de que tenga permisos de ejecución (chmod +x compile.sh).
- Ejecuta el programa:
```bash
./compile.sh
```
- Esto abrirá la interfaz gráfica de tu compilador.

 ## Ejecutar el Código ARM Generado

Sigue estos pasos después de haber usado tu programa (GUI) para generar el código ensamblador ARM.

### 14. Generar el código ARM

- Usa tu programa (la GUI que ejecutaste en el paso 13) para analizar tu código fuente.

- Asegúrate de que el programa genere el archivo de ensamblador en la ruta ./arm/salida.s, ya que el script de ejecución lo buscará allí por defecto.

### 15. Crear el script de ejecución ARM

- En el directorio raíz de tu proyecto, crea un nuevo archivo llamado run_arm.sh.

- Pega el siguiente contenido en el archivo:

``` bash
#!/bin/bash

set -euo pipefail

# Por defecto arm/salida.s; permite override por $1
ASM_FILE="${1:-./arm/salida.s}"
OBJ_FILE="./arm/javalang.o"
FMT_OBJ_FILE="./arm/java_num_format.o"
BIN_FILE="./arm/javalang"

if [ ! -f "$ASM_FILE" ]; then
    echo "No se encontró $ASM_FILE. Ejecuta el compilador con --arm primero." >&2
    exit 1
fi

mkdir -p ./arm

echo "[1/3] Ensamblando $ASM_FILE"
aarch64-linux-gnu-as -o "$OBJ_FILE" "$ASM_FILE"

echo "[2/3] Compilando utilidades auxiliares (java_num_format) para aarch64"
# Compilar helper de formateo numérico para AArch64
aarch64-linux-gnu-gcc -c -O2 -o "$FMT_OBJ_FILE" ./src/utils/java_num_format.c

echo "[2/3] Enlazando a binario"
# Enlazamos contra la libc de aarch64 para tener printf y libm (fmod) disponibles
if [ "${USE_STATIC:-0}" = "1" ]; then
    echo "[INFO] Enlazando de forma estática (-static)"
    aarch64-linux-gnu-gcc -static -no-pie -o "$BIN_FILE" "$OBJ_FILE" "$FMT_OBJ_FILE" -lm || {
        echo "[WARN] Enlace estático falló, reintentando dinámico..." >&2
        aarch64-linux-gnu-gcc -no-pie -o "$BIN_FILE" "$OBJ_FILE" "$FMT_OBJ_FILE" -lm
    }
else
    aarch64-linux-gnu-gcc -no-pie -o "$BIN_FILE" "$OBJ_FILE" "$FMT_OBJ_FILE" -lm
fi

echo "[3/3] Ejecutando en qemu-aarch64"
# Si existe el sysroot de aarch64 en el sistema, usarlo para la libc y el loader
if [ -d "/usr/aarch64-linux-gnu" ]; then
    qemu-aarch64 -L /usr/aarch64-linux-gnu "$BIN_FILE"
else
    echo "[WARN] No se encontró /usr/aarch64-linux-gnu. Intentando ejecutar sin sysroot..." >&2
    echo "       Si falla con 'ld-linux-aarch64.so.1 not found', instala libc cruzada o usa -static." >&2
    qemu-aarch64 "$BIN_FILE"
fi
```

### 16. Ensamblar y Ejecutar el código ARM

- Otorga permisos de ejecución al nuevo script:

```bash
chmod +x run_arm.sh
```

- Ejecuta el script. Esto ensamblará, enlazará y ejecutará tu código ARM usando QEMU:

```bash
./run_arm.sh
```

---

## Notas
- Aparecerán advertencias sobre ```GTimeVal``` (obsoleto) al compilar la GUI, pero son seguras de ignorar.

- Este manual asume que tu proyecto tiene un ```Makefile``` y un ```compile.sh``` en la raíz.

- También se asume una estructura de directorio ```src/``` que contiene el código fuente de tu compilador, incluyendo los archivos de ```flex``` (```src/entries/lexer.l```), ```bison```(```src/entries/parser.y```) y el archivo de utilidad C para ARM (```src/utils/java_num_format.c```).
