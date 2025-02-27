#!/bin/bash
# build.sh - Compiles the stack calculator program
# Author: Original author
# Date: Current date

# Create build directory if it doesn't exist
mkdir -p build

# Assemble all source files
as -o build/main.o src/main.s
as -o build/stack.o src/stack.s
as -o build/io.o src/io.s
as -o build/program.o src/program.s

# Link the object files
ld -o build/calculator build/main.o build/stack.o build/io.o build/program.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main -arch x86_64

echo "Build complete. Run with: ./build/calculator" 