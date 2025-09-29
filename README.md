# OLC2_Proyecto1_202302220

# Instrucciones de configuración y ejecución del programa

## Instalación de dependencias

Para correr el programa son necesarias las siguientes instalaciones:

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

### 7. Verificar instalaciones
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
---

## Configuraciones adicionales

### 8. Configurar el proyecto en VS Code
- Descarga e instala [VS Code](https://code.visualstudio.com).
- Instala la extensión **C/C++** de Microsoft (busca "C/C++" en la pestaña de Extensiones).

### 9. Crear el directorio del proyecto
Crea un directorio (por ejemplo, `OLC2_Proyecto1_202302220`) y navega a él:
```bash
mkdir ~/Escritorio/OLC2_Proyecto1_202302220
cd ~/Escritorio/OLC2_Proyecto1_202302220
```

### 10. Configurar VS Code para IntelliSense
- Abre el proyecto en VS Code (**File > Open Folder** y selecciona el directorio).
- Crea o edita el archivo de configuración de IntelliSense: Presiona `Ctrl+Shift+P`, escribe `C/C++: Edit Configurations (JSON)` y selecciona.
- Usa el siguiente contenido:
```json
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "\${workspaceFolder}/**",
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

## Compilar y ejecutar

### 11. Compilar y ejecutar
- Abre una terminal en VS Code o en el directorio del proyecto.
- Compila el proyecto:
```bash
make
```
- Ejecuta el programa:
```bash
./javalang
```

---

## Notas
- Aparecerán advertencias sobre `GTimeVal` (obsoleto), pero son seguras de ignorar.
- Asegúrate de transferir los archivos `main.c`, `gui.c` y `Makefile` al directorio del proyecto.
