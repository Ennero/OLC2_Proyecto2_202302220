# ===================================================================
# Makefile para el Intérprete de JavaLang
# ===================================================================

# --- Variables de Directorios y Programas ---
SRC     := src
BUILD   := build
ENTRIES := src/entriesTools
CC      := gcc
BISON   := bison
FLEX    := flex

# --- Banderas de Compilación y Enlazado ---

# Banderas para GTK3 y GtkSourceView
GTK_CFLAGS := $(shell pkg-config --cflags gtk+-3.0 gtksourceview-3.0)
GTK_LIBS   := $(shell pkg-config --libs gtk+-3.0 gtksourceview-3.0) -lm

# Rutas de inclusión:
# -I$(SRC)   -> Permite includes como #include "context/context.h"
# -I$(BUILD) -> Permite includes como #include "parser.tab.h"
INCLUDE_PATHS := -I$(SRC) -I$(BUILD)

# Banderas del compilador de C
CFLAGS  := $(INCLUDE_PATHS) -g -Wall -Wextra $(GTK_CFLAGS)

# --- Comandos ---
RM      := rm -rf
MKDIR   := mkdir -p

.DEFAULT_GOAL := all

# --- Definición de Archivos ---
SRC_FILES := $(shell find $(SRC) -name '*.c')

# Archivos generados que irán a la carpeta build/
BISON_C := $(BUILD)/parser.tab.c
BISON_H := $(BUILD)/parser.tab.h
LEX_C   := $(BUILD)/lex.yy.c

# Archivos objeto
OBJ_SRC := $(patsubst $(SRC)/%.c,$(BUILD)/%.o,$(SRC_FILES))
OBJ_GEN := $(BUILD)/parser.tab.o $(BUILD)/lex.yy.o
OBJ_ALL := $(OBJ_SRC) $(OBJ_GEN)

# Nombre del ejecutable
EXECUTABLE := $(BUILD)/javalang

# --- Reglas de Construcción ---

# Regla principal
all: $(EXECUTABLE)

# Crear el directorio de compilación
$(BUILD):
	$(MKDIR) $(BUILD)

# Generar parser
$(BISON_C) $(BISON_H): $(ENTRIES)/parser.y | $(BUILD)
	@echo "Generando Parser..."
	$(BISON) -d -v --locations -o $(BISON_C) $<

# Generar lexer
$(LEX_C): $(ENTRIES)/lexer.l $(BISON_H) | $(BUILD)
	@echo "Generando Lexer..."
	$(FLEX) -o $@ $<

# Añadimos $(BISON_H) como dependencia para asegurar que se genere primero.
$(BUILD)/%.o: $(SRC)/%.c $(BISON_H)
	@echo "Compilando $<..."
	@$(MKDIR) -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# Compilar archivos .c generados
$(BUILD)/parser.tab.o: $(BISON_C) $(BISON_H)
	@echo "Compilando Parser..."
	$(CC) $(CFLAGS) -c $(BISON_C) -o $@

$(BUILD)/lex.yy.o: $(LEX_C)
	@echo "Compilando Lexer..."
	$(CC) $(CFLAGS) -c $(LEX_C) -o $@

# Enlazar todo para crear el ejecutable
$(EXECUTABLE): $(OBJ_ALL)
	@echo "Enlazando ejecutable..."
	$(CC) $^ -o $@ $(GTK_LIBS)

# Regla de limpieza
clean:
	@echo "Limpiando archivos de compilación..."
	@$(RM) $(BUILD)
	@echo "Limpieza completa."

.PHONY: all clean