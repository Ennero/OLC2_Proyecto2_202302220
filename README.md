# OLC2_Proyecto2_202302220

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

### 6. Instalar Flex y Bison (requeridos por el Makefile)
```bash
sudo apt install flex bison -y
```

### 7. Instalar Graphviz
```bash
sudo apt update
sudo apt install graphviz -y
```

### 8. Instalar QEMU y Cross-Compiler ARM (aarch64)

Para ensamblar y ejecutar el código ARM (aarch64) que genera tu compilador, necesitas el compilador cruzado de GCC, las binutils (ensamblador) y el emulador QEMU.

```bash
sudo apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu libc6-dev-arm64-cross qemu-user -y
```

### 9. Verificar instalaciones
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

### 10. Configurar el proyecto en VS Code
- Descarga e instala [VS Code](https://code.visualstudio.com).
- Instala la extensión **C/C++** de Microsoft (busca "C/C++" en la pestaña de Extensiones).

### 11. Crear el directorio del proyecto (opcional)
Si todavía no tienes el proyecto en tu máquina, clónalo o crea un directorio y navega a él. Ejemplo:
```bash
mkdir ~/Escritorio/OLC2_Proyecto2_202302220
cd ~/Escritorio/OLC2_Proyecto2_202302220
```

### 12. Configurar VS Code para IntelliSense
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

### 13. Compilar el Programa (GUI)
- Abre una terminal en VS Code o en el directorio del proyecto.
- Asegúrate de tener tu Makefile en el directorio raíz.
- Compila el proyecto (esto creará el ejecutable en `./build/javalang`):
```bash
make
```

### 14. Ejecutar el Programa (GUI)

- Asegúrate de tener tu script compile.sh con el contenido #!/bin/bash ./build/javalang y de que tenga permisos de ejecución (chmod +x compile.sh).
- Ejecuta el programa:
```bash
./compile.sh
```
- Esto abrirá la interfaz gráfica de tu compilador.

## Ejecutar el Código ARM Generado

Sigue estos pasos después de haber usado tu programa (GUI) para generar el código ensamblador ARM.

### 15. Generar el código ARM

- Usa tu programa (la GUI que ejecutaste en el paso 13) para analizar tu código fuente.

- Asegúrate de que el programa genere el archivo de ensamblador en la ruta ./arm/salida.s, ya que el script de ejecución lo buscará allí por defecto.

### 16. Ensamblar y ejecutar con el script incluido

Este repositorio ya incluye el script `./ensamblar.sh`, que realiza el ensamblado, enlace y ejecución bajo QEMU.

- Concede permisos de ejecución si es necesario:

```bash
chmod +x ensamblar.sh
```

- Ejecuta el script (usa `./arm/salida.s` por defecto):

```bash
./ensamblar.sh
```

- También puedes pasarle una ruta específica al `.s` si generaste a otro archivo:

```bash
./ensamblar.sh ruta/a/tu_archivo.s
```

---

## Uso por línea de comandos (CLI)

Además de la GUI, el ejecutable soporta un modo CLI útil para automatizar pruebas:

- Interpretar y ejecutar directamente un archivo `.usl`:

```bash
./build/javalang --run test/proyecto1/prueba_main.usl
```

- Generar ensamblador AArch64 a `arm/salida.s` y luego ensamblar/ejecutar:

```bash
./build/javalang --arm test/proyecto1/examen_final.usl
./ensamblar.sh            # o ./ensamblar.sh arm/salida.s
```

Sugerencia: Puedes exportar `USE_STATIC=1` para intentar enlace estático (útil si QEMU no encuentra la libc de aarch64):

```bash
USE_STATIC=1 ./ensamblar.sh
```

---

## Notas
- Aparecerán advertencias sobre ```GTimeVal``` (obsoleto) al compilar la GUI, pero son seguras de ignorar.

- Este manual asume que tu proyecto tiene un ```Makefile``` y un ```compile.sh``` en la raíz.

- También se asume una estructura de directorio ```src/``` que contiene el código fuente de tu compilador, incluyendo los archivos de ```flex``` (```src/entriesTools/lexer.l```), ```bison``` (```src/entriesTools/parser.y```), y el archivo de utilidad C para ARM (```src/utils/java_num_format.c```).

- Para exportar el AST desde la GUI, se usa Graphviz (`dot`) y los resultados se guardan en la carpeta `ast-graph/` como `ast.svg` y `ast.pdf`.

- El código ensamblador ARM64 se genera por la GUI y por CLI en la ruta `arm/salida.s`.
