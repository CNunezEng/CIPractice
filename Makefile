# ═══════════════════════════════════════════════════════════════════════════
# Parentheses Test Makefile
# ═══════════════════════════════════════════════════════════════════════════
# Builds and runs the Parentheses Validation solution with Catch2 testing.
# Targets: make, make run, make clean
# ═════════════════════════════════════════════════════════════════════════════
# ─────────────────────────────────────────────────────────────────────────────
# Compiler Configuration
# ─────────────────────────────────────────────────────────────────────────────
# CXX: C++ compiler executable (g++ for MinGW on Windows)
CXX = g++
# CXXFLAGS: Compiler flags
#   -std=c++17           : Use C++17 standard
#   -Wall -Wextra        : Enable all warnings and extra warnings
#   -I./include          : Include path for project headers
CXXFLAGS = -std=c++17 -Wall -Wextra -I./include

# ─────────────────────────────────────────────────────────────────────────────
# Directory Variables
# ─────────────────────────────────────────────────────────────────────────────
# SRC_DIR: Directory containing source files (Parentheses.cpp, ParenthesesTest.cpp)
SRC_DIR = src
# OBJ_DIR: Directory for intermediate object files (.o)
OBJ_DIR = build
# BIN_DIR: Directory for final executable (current directory)
BIN_DIR = .

# ─────────────────────────────────────────────────────────────────────────────
# Source and Object Files
# ─────────────────────────────────────────────────────────────────────────────
# SOURCES: List of project source files to compile
SOURCES = $(SRC_DIR)/Parentheses.cpp $(SRC_DIR)/ParenthesesTest.cpp
# OBJECTS: Transform SOURCES paths (src/%.cpp) to object file paths (build/%.o)
OBJECTS = $(SOURCES:$(SRC_DIR)/%.cpp=$(OBJ_DIR)/%.o)
# Append Catch2 object to dependencies
OBJECTS += $(CATCH_OBJ)
# TARGET: Final executable name
TARGET = $(BIN_DIR)/parentheses_tests.exe

# ─────────────────────────────────────────────────────────────────────────────
# Phony Targets (targets that don't represent files)
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: all run clean

# ─────────────────────────────────────────────────────────────────────────────
# Build Rules
# ─────────────────────────────────────────────────────────────────────────────

# all: Default target, builds the executable
all: $(TARGET)

# $(TARGET): Links all object files into the final executable
# Depends on: $(OBJECTS) = Baseball.o, BaseballTest.o, catch_amalgamated.o
# Order-only prerequisite: $(BIN_DIR) ensures output directory exists first
$(TARGET): $(OBJECTS) | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $^

# Pattern rule: Compiles source files in $(SRC_DIR) to object files in $(OBJ_DIR)
# $< = first dependency (the .cpp file)
# $@ = target (the .o file)
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp | $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Directory creation rule: Creates $(OBJ_DIR) and $(BIN_DIR) if they don't exist
# Uses PowerShell for Windows compatibility (MinGW environment)
$(OBJ_DIR) $(BIN_DIR):
	powershell -Command "if (!(Test-Path '$@')) { New-Item -ItemType Directory -Path '$@' | Out-Null }"

# ─────────────────────────────────────────────────────────────────────────────
# Utility Targets
# ─────────────────────────────────────────────────────────────────────────────

# run: Builds and executes the test executable
run: $(TARGET)
	./parentheses_tests.exe

# clean: Removes all build artifacts and executables
# Uses PowerShell for Windows compatibility
clean:
	powershell -Command "if (Test-Path build) { Remove-Item -Recurse -Force build }"
	powershell -Command "if (Test-Path parentheses_tests.exe) { Remove-Item parentheses_tests.exe }"

.PHONY: all run clean