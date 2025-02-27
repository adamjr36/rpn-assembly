# constants.s - Defines constants used throughout the program
# Author: Adam Rubinstein
# Date: 02/27/2025

# System call numbers
.equ SYS_READ, 0x2000003
.equ SYS_WRITE, 0x2000004
.equ SYS_EXIT, 0x2000001

# File descriptors
.equ STDIN, 0
.equ STDOUT, 1

# Stack configuration
.equ STACK_SIZE, 1000
.equ INT_SIZE, 4

# Buffer size for reading input
.equ BUFFER_SIZE, 1024 