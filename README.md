<div align="center">

# ⚙️ Javalang Compiler — Java to ARM64 Assembly Compiler & IDE

**Compilador completo para un subconjunto del lenguaje Java orientado a arquitectura ARM64 (AArch64) con interfaz gráfica en GTK3**

[![C Language](https://img.shields.io/badge/C-17-A8B9CC?style=for-the-badge&logo=c&logoColor=black)](https://en.wikipedia.org/wiki/C_(programming_language))
[![Flex & Bison](https://img.shields.io/badge/Flex_%26_Bison-LALR(1)-blue?style=for-the-badge)](https://www.gnu.org/software/bison/)
[![ARM64](https://img.shields.io/badge/Target-ARM64%20(AArch64)-FF6B6B?style=for-the-badge&logo=arm&logoColor=white)](https://developer.arm.com/)
[![GTK3](https://img.shields.io/badge/GUI-GTK3%20%2B%20GtkSourceView-4A90E2?style=for-the-badge&logo=gnome&logoColor=white)](https://www.gtk.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![University](https://img.shields.io/badge/USAC-Compiladores_2-003366?style=for-the-badge)](https://ingenieria.usac.edu.gt/)

</div>

---

## 📌 Descripción General

**Javalang Compiler** es un compilador e IDE de escritorio desarrollado en **C**, diseñado para procesar y traducir código fuente a instrucciones de ensamblador nativo **ARM64 (AArch64)**. El proyecto abarca todas las fases clásicas de la ingeniería de compiladores:

1. **Análisis Léxico:** Generador de analizadores léxicos con **GNU Flex**.
2. **Análisis Sintáctico:** Gramática formal LALR(1) procesada con **GNU Bison**.
3. **Árbol de Sintaxis Abstracta (AST):** Construcción y visualización gráfica del AST exportable a SVG y PDF mediante **Graphviz**.
4. **Análisis Semántico & Tablas de Símbolos:** Tipado estático, comprobación de ámbitos, resolución de identificadores y control de errores semánticos.
5. **Generador de Código ARM64:** Emisión de código ensamblador AArch64 con gestión de registros, paso de parámetros conforme al estándar ABI de ARM y soporte para ejecución cruzada mediante emulación con **QEMU**.
6. **IDE Gráfico (GTK3):** Interfaz completa con pestañas, resaltado de sintaxis con `GtkSourceView`, consola de salida, visualizador de errores y renderizado de AST.

Desarrollado en el curso **Organización de Lenguajes y Compiladores 2 (OLC2)** en la Universidad de San Carlos de Guatemala.

---

## 🏗️ Pipeline de Compilación

```mermaid
flowchart LR
    Source["Código Fuente (.usl)"] --> Lexer["Flex (Lexer)"]
    Lexer --> Parser["Bison (Parser LALR)"]
    Parser --> AST["Árbol Sintáctico (AST)"]
    AST --> Semantic["Análisis Semántico"]
    Semantic --> Codegen["Generador ARM64 (.s)"]
    Codegen --> Toolchain["Cross-Compiler (aarch64-linux-gnu-as)"]
    Toolchain --> Exec["Binario ELF ARM64"]
    Exec --> QEMU["Emulador QEMU User"]
```

---

## 📦 Estructura del Repositorio

```
OLC2_Proyecto2_202302220/
├── src/                    # Código fuente del compilador en C
│   ├── entriesTools/       # Definiciones léxicas (lexer.l) y sintácticas (parser.y)
│   ├── ast/                # Nodos y constructores del AST
│   ├── semantic/           # Tabla de símbolos y chequeo semántico
│   ├── arm_gen/            # Generación de instrucciones AArch64
│   └── gui/                # Ventana principal e integración con GTK3
├── arm/                    # Código ensamblador generado (ej. salida.s)
├── ast-graph/              # Diagramas y reportes gráficos de Graphviz
├── test/                   # Casos de prueba (.usl)
├── Makefile                # Automatización de compilación con GCC, Flex y Bison
├── compile.sh              # Script rápido de arranque
├── ensamblar.sh            # Script para ensamblar código ARM y ejecutar con QEMU
├── LICENSE                 # Licencia MIT
└── README.md               # Este documento
```

---

## ⚙️ Guía de Instalación y Dependencias

### 1. Dependencias Básicas del Sistema
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential pkg-config git flex bison graphviz -y
```

### 2. Entorno Gráfico GTK3 y GtkSourceView
```bash
sudo apt install libgtk-3-dev libgtksourceview-3.0-dev libatk1.0-dev libpango1.0-dev libcairo2-dev libgdk-pixbuf2.0-dev -y
```

*Si `pkg-config` no encuentra `gtksourceview-3.0`:*
```bash
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/:$PKG_CONFIG_PATH
```

### 3. Toolchain ARM64 (Cross-Compiler y QEMU)
Para ensamblar y ejecutar el código ARM generado en arquitecturas x86_64:
```bash
sudo apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu libc6-dev-arm64-cross qemu-user -y
```

---

## 🚀 Compilación y Ejecución

### Modo Interfaz Gráfica (GUI)

1. **Compilar el proyecto:**
   ```bash
   make
   ```
   *Genera el ejecutable en `./build/javalang`.*

2. **Ejecutar la interfaz:**
   ```bash
   ./compile.sh
   ```

### Modo Línea de Comandos (CLI)

Ideal para pruebas automatizadas e integración continua:

- **Interpretar y ejecutar directamente un archivo:**
  ```bash
  ./build/javalang --run test/proyecto1/prueba_main.usl
  ```

- **Generar código ensamblador ARM64:**
  ```bash
  ./build/javalang --arm test/proyecto1/examen_final.usl
  ```

- **Ensamblar y ejecutar bajo QEMU:**
  ```bash
  ./ensamblar.sh
  # O indicando un archivo específico:
  ./ensamblar.sh arm/salida.s
  ```

---

## 📄 Licencia

Este proyecto está liberado bajo la Licencia **MIT**. Consulta el archivo [LICENSE](LICENSE) para más información.

---

## 👨‍💻 Autor

- **Enner Mendizabal** - [@Ennero](https://github.com/Ennero)  
- *Ingeniería en Ciencias y Sistemas, Universidad de San Carlos de Guatemala.*
