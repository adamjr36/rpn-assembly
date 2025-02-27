#!/bin/bash
# run_tests.sh - Runs the stack calculator program with all tests cases in inputs directory
# Author: Adam Rubinstein
# Date: 02/27/2025

# Run the program with all test cases in inputs directory. 
# Ex: ./build/calculator < inputs/x.txt > outputs/x.txt
mkdir -p outputs

for file in inputs/*.txt; do
    echo "Running test case $file"

    filename=$(basename $file)
    output_file="outputs/${filename}"

    ./build/calculator < $file > $output_file
done
